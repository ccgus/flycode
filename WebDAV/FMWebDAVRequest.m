//
//  FMWebDAVRequest.m
//  davtest
//
//  Created by August Mueller on 8/7/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#if !TARGET_OS_IPHONE
#import <SecurityInterface/SFCertificateTrustPanel.h>
#endif
#import "FMWebDAVRequest.h"
#import "FMFileDAVRequest.h"
#import "ISO8601DateFormatter.h"

NSString * const FMWebDAVRequestTestPayloadData  = @"FMWebDAVRequestTestPayloadData";
NSString * const FMWebDAVRequestTestResponseCode = @"FMWebDAVRequestTestResponseCode";
NSString * const FMWebDAVRequestTestPayloadURL   = @"FMWebDAVRequestTestPayloadURL";

NSString *FMWebDAVContentTypeKey   = @"contenttype";
NSString *FMWebDAVETagKey          = @"etag";
NSString *FMWebDAVHREFKey          = @"href";
NSString *FMWebDAVURIKey           = @"uri";

static NSMutableArray *FMWebDAVRequestTestResponses = nil;

@interface FMWebDAVRequest ()
- (void)logResponse:(NSHTTPURLResponse *)response;
- (void)logRequest:(NSURLRequest *)request;
- (void)callAndReleaseFinishBlock;
@end


@implementation FMWebDAVRequest

@synthesize connection=_connection;
@synthesize responseData=_responseData;
@synthesize url=_url;
@synthesize delegate=_delegate;
@synthesize contextInfo=_contextInfo;
@synthesize endSelector=_endSelector;
@synthesize responseStatusCode=_responseStatusCode;
@synthesize error=_error;
@synthesize username=_username;
@synthesize password=_password;

+ (id)requestToURL:(NSURL*)url {
    
    FMWebDAVRequest *request = [url isFileURL] ? [[FMFileDAVRequest alloc] init] : [[FMWebDAVRequest alloc] init];
    
    [request setUrl:url];
    
    return [request autorelease];
}

+ (id)requestToURL:(NSURL*)url delegate:(id)del {
    
    FMWebDAVRequest *request = [self requestToURL:url];
    
    [request setDelegate:del];
    
    return request;
}


+ (id)requestToURL:(NSURL*)url delegate:(id)del endSelector:(SEL)anEndSelector contextInfo:(id)context {
    
    FMWebDAVRequest *request = [self requestToURL:url delegate:del];
    
    [request setContextInfo:context];
    [request setEndSelector:anEndSelector];
    
    return request;
}

+ (void)addTestResponse:(NSString *)payload withResponseCode:(int)code {
    
    if (!FMWebDAVRequestTestResponses) {
        FMWebDAVRequestTestResponses = [[NSMutableArray alloc] init];
    }
    
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    
    [FMWebDAVRequestTestResponses addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             payloadData, FMWebDAVRequestTestPayloadData,
                                             [NSNumber numberWithInt:code], FMWebDAVRequestTestResponseCode,
                                             nil]];
}

+ (void)addTestResponseURL:(NSURL *)payloadURL withResponseCode:(int)code {
    
    if (!FMWebDAVRequestTestResponses) {
        FMWebDAVRequestTestResponses = [[NSMutableArray alloc] init];
    }
    
    [FMWebDAVRequestTestResponses addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             payloadURL, FMWebDAVRequestTestPayloadURL,
                                             [NSNumber numberWithInt:code], FMWebDAVRequestTestResponseCode,
                                             nil]];
}

+ (void)removeAllTestResponses {
    [FMWebDAVRequestTestResponses removeAllObjects];
}

- (void)dealloc {
    // _delegate isn't retained.
    
    //debug(@"%s:%d", __FUNCTION__, __LINE__);
    
    [_xmlBucket release];
    [_connection release];
    [_responseData release];
    [_url release];
    [_contextInfo release];
    [_xmlChars release];
    [_directoryBucket release];
    [_finishBlock release];
    [_error release];
    [_username release];
    [_password release];
    [super dealloc];
}

