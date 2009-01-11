//
//  TCPEndpoint.h
//  MYNetwork
//
//  Created by Jens Alfke on 5/14/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#include <CFNetwork/CFSocketStream.h>
#else
#import <CoreServices/CoreServices.h>
#endif


// SSL properties:
#define kTCPPropertySSLCertificates  ((NSString*)kCFStreamSSLCertificates)
#define kTCPPropertySSLAllowsAnyRoot ((NSString*)kCFStreamSSLAllowsAnyRoot)

extern NSString* const kTCPPropertySSLClientSideAuthentication;    // value is TCPAuthenticate enum
typedef enum {
	kTCPNeverAuthenticate,			/* skip client authentication */
	kTCPAlwaysAuthenticate,         /* require it */
	kTCPTryAuthenticate             /* try to authenticate, but not error if client has no cert */
} TCPAuthenticate; // these MUST have same values as SSLAuthenticate enum in SecureTransport.h!


/** Abstract base class of TCPConnection and TCPListener.
    Mostly just manages the SSL properties. */
@interface TCPEndpoint : NSObject
{
    NSMutableDictionary *_sslProperties;
    id _delegate;
}

/** The desired security level. Use the security level constants from NSStream.h,
    such as NSStreamSocketSecurityLevelNegotiatedSSL. */
@property (copy) NSString *securityLevel;

/** Detailed SSL settings. This is the same as CFStream's kCFStreamPropertySSLSettings
    property. */
@property (copy) NSMutableDictionary *SSLProperties;

/** Shortcut to set a single SSL property. */
- (void) setSSLProperty: (id)value 
                 forKey: (NSString*)key;

//protected:
- (void) tellDelegate: (SEL)selector withObject: (id)param;

@end
