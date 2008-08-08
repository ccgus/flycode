//
//  FMWebDAVRequest.h
//  davtest
//
//  Created by August Mueller on 8/7/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NSStringToURL(arrrrgh) [NSURL URLWithString:arrrrgh]
#define NSDataToString(blah) [[[NSString alloc] initWithData:blah encoding:NSUTF8StringEncoding] autorelease]

enum {
    FMWebDAVDirectoryListing    = 1,
};


@interface FMWebDAVRequest : NSObject {
    
    NSURLConnection *_connection;
    NSMutableData *_responseData;
    NSMutableString *_xmlChars;
    NSURL *_url;
    id _delegate;
    id _contextInfo;
    SEL _endSelector;
    NSUInteger _parseState;
    
    NSUInteger _uriLength;
    NSMutableArray *_directoryBucket;
    
    NSInteger _responseStatusCode;
    
    BOOL _synchronous;
}

@property (retain) NSURLConnection *connection;
@property (retain) NSMutableData *responseData; // even though this is "mutable", it isn't if you are doing synchronous connections
@property (retain) NSURL *url;
@property (assign) id delegate;
@property (retain) id contextInfo;
@property (assign) SEL endSelector;
@property (assign) NSInteger responseStatusCode;

+ (id) requestToURL:(NSURL*)url;
+ (id) requestToURL:(NSURL*)url delegate:(id)del endSelector:(SEL)anEndSelector contextInfo:(id)context;

- (FMWebDAVRequest*) fetchDirectoryListing;
- (NSArray*) directoryListing;

- (void) createDirectory;
- (void) delete;
- (void) putData:(NSData*)data;
- (FMWebDAVRequest*) get;
- (FMWebDAVRequest*) head;

- (FMWebDAVRequest*) synchronous;

- (FMWebDAVRequest*) propfind;

@end


@interface NSObject (VPRServiceRequestDelegate)

- (void) request:(FMWebDAVRequest*)request didFailWithError:(NSError *)error;
- (void) request:(FMWebDAVRequest*)request hadStatusCodeErrorWithResponse:(NSHTTPURLResponse *)httpResponse;
- (void) request:(FMWebDAVRequest*)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end