- (FMWebDAVRequest*)releaseWhenClosed {
    _releasedWhenClosed++;
    return [self retain];
}

- (FMWebDAVRequest*)synchronous {
    _synchronous = YES;
    return self;
}

- (FMWebDAVRequest*)rlsynchronous {
    _rlSynchronous = YES;
    return [self retain];
}

- (FMWebDAVRequest*)withFinishBlock:(void (^)(FMWebDAVRequest *))block {
    [_finishBlock autorelease];
    _finishBlock = [block copy];
    return self;
}

- (void)sendRequest:(NSMutableURLRequest *)req {
    
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    if ([FMWebDAVRequestTestResponses count]) {
        
        NSDictionary *testDict = [FMWebDAVRequestTestResponses objectAtIndex:0];
        
        [self setResponseStatusCode:[[testDict objectForKey:FMWebDAVRequestTestResponseCode] intValue]];
        [self setResponseData:[testDict objectForKey:FMWebDAVRequestTestPayloadData]];
        NSURL *responseURL = [testDict objectForKey:FMWebDAVRequestTestPayloadURL];
        
        if (![self responseData] && responseURL) {
            [self setResponseData:[NSData dataWithContentsOfURL:responseURL]];
        }
        
        [FMWebDAVRequestTestResponses removeObjectAtIndex:0];
    }
    else if (_rlSynchronous) {
        
        [self setConnection:[NSURLConnection connectionWithRequest:req delegate:self]];
        [self logRequest:req];
        
        // we do this so we get our delegate callbacks.
        // just regular [foo syncronous] won't work for that.
        NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
        while (_rlSynchronous && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            // Empty
        }
    }
    else if (_synchronous) {
        NSURLResponse *response = 0x00;
        
        NSError *err = nil;
        [self setResponseData:(NSMutableData*)[NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&err]];
        [self setError:err];
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        
        if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            NSLog(@"%s:%d", __FUNCTION__, __LINE__);
            NSLog(@"FMWebDAVRequest Unknown response type: %@", httpResponse);
            NSLog(@"Request method: %@", [req HTTPMethod]);
            
            if ([_error code] == NSURLErrorUserCancelledAuthentication) {
                _responseStatusCode = FMWebDAVUnauthorized;
            }
        }
        else {
            
            [self logRequest:req];
            [self logResponse:httpResponse];
            
            _responseStatusCode = [httpResponse statusCode];
        }
        
        [self callAndReleaseFinishBlock];
    }
    else {
        [self setConnection:[NSURLConnection connectionWithRequest:req delegate:self]];
        [self logRequest:req];
    }
}

- (FMWebDAVRequest*)createDirectory {
    if (!_endSelector) {
        _endSelector = @selector(requestDidCreateDirectory:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setTimeoutInterval:60 * 5];
    
    [req setHTTPMethod:@"MKCOL"];
    
    // defaults write com.flyingmeat.VoodooPad skipMKCOLContentType 1
    // defaults delete com.flyingmeat.VoodooPad skipMKCOLContentType
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"skipMKCOLContentType"]) {
        [req setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    }
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*)delete {
    if (!_endSelector) {
        _endSelector = @selector(requestDidDelete:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setTimeoutInterval:60 * 5];
    
    [req setHTTPMethod:@"DELETE"];
    
    [req setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*)putData:(NSData*)data {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidPutData:);
    }
    
    assert(data);
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setTimeoutInterval:60 * 5];
    
    [req setHTTPMethod:@"PUT"];
    
    [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    // this actually speeds things up for some reason.
    [req setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
    
    [req setHTTPBody:data];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*)get {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidGet:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setTimeoutInterval:60 * 5];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*)copyToDestinationURL:(NSURL*)dest {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidCopy:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setTimeoutInterval:60 * 5];
    
    [req setHTTPMethod:@"COPY"];
    
    [req setValue:[dest absoluteString] forHTTPHeaderField:@"Destination"];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*)moveToDestinationURL:(NSURL*)dest {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidCopy:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setTimeoutInterval:60 * 5];
    
    [req setHTTPMethod:@"MOVE"];
    
    [req setValue:[dest absoluteString] forHTTPHeaderField:@"Destination"];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*)head {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidHead:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setTimeoutInterval:60 * 5];
    
    [req setHTTPMethod:@"HEAD"];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*)propfind {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidPropfind:);
    }
    
    return [self fetchDirectoryListingWithDepth:0];
}


