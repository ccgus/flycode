//
//  BLIPTest.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/13/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#ifndef NDEBUG


#import "BLIPRequest.h"
#import "BLIPProperties.h"
#import "BLIPConnection.h"

#import "IPAddress.h"
#import "Target.h"
#import "CollectionUtils.h"
#import "Logging.h"
#import "Test.h"

#define HAVE_KEYCHAIN_FRAMEWORK 0
#if HAVE_KEYCHAIN_FRAMEWORK
#import <Keychain/Keychain.h>
#endif


#define kListenerHost               @"localhost"
#define kListenerPort               46353
#define kSendInterval               0.5
#define kNBatchedMessages           20
#define kUseCompression             YES
#define kUrgentEvery                4
#define kClientRequiresSSL          NO
#define kClientUsesSSLCert          NO
#define kListenerRequiresSSL        NO
#define kListenerRequiresClientCert NO
#define kListenerCloseAfter         50
#define kClientAcceptCloseRequest   YES


static SecIdentityRef GetClientIdentity(void) {
    return NULL;    // Make this return a valid identity to test client-side certs
}

static SecIdentityRef GetListenerIdentity(void) {
    return NULL;    // Make this return a valid identity to test client-side certs
}


#pragma mark -
#pragma mark CLIENT TEST:


@interface BLIPConnectionTester : NSObject <BLIPConnectionDelegate>
{
    BLIPConnection *_conn;
    NSMutableDictionary *_pending;
}

@end


@implementation BLIPConnectionTester

- (id) init
{
    self = [super init];
    if (self != nil) {
        Log(@"** INIT %@",self);
        _pending = [[NSMutableDictionary alloc] init];
        IPAddress *addr = [[IPAddress alloc] initWithHostname: kListenerHost port: kListenerPort];
        _conn = [[BLIPConnection alloc] initToAddress: addr];
        if( ! _conn ) {
            [self release];
            return nil;
        }
        if( kClientRequiresSSL ) {
            _conn.SSLProperties = $mdict({kTCPPropertySSLAllowsAnyRoot, $true});
            if( kClientUsesSSLCert ) {
                SecIdentityRef clientIdentity = GetClientIdentity();
                if( clientIdentity ) {
                    [_conn setSSLProperty: $array((id)clientIdentity)
                                   forKey: kTCPPropertySSLCertificates];
                }
            }
        }
        _conn.delegate = self;
        Log(@"** Opening connection...");
        [_conn open];
    }
    return self;
}

- (void) dealloc
{
    Log(@"** %@ closing",self);
    [_conn close];
    [_conn release];
    [super dealloc];
}

- (void) sendAMessage
{
    if( _conn.status==kTCP_Open || _conn.status==kTCP_Opening ) {
        if(_pending.count<100) {
            Log(@"** Sending another %i messages...", kNBatchedMessages);
            for( int i=0; i<kNBatchedMessages; i++ ) {
                size_t size = random() % 32768;
                NSMutableData *body = [NSMutableData dataWithLength: size];
                UInt8 *bytes = body.mutableBytes;
                for( size_t i=0; i<size; i++ )
                    bytes[i] = i % 256;
                
                BLIPRequest *q = [_conn requestWithBody: body
                                             properties: $dict({@"Content-Type", @"application/octet-stream"},
                                                               {@"User-Agent", @"BLIPConnectionTester"},
                                                               {@"Date", [[NSDate date] description]},
                                                               {@"Size",$sprintf(@"%u",size)})];
                Assert(q);
                if( kUseCompression && (random()%2==1) )
                    q.compressed = YES;
                if( random()%16 > 12 )
                    q.urgent = YES;
                BLIPResponse *response = [q send];
                Assert(response);
                Assert(q.number>0);
                Assert(response.number==q.number);
                [_pending setObject: $object(size) forKey: $object(q.number)];
                response.onComplete = $target(self,responseArrived:);
            }
        } else {
            Warn(@"There are %u pending messages; waiting for the listener to catch up...",_pending.count);
        }
        [self performSelector: @selector(sendAMessage) withObject: nil afterDelay: kSendInterval];
    }
}

- (void) responseArrived: (BLIPResponse*)response
{
    Log(@"********** called responseArrived: %@",response);
}

- (void) connectionDidOpen: (TCPConnection*)connection
{
    Log(@"** %@ didOpen",connection);
    [self sendAMessage];
}
- (BOOL) connection: (TCPConnection*)connection authorizeSSLPeer: (SecCertificateRef)peerCert
{
#if HAVE_KEYCHAIN_FRAMEWORK
    Certificate *cert = peerCert ?[Certificate certificateWithCertificateRef: peerCert] :nil;
    Log(@"** %@ authorizeSSLPeer: %@",self,cert);
#else
    Log(@"** %@ authorizeSSLPeer: %@",self,peerCert);
#endif
    return peerCert != nil;
}
- (void) connection: (TCPConnection*)connection failedToOpen: (NSError*)error
{
    Log(@"** %@ failedToOpen: %@",connection,error);
    CFRunLoopStop(CFRunLoopGetCurrent());
}
- (void) connectionDidClose: (TCPConnection*)connection
{
    Log(@"** %@ didClose",connection);
    setObj(&_conn,nil);
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    CFRunLoopStop(CFRunLoopGetCurrent());
}
- (void) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request
{
    Log(@"***** %@ received %@",connection,request);
    [request respondWithData: request.body contentType: request.contentType];
}

