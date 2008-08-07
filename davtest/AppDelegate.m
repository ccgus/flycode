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
	
    NSString *baseURL = @"http://srv.local/webdav/";
    [[FMWebDAVRequest requestToURL:NSStringToURL(baseURL) delegate:self endSelector:nil contextInfo:nil] fetchDirectoryListing];
    
    
    NSString *dirURL = [baseURL stringByAppendingFormat:@"newdir-%d/", (int)[NSDate timeIntervalSinceReferenceDate]];
    [[FMWebDAVRequest requestToURL:NSStringToURL(dirURL) delegate:self endSelector:nil contextInfo:nil] createDirectory];
    
    
    NSString *putURL    = [baseURL stringByAppendingPathComponent:@"Compass.icns"];
    NSData *data        = [NSData dataWithContentsOfFile:@"/Applications/Safari.app/Contents/Resources/compass.icns"];
    [[FMWebDAVRequest requestToURL:NSStringToURL(putURL) delegate:self endSelector:nil contextInfo:nil] putData:data];
}

- (void) requestDidFetchDirectoryListing:(FMWebDAVRequest*)req {
    
    NSArray *directoryListing = [req directoryListing];
    
    for (NSString *file in directoryListing) {
        debug(@"file: %@", file);
    }
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
    
    // ok, let's delete it now...
    [[FMWebDAVRequest requestToURL:request.url delegate:self endSelector:nil contextInfo:nil] delete];
}

- (void) requestDidDelete:(FMWebDAVRequest*)request {
    debug(@"response from delete directory: %d", request.responseStatusCode);
}

- (void) requestDidPutData:(FMWebDAVRequest*)request {
    debug(@"response from putData: %d", request.responseStatusCode);
    
    [[FMWebDAVRequest requestToURL:request.url delegate:self endSelector:nil contextInfo:nil] get];
}

- (void) requestDidGet:(FMWebDAVRequest*)request {
    
    [[request responseData] writeToFile:@"/tmp/compass.icns" atomically:YES];
    system("open /tmp/compass.icns");
    
}

@end