- (FMWebDAVRequest*)fetchDirectoryListing {
    return [self fetchDirectoryListingWithDepth:1];
}

- (FMWebDAVRequest*)fetchDirectoryListingWithDepth:(NSUInteger)depth {
    return [self fetchDirectoryListingWithDepth:depth extraToPropfind:@""];
}

// <D:prop><D:creationdate/></D:prop>
- (FMWebDAVRequest*)fetchDirectoryListingWithDepth:(NSUInteger)depth extraToPropfind:(NSString*)extra {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidFetchDirectoryListing:);
    }
    
    if (!extra) {
        extra = @"";
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setTimeoutInterval:60 * 5];
    
    // the trailing / always gets stripped off for some reason...
    _uriLength = [[[_url path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] length] + 1;
    
    [req setHTTPMethod:@"PROPFIND"];
    
    NSString *xml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<D:propfind xmlns:D=\"DAV:\"><D:allprop/>%@</D:propfind>", extra];
    
    if (depth > 1) {
        // http://tools.ietf.org/html/rfc2518#section-9.2
        [req setValue:@"infinity" forHTTPHeaderField:@"Depth"];
    }
    else {
        [req setValue:[NSString stringWithFormat:@"%d", depth] forHTTPHeaderField:@"Depth"];
    }
    
    [req setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    [req setHTTPBody:[xml dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self sendRequest:req];
    
    return self;
}

- (NSArray*)directoryListing {
    
    NSMutableArray *ret = [NSMutableArray array];
    
    for (NSDictionary *dict in [self directoryListingWithAttributes]) {
        if ([dict objectForKey:@"href"]) {
            [ret addObject:[dict objectForKey:@"href"]];
        }
    }
    
    return ret;
}

- (NSArray*)directoryListingWithAttributes {
    
    if (!_responseData) {
        return nil;
    }
    
    _parseState = FMWebDAVDirectoryListing;
    [_directoryBucket release];
    _directoryBucket = [[NSMutableArray array] retain];
    
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:_responseData] autorelease];
    [parser setDelegate:self];
    [parser parse];
    
    return _directoryBucket;
}