- (void) connection: (BLIPConnection*)connection receivedResponse: (BLIPResponse*)response
{
    Log(@"********** %@ received %@",connection,response);
    NSNumber *sizeObj = [_pending objectForKey: $object(response.number)];

    if( response.error )
        Warn(@"Got error response: %@",response.error);
    else {
        NSData *body = response.body;
        size_t size = body.length;
        Assert(size<32768);
        const UInt8 *bytes = body.bytes;
        for( size_t i=0; i<size; i++ )
            AssertEq(bytes[i],i % 256);
        AssertEq(size,sizeObj.intValue);
    }
    Assert(sizeObj);
    [_pending removeObjectForKey: $object(response.number)];
    Log(@"Now %u replies pending", _pending.count);
}

- (BOOL) connectionReceivedCloseRequest: (BLIPConnection*)connection
{
    BOOL response = kClientAcceptCloseRequest;
    Log(@"***** %@ received a close request; returning %i",connection,response);
    return response;
}


@end


TestCase(BLIPConnection) {
#if HAVE_KEYCHAIN_FRAMEWORK
    [Keychain setUserInteractionAllowed: YES];
#endif
    BLIPConnectionTester *tester = [[BLIPConnectionTester alloc] init];
    CAssert(tester);
    
    [[NSRunLoop currentRunLoop] run];
    
    Log(@"** Runloop stopped");
    [tester release];
}




#pragma mark LISTENER TEST:


@interface BLIPTestListener : NSObject <TCPListenerDelegate, BLIPConnectionDelegate>
{
    BLIPListener *_listener;
    int _nReceived;
}

@end


@implementation BLIPTestListener

- (id) init
{
    self = [super init];
    if (self != nil) {
        _listener = [[BLIPListener alloc] initWithPort: kListenerPort];
        _listener.delegate = self;
        _listener.pickAvailablePort = YES;
        _listener.bonjourServiceType = @"_bliptest._tcp";
        if( kListenerRequiresSSL ) {
            SecIdentityRef listenerIdentity = GetListenerIdentity();
            Assert(listenerIdentity);
            _listener.SSLProperties = $mdict({kTCPPropertySSLCertificates, $array((id)listenerIdentity)},
                                             {kTCPPropertySSLAllowsAnyRoot,$true},
                            {kTCPPropertySSLClientSideAuthentication, $object(kTCPTryAuthenticate)});
        }
        Assert( [_listener open] );
        Log(@"%@ is listening...",self);
    }
    return self;
}

- (void) dealloc
{
    Log(@"%@ closing",self);
    [_listener close];
    [_listener release];
    [super dealloc];
}

- (void) listener: (TCPListener*)listener didAcceptConnection: (TCPConnection*)connection
{
    Log(@"** %@ accepted %@",self,connection);
    connection.delegate = self;
}

- (void) listener: (TCPListener*)listener failedToOpen: (NSError*)error
{
    Log(@"** BLIPTestListener failed to open: %@",error);
}

- (void) listenerDidOpen: (TCPListener*)listener   {Log(@"** BLIPTestListener did open");}
- (void) listenerDidClose: (TCPListener*)listener   {Log(@"** BLIPTestListener did close");}

- (BOOL) listener: (TCPListener*)listener shouldAcceptConnectionFrom: (IPAddress*)address
{
    Log(@"** %@ shouldAcceptConnectionFrom: %@",self,address);
    return YES;
}


- (void) connectionDidOpen: (TCPConnection*)connection
{
    Log(@"** %@ didOpen [SSL=%@]",connection,connection.actualSecurityLevel);
    _nReceived = 0;
}
- (BOOL) connection: (TCPConnection*)connection authorizeSSLPeer: (SecCertificateRef)peerCert
{
#if HAVE_KEYCHAIN_FRAMEWORK
    Certificate *cert = peerCert ?[Certificate certificateWithCertificateRef: peerCert] :nil;
    Log(@"** %@ authorizeSSLPeer: %@",connection,cert);
#else
    Log(@"** %@ authorizeSSLPeer: %@",self,peerCert);
#endif
    return peerCert != nil || ! kListenerRequiresClientCert;
}
- (void) connection: (TCPConnection*)connection failedToOpen: (NSError*)error
{
    Log(@"** %@ failedToOpen: %@",connection,error);
}
- (void) connectionDidClose: (TCPConnection*)connection
{
    Log(@"** %@ didClose",connection);
    [connection release];
}
- (void) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request
{
    Log(@"***** %@ received %@",connection,request);
    NSData *body = request.body;
    size_t size = body.length;
    Assert(size<32768);
    const UInt8 *bytes = body.bytes;
    for( size_t i=0; i<size; i++ )
        AssertEq(bytes[i],i % 256);
    
    AssertEqual([request valueOfProperty: @"Content-Type"], @"application/octet-stream");
    Assert([request valueOfProperty: @"User-Agent"] != nil);
    AssertEq([[request valueOfProperty: @"Size"] intValue], size);

    [request respondWithData: body contentType: request.contentType];
    
    if( ++ _nReceived == kListenerCloseAfter ) {
        Log(@"********** Closing BLIPTestListener after %i requests",_nReceived);
        [connection close];
    }
}

- (BOOL) connectionReceivedCloseRequest: (BLIPConnection*)connection;
{
    Log(@"***** %@ received a close request",connection);
    return YES;
}

- (void) connection: (BLIPConnection*)connection closeRequestFailedWithError: (NSError*)error
{
    Log(@"***** %@'s close request failed: %@",connection,error);
}


@end


TestCase(BLIPListener) {
    EnableLogTo(BLIP,YES);
    EnableLogTo(PortMapper,YES);
    EnableLogTo(Bonjour,YES);
#if HAVE_KEYCHAIN_FRAMEWORK
    [Keychain setUserInteractionAllowed: YES];
#endif
    BLIPTestListener *listener = [[BLIPTestListener alloc] init];
    
    [[NSRunLoop currentRunLoop] run];
    
    [listener release];
}


#endif


/*
 Copyright (c) 2008, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRI-
 BUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
 THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
