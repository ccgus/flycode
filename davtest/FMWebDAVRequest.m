//
//  FMWebDAVRequest.m
//  davtest
//
//  Created by August Mueller on 8/7/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import "FMWebDAVRequest.h"

@implementation FMWebDAVRequest

@synthesize connection=_connection;
@synthesize responseData=_responseData;
@synthesize url=_url;
@synthesize delegate=_delegate;
@synthesize contextInfo=_contextInfo;
@synthesize endSelector=_endSelector;
@synthesize responseStatusCode=_responseStatusCode;
@synthesize error=_error;

+ (id) requestToURL:(NSURL*)url {
    FMWebDAVRequest *request = [[FMWebDAVRequest alloc] init];
    
    [request setUrl:url];
    
    return request;
}

+ (id) requestToURL:(NSURL*)url delegate:(id)del endSelector:(SEL)anEndSelector contextInfo:(id)context {
    
    FMWebDAVRequest *request = [[FMWebDAVRequest alloc] init];
    
    [request setUrl:url];
    [request setDelegate:del];
    [request setContextInfo:context];
    [request setEndSelector:anEndSelector];
    
    return request;
}

- (void)dealloc {
    // _delegate isn't retained.
    
    [_connection release];
    [_responseData release];
    [_url release];
    [_contextInfo release];
    [_xmlChars release];
    [_directoryBucket release];
    
    [super dealloc];
}

- (FMWebDAVRequest*) synchronous {
    _synchronous = YES;
    return [self autorelease];
}

- (void) sendRequest:(NSMutableURLRequest *)req {
    
    if (_synchronous) {
        NSURLResponse *response = 0x00;
        
        self.responseData = (NSMutableData*)[NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&_error];
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        
        if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            NSLog(@"%s:%d", __FUNCTION__, __LINE__);
            NSLog(@"FMWebDAVRequest Unknown response type: %@", httpResponse);
        }
        else {
            _responseStatusCode = [httpResponse statusCode];
        }
    }
    else {
        [NSURLConnection connectionWithRequest:req delegate:self];
    }
    
}

- (FMWebDAVRequest*) createDirectory {
    if (!_endSelector) {
        _endSelector = @selector(requestDidCreateDirectory:);
    }
    
    NSMutableURLRequest *req    = [NSMutableURLRequest requestWithURL:_url];
    
    [req setHTTPMethod:@"MKCOL"];
    
    [req setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*) delete {
    if (!_endSelector) {
        _endSelector = @selector(requestDidDelete:);
    }
    
    NSMutableURLRequest *req    = [NSMutableURLRequest requestWithURL:_url];
    
    [req setHTTPMethod:@"DELETE"];
    
    [req setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*) putData:(NSData*)data {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidPutData:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setHTTPMethod:@"PUT"];
    
    [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    [req setHTTPBody:data];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*) get {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidGet:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*) copyToDestinationURL:(NSURL*)dest {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidCopy:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setHTTPMethod:@"COPY"];
    
    [req setValue:[dest absoluteString] forHTTPHeaderField:@"Destination"];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*) moveToDestinationURL:(NSURL*)dest {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidCopy:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setHTTPMethod:@"MOVE"];
    
    [req setValue:[dest absoluteString] forHTTPHeaderField:@"Destination"];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*) head {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidHead:);
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:_url];
    
    [req setHTTPMethod:@"HEAD"];
    
    [self sendRequest:req];
    
    return self;
}

- (FMWebDAVRequest*) propfind {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidPropfind:);
    }
    
    return [self fetchDirectoryListingWithDepth:0];
}


- (FMWebDAVRequest*) fetchDirectoryListing {
    return [self fetchDirectoryListingWithDepth:1];
}

- (FMWebDAVRequest*) fetchDirectoryListingWithDepth:(NSUInteger)depth {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidFetchDirectoryListing:);
    }
    
    NSMutableURLRequest *req    = [NSMutableURLRequest requestWithURL:_url];
    
    // the trailing / always gets stripped off for some reason...
    _uriLength = [[_url path] length] + 1;
    
    [req setHTTPMethod:@"PROPFIND"];
    
    NSString *xml = @"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<D:propfind xmlns:D=\"DAV:\"><D:allprop/></D:propfind>";
    
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

