//
//  FMWebDAVRequest.h
//  davtest
//
//  Created by August Mueller on 8/7/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef __has_feature      // Optional.
    #define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

#ifndef NS_RETURNS_NOT_RETAINED
    #if __has_feature(attribute_ns_returns_not_retained)
        #define NS_RETURNS_NOT_RETAINED __attribute__((ns_returns_not_retained))
    #else
        #define NS_RETURNS_NOT_RETAINED
    #endif
#endif

#define NSStringToURL(arrrrgh) [NSURL URLWithString:[arrrrgh stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
#define NSDataToString(blah) [[[NSString alloc] initWithData:blah encoding:NSUTF8StringEncoding] autorelease]

enum {
    FMWebDAVDirectoryListing    = 1,
};


// http://www.ietf.org/rfc/rfc2518.txt
// just a small collection of stuff that I find useful.
enum {
    FMWebDAVOKStatusCode = 200,
    FMWebDAVCreatedStatusCode = 201,
    FMWebDAVNoContentStatusCode = 204,
    FMWebDAVUnauthorized = 401,
    FMWebDAVPaymentRequired = 402,
    FMWebDAVForbiddenStatusCode = 403,
    FMWebDAVNotFoundStatusCode = 404,
    FMWebDAVMethodNotAllowedStatusCode = 405,
    FMWebDAVConflictStatusCode = 409,
    FMHTTPNotImplementedErrorCode = 501,
};


extern NSString *FMWebDAVContentTypeKey;
extern NSString *FMWebDAVETagKey;
extern NSString *FMWebDAVHREFKey;
extern NSString *FMWebDAVURIKey;


@class FMWebDAVRequest;

@interface FMWebDAVRequest : NSObject <NSXMLParserDelegate> {
    
    NSURLConnection *_connection;
    NSMutableData *_responseData;
    
    NSMutableString *_xmlChars;
    NSMutableDictionary *_xmlBucket;
    NSMutableArray *_directoryBucket;
    
    NSURL *_url;
    id _delegate;
    id _contextInfo;
    SEL _endSelector;
    NSUInteger _parseState;
    
    NSUInteger _uriLength;
    
    NSInteger _responseStatusCode;
    
    BOOL _synchronous;
    BOOL _rlSynchronous;
    BOOL _canceling;
    
    NSUInteger _releasedWhenClosed;
    
    NSError *_error;
    
    NSString *_username;
    NSString *_password;
    
    void (^_finishBlock)(FMWebDAVRequest *);
}

@property (retain) NSURLConnection *connection;
@property (retain) NSMutableData *responseData; // even though this is "mutable", it isn't if you are doing synchronous connections
@property (retain) NSURL *url;
@property (assign) id delegate;
@property (retain) id contextInfo;
@property (assign) SEL endSelector;
@property (assign) NSInteger responseStatusCode;
@property (retain) NSError *error;
@property (retain) NSString *username;
@property (retain) NSString *password;

+ (id)requestToURL:(NSURL*)url;
+ (id)requestToURL:(NSURL*)url delegate:(id)del;
+ (id)requestToURL:(NSURL*)url delegate:(id)del endSelector:(SEL)anEndSelector contextInfo:(id)context;

+ (void)addTestResponse:(NSString*)payload withResponseCode:(int)code;
+ (void)addTestResponseURL:(NSURL *)payloadURL withResponseCode:(int)code;
+ (void)removeAllTestResponses;

- (FMWebDAVRequest*)fetchDirectoryListingWithDepth:(NSUInteger)depth extraToPropfind:(NSString*)extra;
- (FMWebDAVRequest*)fetchDirectoryListingWithDepth:(NSUInteger)depth;
- (FMWebDAVRequest*)fetchDirectoryListing;
- (NSArray*)directoryListing;
- (NSArray*)directoryListingWithAttributes;
- (NSString*)responseString;

- (FMWebDAVRequest*)createDirectory;
- (FMWebDAVRequest*)delete;
- (FMWebDAVRequest*)putData:(NSData*)data;
- (FMWebDAVRequest*)get;
- (FMWebDAVRequest*)head;
- (FMWebDAVRequest*)copyToDestinationURL:(NSURL*)dest NS_RETURNS_NOT_RETAINED;
- (FMWebDAVRequest*)moveToDestinationURL:(NSURL*)dest;

- (FMWebDAVRequest*)synchronous;
- (FMWebDAVRequest*)rlsynchronous;
- (FMWebDAVRequest*)releaseWhenClosed;

- (FMWebDAVRequest*)propfind;

- (FMWebDAVRequest*)withFinishBlock:(void (^)(FMWebDAVRequest *))block;

// maybe I went a little overboard with the whole return self thing?  Probably.

+ (NSDate*)parseDateString:(NSString*)dateString;

@end


@interface NSObject (VPRServiceRequestDelegate)

- (void)request:(FMWebDAVRequest*)request didFailWithError:(NSError *)error;
- (void)request:(FMWebDAVRequest*)request hadStatusCodeErrorWithResponse:(NSHTTPURLResponse *)httpResponse;
- (void)request:(FMWebDAVRequest*)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end
