//
//  FMWebDAVRequest.h
//  davtest
//
//  Created by August Mueller on 8/7/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

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
    FMWebDAVForbiddenStatusCode = 403,
    FMWebDAVNotFoundStatusCode = 404,
    FMWebDAVMethodNotAllowedStatusCode = 405,
    FMWebDAVConflictStatusCode = 409,
};


@interface FMWebDAVRequest : NSObject {
    
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
    
    NSError *_error;
}

@property (retain) NSURLConnection *connection;
@property (retain) NSMutableData *responseData; // even though this is "mutable", it isn't if you are doing synchronous connections
@property (retain) NSURL *url;
@property (assign) id delegate;
@property (retain) id contextInfo;
@property (assign) SEL endSelector;
@property (assign) NSInteger responseStatusCode;
@property (retain) NSError *error;

+ (id) requestToURL:(NSURL*)url;
+ (id) requestToURL:(NSURL*)url delegate:(id)del endSelector:(SEL)anEndSelector contextInfo:(id)context;

- (FMWebDAVRequest*) fetchDirectoryListingWithDepth:(NSUInteger)depth extraToPropfind:(NSString*)extra;
- (FMWebDAVRequest*) fetchDirectoryListingWithDepth:(NSUInteger)depth;
- (FMWebDAVRequest*) fetchDirectoryListing;
- (NSArray*) directoryListing;
- (NSArray*) directoryListingWithAttributes;
- (NSString*) responseString;

- (FMWebDAVRequest*) createDirectory;
- (FMWebDAVRequest*) delete;
- (FMWebDAVRequest*) putData:(NSData*)data;
- (FMWebDAVRequest*) get;
- (FMWebDAVRequest*) head;
- (FMWebDAVRequest*) copyToDestinationURL:(NSURL*)dest;
- (FMWebDAVRequest*) moveToDestinationURL:(NSURL*)dest;

- (FMWebDAVRequest*) synchronous;

- (FMWebDAVRequest*) propfind;

// maybe I went a little overboard with the whole return self thing?  Probably.

+ (NSDate*) parseDateString:(NSString*)dateString;

@end


@interface NSObject (VPRServiceRequestDelegate)

- (void) request:(FMWebDAVRequest*)request didFailWithError:(NSError *)error;
- (void) request:(FMWebDAVRequest*)request hadStatusCodeErrorWithResponse:(NSHTTPURLResponse *)httpResponse;
- (void) request:(FMWebDAVRequest*)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end