- (NSArray*) directoryListing {
    
    NSMutableArray *ret = [NSMutableArray array];
    
    for (NSDictionary *dict in [self directoryListingWithAttributes]) {
        if ([dict objectForKey:@"href"]) {
            [ret addObject:[dict objectForKey:@"href"]];
        }
    }
    
    return ret;
    
}

- (NSArray*) directoryListingWithAttributes {
    
    if (!_responseData) {
        return nil;
    }
    
    _parseState = FMWebDAVDirectoryListing;
    _directoryBucket = [[NSMutableArray array] retain];
    
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:_responseData] autorelease];
    [parser setDelegate:self];
    [parser parse];
    
    return _directoryBucket;
}

- (NSString*) responseString {
    return [[[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding] autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    if (!_responseData) {
        [self setResponseData:[NSMutableData data]];
    }
    
    [_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if (self.delegate && [self.delegate respondsToSelector:@selector(request:didReceiveAuthenticationChallenge:)]) {
        [self.delegate request:self didReceiveAuthenticationChallenge:challenge];
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
    
    _responseStatusCode = [httpResponse statusCode];
    
    if (_responseStatusCode >= 400) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(request:hadStatusCodeErrorWithResponse:)]) {
            [self.delegate request:self hadStatusCodeErrorWithResponse:httpResponse];
        }
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    // hrm... do we really want to do this?
    if (self.delegate && [self.delegate respondsToSelector:@selector(connection:didFailWithError:)]) {
        [self.delegate connection:connection didFailWithError:error];
    }
    
    // what about this?
    if (self.delegate && [self.delegate respondsToSelector:_endSelector]) {
        [self.delegate performSelector:_endSelector withObject:self];
    }
    
    [self autorelease];
}


-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    if (self.delegate && [self.delegate respondsToSelector:_endSelector]) {
        [self.delegate performSelector:_endSelector withObject:self];
    }
    
    [self autorelease];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    //debug(@"start: %@", elementName);
    
    if (!_xmlChars) {
        _xmlChars = [[NSMutableString string] retain];
    }
    
    [_xmlChars setString:@""];
    
    
    if (_parseState == FMWebDAVDirectoryListing) {
        
        if ([elementName isEqualToString:@"D:response"]) {
            _xmlBucket = [[NSMutableDictionary dictionary] retain];
        }
        // ...
    } 
    
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    //debug(@"end: %@, '%@'", elementName, _xmlChars);
    
    if (_parseState == FMWebDAVDirectoryListing) {
        if ([elementName isEqualToString:@"D:href"]) {
            
            if ([_xmlChars length] < _uriLength) {
                // whoa, problemo.
                return;
            }
            
            NSString *lastBit = [_xmlChars substringFromIndex:_uriLength];
            if ([lastBit length]) {
                [_xmlBucket setObject:lastBit forKey:@"href"];
            }
        }
        else if ([elementName hasSuffix:@":creationdate"] || [elementName hasSuffix:@":modificationdate"]) {
            
            // '2008-10-30T02:52:47Z'
            // 1997-12-01T17:42:21-08:00
            // date-time = full-date "T" full-time, aka ISO-8601
            
            // stolen from http://www.cocoabuilder.com/archive/message/cocoa/2008/3/18/201578
            
            NSString *dateString = _xmlChars;
            
            static NSDateFormatter* sISO8601 = nil;
            if (!sISO8601) {
                sISO8601 = [[NSDateFormatter alloc] init];
                [sISO8601 setTimeStyle:NSDateFormatterFullStyle];
                [sISO8601 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];    // NOTE: problem!
            }
            
            if ([dateString hasSuffix:@"Z"]) {
                dateString = [[dateString substringToIndex:(dateString.length-1)] stringByAppendingString:@"GMT"];
            }
            
            NSDate *d = [sISO8601 dateFromString:dateString];
            
            int colIdx = [elementName rangeOfString:@":"].location;
            
            [_xmlBucket setObject:d forKey:[elementName substringFromIndex:colIdx + 1]];
        }
        
        else if ([elementName hasSuffix:@":getlastmodified"]) {
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
        else if ([elementName isEqualToString:@"D:response"] && [_xmlBucket objectForKey:@"href"]) {
            [_directoryBucket addObject:_xmlBucket];
            [_xmlBucket release];
            _xmlBucket = nil;
        }
        
        
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [_xmlChars appendString:string];
}


@end
