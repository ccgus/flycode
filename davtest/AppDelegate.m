//
//  AppDelegate.m
//  davtest
//
//  Created by August Mueller on 8/6/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "FMWebDAVRequest.h"

@implementation AppDelegate

- (void)awakeFromNib {
	
    waitingOnAuthentication = YES;
    
    NSString *baseURL = @"http://srv.local/webdav/";
    
    [[FMWebDAVRequest requestToURL:NSStringToURL(baseURL)
                          delegate:self
                       endSelector:@selector(requestDidFetchDirectoryListingAndTestAuthenticationDidFinish:)
                       contextInfo:nil] fetchDirectoryListing];
    
    NSRunLoop * currentRunLoop = [NSRunLoop currentRunLoop];
    while (waitingOnAuthentication && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        // Empty
    }
    
    
    NSString *dirURL = [baseURL stringByAppendingFormat:@"newdir-%d/", (int)[NSDate timeIntervalSinceReferenceDate]];
    [[FMWebDAVRequest requestToURL:NSStringToURL(dirURL) delegate:self endSelector:nil contextInfo:nil] createDirectory];
    
    
    NSString *putURL    = [baseURL stringByAppendingString:@"Compass.icns"];
    NSData *data        = [NSData dataWithContentsOfFile:@"/Applications/Safari.app/Contents/Resources/compass.icns"];
    
    debug(@"putURL: %@", putURL);
    
    (void)[[[FMWebDAVRequest requestToURL:NSStringToURL(putURL) delegate:self endSelector:nil contextInfo:nil] synchronous] putData:data];
    
    NSString *copyToURL = [baseURL stringByAppendingString:@"Compass-Copy.icns"];
    
    [[[FMWebDAVRequest requestToURL:NSStringToURL(putURL)] synchronous] copyToDestinationURL:NSStringToURL(copyToURL)];
    
    data = [[[FMWebDAVRequest requestToURL:NSStringToURL(copyToURL) delegate:self endSelector:nil contextInfo:nil] synchronous] get].responseData;
    
    [data writeToFile:@"/tmp/compass.icns" atomically:YES];
    system("open /tmp/compass.icns");
    
    [[FMWebDAVRequest requestToURL:NSStringToURL(putURL)] delete];
    [[FMWebDAVRequest requestToURL:NSStringToURL(copyToURL)] delete];
}

- (void) requestDidFetchDirectoryListingAndTestAuthenticationDidFinish:(FMWebDAVRequest*)req {
    
    NSArray *directoryListing = [req directoryListing];
    
    for (NSString *file in directoryListing) {
        debug(@"file: %@", file);
    }
    
    waitingOnAuthentication = NO;
}

- (void) request:(FMWebDAVRequest*)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    if ([challenge previousFailureCount] == 0) {
        
        NSURLCredential *cred = [NSURLCredential credentialWithUser:@"gus"
                                                           password:@"foo"
                                                        persistence:NSURLCredentialPersistenceForSession];
        
        [[challenge sender] useCredential:cred forAuthenticationChallenge:challenge];
        
        return;
    }
}


- (void) requestDidCreateDirectory:(FMWebDAVRequest*)request {
    debug(@"response from create directory: %d", request.responseStatusCode);
    
    NSInteger responseStatusCode = [[[FMWebDAVRequest requestToURL:request.url] synchronous] propfind].responseStatusCode;
    
    if (207 == responseStatusCode) {
        // ok, let's delete it now...
        [[FMWebDAVRequest requestToURL:request.url delegate:self endSelector:nil contextInfo:nil] delete];
    }
}

@end