- (NSString*)responseString {
#if DEBUG
    const NSUInteger MAX_DISPLAY_LENGTH = 8*1024;
    
    NSString *displayString = [[[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding] autorelease];
    
    if (displayString) {
        
        NSUInteger  stringLength = [displayString length];
        if (stringLength > MAX_DISPLAY_LENGTH) {
            
            displayString = [NSString stringWithFormat:@"Showing first %d of %lu characters: %@", 
                             MAX_DISPLAY_LENGTH, stringLength, 
                             [displayString substringWithRange:NSMakeRange( 0, MAX_DISPLAY_LENGTH )]];
        }
    }
    else {
        
        NSData *displayData = _responseData;
        NSUInteger dataLength = [displayData length];
        if (dataLength > MAX_DISPLAY_LENGTH) {
            
            displayString = [NSString stringWithFormat:@"Showing first %d of %lu bytes: %@",
                             MAX_DISPLAY_LENGTH, dataLength, 
                             [displayData subdataWithRange:NSMakeRange( 0, MAX_DISPLAY_LENGTH )]];
        }
        else {
            displayString = [displayData description];
        }
    }
    
    return displayString;
#else
    return [[[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding] autorelease];
#endif
}

- (void)logRequest:(NSURLRequest *)request {
    
    BOOL writeAlways = NO;
    
#if defined(VPMobile) && defined(DEBUG)
    writeAlways = NO;  // YES if HTTP traffic is wanted, NO if not
#endif
    
    // defaults write com.flyingmeat.VoodooPad FMWebDAVRequestDebug 1
    // defaults delete com.flyingmeat.VoodooPad FMWebDAVRequestDebug
    
    if (writeAlways || [[NSUserDefaults standardUserDefaults] boolForKey:@"FMWebDAVRequestDebug"]) {
        
        NSMutableString *logOutput = [[NSMutableString alloc] init];
        
        if ([self connection]) {
            [logOutput appendFormat:@"Request for connection %p:\n", [self connection]];
        }
        else {
            [logOutput appendString:@"Synchronous request:\n"];
        }
        
        [logOutput appendFormat:@"%@ %@\n", [request HTTPMethod], [[request URL] absoluteString]];
        
        NSDictionary *headers = [request allHTTPHeaderFields];
        [logOutput appendFormat:@"headers: %@\n", headers ? [headers description] : @"{}"];
        
        NSString *body = nil;
        if ([[request HTTPBody] length]) {
            body = [[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
            body = [body stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
            body = [NSString stringWithFormat:@"{\n\t%@\n}", body];
        }
        [logOutput appendFormat:@"body: %@", body ? : @"{}"];
        
        NSLog( @"%@", logOutput );
        [logOutput release];
    }
}

- (void)logResponse:(NSHTTPURLResponse *)response {
    
    BOOL writeAlways = NO;
    
#if defined(VPMobile) && defined(DEBUG)
    writeAlways = NO;  // YES if HTTP traffic is wanted, NO if not
#endif
    
    // defaults write com.flyingmeat.VoodooPad FMWebDAVRequestDebug 1
    // defaults delete com.flyingmeat.VoodooPad FMWebDAVRequestDebug
    
    if (writeAlways || [[NSUserDefaults standardUserDefaults] boolForKey:@"FMWebDAVRequestDebug"]) {
        
        NSMutableString *logOutput = [[NSMutableString alloc] init];
        
        if (response) {
            
            if ([self connection]) {
                [logOutput appendFormat:@"Response for connection %p:\n", [self connection]];
            }
            else {
                [logOutput appendString:@"Synchronous response:\n"];
            }
            
            [logOutput appendFormat:@"Response status: %ld\n", (long)[response statusCode]];
            
            NSDictionary *headers = [response allHeaderFields];
            [logOutput appendFormat:@"Response headers: %@\n", headers ? [headers description] : @"{}"];
        }
        
        if (_responseData) {
            NSString *body = [self responseString];
            body = [body stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
            body = [NSString stringWithFormat:@"{\n\t%@\n}", body];
            [logOutput appendFormat:@"Response body: %@", body ? : @"{}"];
        }
        
        NSLog( @"%@", logOutput );
        [logOutput release];
    }
}

#if !TARGET_OS_IPHONE

// FIXME: move this to a delegate some day, because it really really really really doesn't belong here.

- (BOOL)connectDespiteServerTrustChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    // http://lists.apple.com/archives/Apple-cdsa/2006/Apr/msg00013.html
    
    NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
    SecTrustRef serverTrust = [protectionSpace serverTrust];
    BOOL userHasBeenAsked = NO;
    
    do {
        
        SecTrustResultType resultType = kSecTrustResultOtherError;
        SecTrustEvaluate( serverTrust, &resultType );
        
        // Reasons to accept the challenge
        if (resultType == kSecTrustResultProceed) {
            // debug(@"Accepting challenge because it is good");
            return YES;
        }
        
        if (resultType == kSecTrustResultUnspecified) {
            // debug(@"Accepting challenge because the user is using default settings");
            return YES;
        }
        
        // Reasons to reject the challenge
        if (resultType == kSecTrustResultDeny) {
            // debug(@"Rejecting challenge because user configured the keychain to do so");
            return NO;
        }
        
        if (resultType == kSecTrustResultInvalid || resultType == kSecTrustResultFatalTrustFailure || resultType == kSecTrustResultOtherError) {
            // debug(@"Rejecting challenge because something bad happened");
            return NO;
        }
        
        if (userHasBeenAsked) {
            //The modal dialog has already been presented to and dismissed by the user.  After evaluating trust a second time, nothing has changed.  Therefore, the user clicked the "Continue" button without making changes to the trust settings.  That means it is OK to connect.
            return YES;
        }
        
        // Go ask the user
        NSString *messageFormat = NSLocalizedString(@"Can't verify the identity of the server \"%@\".", @"Can't verify the identity of the server \"%@\".");
        NSString *message = [NSString stringWithFormat:messageFormat, [protectionSpace host]];
        NSString *infoFormat = NSLocalizedString(@"The certificate for this server appears to be invalid.  You might be connecting to a server that is pretending to be \"%@\", which could put your confidential information at risk.  Would you like to connect to the server anyway?", @"The certificate for this server appears to be invalid.  You might be connecting to a server that is pretending to be \"%@\", which could put your confidential information at risk.  Would you like to connect to the server anyway?");
        NSString *info = [NSString stringWithFormat:infoFormat, [protectionSpace host]];
        
        SFCertificateTrustPanel *panel = [SFCertificateTrustPanel sharedCertificateTrustPanel];
        [panel setInformativeText:info];
        [panel setAlternateButtonTitle:@"Cancel"];
        
        if ([panel runModalForTrust:serverTrust message:message] != NSOKButton) {
            return NO;
        }
        
        userHasBeenAsked = YES;
        
    }
    while (YES);
    
    return NO;
}
#endif

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    // If -connection:canAuthenticateAgainstProtectionSpace: was not implemented, NSURLConnection would assume NO for NSURLAuthenticationMethodClientCertificate and NSURLAuthenticationMethodServerTrust authentication methods and YES for all others.
    return ![[protectionSpace authenticationMethod] isEqualToString:NSURLAuthenticationMethodClientCertificate];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    if (!_responseData) {
        [self setResponseData:[NSMutableData data]];
    }
    
    [_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    if (!_delegate && !(_username && _password)) {
        NSLog(@"No delegate set, or password + username set for an auth challenge");
    }
    
    if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        // NSURLAuthenticationMethodServerTrust and -[NSURLProtectionSpace serverTrust] are present on Mac OS X 10.6 / iOS 3.0 and later
        
#if !TARGET_OS_IPHONE
        if ([self connectDespiteServerTrustChallenge:challenge]) {
            [[self delegate] request:self didReceiveAuthenticationChallenge:challenge];
        }
        else {
            _canceling = YES;
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
#endif
        
#ifdef TARGET_OS_IPHONE
        debug(@"Accepting server trust challenge for '%@'", [[challenge protectionSpace] host]);
        [[challenge sender] useCredential:[NSURLCredential credentialForTrust:[[challenge protectionSpace] serverTrust]] forAuthenticationChallenge:challenge];
#endif
    }
    else if ([self delegate] && [[self delegate] respondsToSelector:@selector(request:didReceiveAuthenticationChallenge:)]) {
        [[self delegate] request:self didReceiveAuthenticationChallenge:challenge];
    }
    
    else if (_username && _password && ([challenge previousFailureCount] == 0)) {
        
        NSURLCredential *cred = [NSURLCredential credentialWithUser:_username
                                                           password:_password
                                                        persistence:NSURLCredentialPersistenceForSession];
        
        [[challenge sender] useCredential:cred forAuthenticationChallenge:challenge];
        
    }
    else {
        debug(@"The password didn't work!");
        _rlSynchronous = NO;
        [self setResponseStatusCode:FMWebDAVUnauthorized];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)URLresponse {
    
    [_responseData setLength:0]; 
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)URLresponse;
    
    if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"Unknown response type: %@", URLresponse);
        return;
    }
    
    [self logResponse:httpResponse];
    
    _responseStatusCode = [httpResponse statusCode];
    
    if (_responseStatusCode >= 400) {
        if ([self delegate] && [[self delegate] respondsToSelector:@selector(request:hadStatusCodeErrorWithResponse:)]) {
            [[self delegate] request:self hadStatusCodeErrorWithResponse:httpResponse];
        }
    }
}

- (void)checkReleaseWhenClosed {
    while (_releasedWhenClosed > 0) {
        _releasedWhenClosed--;
        [self autorelease];
    }
}

- (void)callAndReleaseFinishBlock {
    
    if (_finishBlock) {
        _finishBlock(self);
        [_finishBlock release];
        _finishBlock = 0x00;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    
    if (_canceling) {
        _canceling = NO;
        _rlSynchronous = NO;
        [self checkReleaseWhenClosed];
        return;
    }
    
    [self setError:error];
    
    if ([[self delegate] respondsToSelector:@selector(connection:didFailWithError:)]) {
        [[self delegate] connection:connection didFailWithError:error];
    }
    
    if ([[self delegate] respondsToSelector:_endSelector]) {
        [[self delegate] performSelector:_endSelector withObject:self];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"FMWebDAVRequestDebug"]) {
        NSLog( @"Error response: %p {\n\t%@\n}", connection, [error localizedDescription] );
    }
    
    [self callAndReleaseFinishBlock];
    
    _rlSynchronous = NO;
    
    
    [self checkReleaseWhenClosed];
}


-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    if ([[self delegate] respondsToSelector:_endSelector]) {
        [[self delegate] performSelector:_endSelector withObject:self];
    }
    
    [self logResponse:nil];
    
    _rlSynchronous = NO;
    
    [self callAndReleaseFinishBlock];
    [self checkReleaseWhenClosed];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    if (!_xmlChars) {
        _xmlChars = [[NSMutableString string] retain];
    }
    
    [_xmlChars setString:@""];
    
    if (_parseState == FMWebDAVDirectoryListing) {
        
        if ([elementName isEqualToString:@"D:response"]) {
            _xmlBucket = [[NSMutableDictionary dictionary] retain];
        }
    }
}

+ (NSDate*)parseDateString:(NSString*)dateString {
    
    ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
    
    NSDate *date = [formatter dateFromString:dateString];
    
    if (!date) {
        NSLog(@"Could not parse %@", dateString);
    }
    
    return date;
    
    /*
     
     NSLog(@"dateString: %@", dateString);
     
     static NSDateFormatter* formatterA = nil;
     if (!formatterA) {
     formatterA = [[NSDateFormatter alloc] init];
     [formatterA setTimeStyle:NSDateFormatterFullStyle];
     [formatterA setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];    // NOTE: problem! (but I'm not sure what that problem would be)
     }
     static NSDateFormatter* formatterB = nil;
     if (!formatterB) {
     formatterB = [[NSDateFormatter alloc] init];
     [formatterB setTimeStyle:NSDateFormatterFullStyle];
     [formatterB setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];    // NOTE: problem! (but I'm not sure what that problem would be)
     }
     
     
     NSArray *formatters = [NSArray arrayWithObjects:formatterA, formatterB, nil];
     
     for (NSDateFormatter *formatter in formatters) {
     
     NSString *stringToWorkOn = dateString;
     
     if ([stringToWorkOn hasSuffix:@"Z"]) {
     NSLog(@"stripping the z");
     stringToWorkOn = [[stringToWorkOn substringToIndex:(dateString.length-1)] stringByAppendingString:@"GMT"];
     }
     
     NSDate *d = [formatter dateFromString:stringToWorkOn];
     
     if (!d) {
     // 2009-06-30T02:46:53GM
     NSLog(@"Initial parse failed");
     }
     
     if (!d && ![stringToWorkOn hasSuffix:@"GMT"]) {
     stringToWorkOn = [stringToWorkOn stringByAppendingString:@"GMT"];
     d = [formatter dateFromString:stringToWorkOn];
     }
     
     if (d) {
     return d;
     }
     }
     
     
     NSLog(@"Could not parse %@", dateString);
     
     return nil;
     */
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if (_parseState == FMWebDAVDirectoryListing) {
        if ([elementName isEqualToString:@"D:href"]) {
            
            if ([_xmlChars length] < _uriLength) {
                // whoa, problemo.
                return;
            }
            
            if ([_xmlChars hasPrefix:@"http"]) {
                // aakkkk!
                NSURL *junk = [NSURL URLWithString:_xmlChars];
                BOOL trailingSlash = [_xmlChars hasSuffix:@"/"];
                [_xmlChars setString:[junk path]];
                if (trailingSlash) {
                    [_xmlChars appendString:@"/"];
                }
            }
            
            if ([_xmlChars length]) {
                [_xmlBucket setObject:[[_xmlChars copy] autorelease] forKey:FMWebDAVURIKey];
            }
            
            NSString *lastBit = [_xmlChars substringFromIndex:_uriLength];
            if ([lastBit length]) {
                [_xmlBucket setObject:lastBit forKey:FMWebDAVHREFKey];
            }
        }
        else if ([elementName hasSuffix:@":creationdate"] || [elementName hasSuffix:@":modificationdate"]) {
            
            // 2009-06-30T02:46:53GMT
            // '2008-10-30T02:52:47Z'
            // 1997-12-01T17:42:21-08:00
            // date-time = full-date "T" full-time, aka ISO-8601
            
            // stolen from http://www.cocoabuilder.com/archive/message/cocoa/2008/3/18/201578
            
            if ([_xmlChars length]) {
                
                NSDate *d = [[self class] parseDateString:_xmlChars];
                
                if (d) {
                    
                    int colIdx = [elementName rangeOfString:@":"].location;
                    
                    [_xmlBucket setObject:d forKey:[elementName substringFromIndex:colIdx + 1]];
                }
                else {
                    NSLog(@"Could not parse date string '%@' for '%@'", _xmlChars, elementName);
                }
            }
        }
        
        else if ([elementName hasSuffix:@":getlastmodified"]) {
            #pragma message "FIXME: go ahead and do this bit."
            // 'Thu, 30 Oct 2008 02:52:47 GMT'
            // Monday, 12-Jan-98 09:25:56 GMT
            // Value: HTTP-date  ; defined in section 3.3.1 of RFC2068
            // of course it's fucking different than creationdate.
            //
            // That makes complete sense.
            //
            // I thought for a while, that WebDAV was pretty sane.  then I saw this.
            // ok ok ok, it's not _that_ bad... but, really?
            //
            // obviously there's no code here to deal with it.
            //
            // I'll take a patch.  kthx, bai now.
        }
        else if ([elementName hasSuffix:@":getetag"] && [_xmlChars length]) {
            [_xmlBucket setObject:[[_xmlChars copy] autorelease] forKey:FMWebDAVETagKey];
        }
        else if ([elementName hasSuffix:@":getcontenttype"] && [_xmlChars length]) {
            [_xmlBucket setObject:[[_xmlChars copy] autorelease] forKey:FMWebDAVContentTypeKey];
        }
        else if ([elementName isEqualToString:@"D:response"]) {
            if ([_xmlBucket objectForKey:@"href"]) {
                [_directoryBucket addObject:_xmlBucket];
            }
            [_xmlBucket release];
            _xmlBucket = nil;
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [_xmlChars appendString:string];
}


- (BOOL)xrespondsToSelector:(SEL)aSelector {
    debug(@"%@: %@", NSStringFromClass([self class]), NSStringFromSelector(aSelector));
    return [super respondsToSelector:aSelector];
}

@end
