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

- (void)testURL:(NSString*)baseURL {
    [[FMWebDAVRequest requestToURL:NSStringToURL(baseURL)
                          delegate:self
                       endSelector:@selector(requestDidFetchDirectoryListingAndTestAuthenticationDidFinish:)
                       contextInfo:nil] fetchDirectoryListing];
    
    NSRunLoop * currentRunLoop = [NSRunLoop currentRunLoop];
    while (waitingOnAuthentication && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        // Empty
    }
    
    
    NSString *dirURL = [baseURL stringByAppendingFormat:@"newdir-%d/", (int)[NSDate timeIntervalSinceReferenceDate]];
    FMWebDAVRequest *createDir = [[[FMWebDAVRequest requestToURL:NSStringToURL(dirURL) delegate:self endSelector:nil contextInfo:nil] synchronous] createDirectory];
    
    assert([createDir responseStatusCode] == 201);
    
    NSString *putURL    = [baseURL stringByAppendingString:@"Compass.icns"];
    NSData *data        = [NSData dataWithContentsOfFile:@"/Applications/Safari.app/Contents/Resources/compass.icns"];
    
    (void)[[[FMWebDAVRequest requestToURL:NSStringToURL(putURL) delegate:self endSelector:nil contextInfo:nil] synchronous] putData:data];
    
    NSString *copyToURL = [baseURL stringByAppendingString:@"Compass-Copy.icns"];
    
    [[[FMWebDAVRequest requestToURL:NSStringToURL(putURL)] synchronous] copyToDestinationURL:NSStringToURL(copyToURL)];
    
    data = [[[FMWebDAVRequest requestToURL:NSStringToURL(copyToURL) delegate:self endSelector:nil contextInfo:nil] synchronous] get].responseData;
    
    [data writeToFile:@"/tmp/compass.icns" atomically:YES];
    system("open /tmp/compass.icns");
    
    FMWebDAVRequest *deleteReq = [[[FMWebDAVRequest requestToURL:NSStringToURL(putURL)] synchronous] delete];
    
    assert([deleteReq responseStatusCode] == 204);
    
    [[FMWebDAVRequest requestToURL:NSStringToURL(copyToURL)] delete];
}

- (void)awakeFromNib {
	
    waitingOnAuthentication = YES;
    
    [self testURL:@"http://127.0.0.1/webdav/"];
    
    system("mkdir /tmp/webdav");
    
    [self testURL:@"file:///tmp/webdav/"];
    
}

- (void)requestDidFetchDirectoryListingAndTestAuthenticationDidFinish:(FMWebDAVRequest*)req {
    
    NSArray *directoryListing = [req directoryListing];
    
    for (NSString *file in directoryListing) {
        debug(@"file: %@", file);
    }
    
    waitingOnAuthentication = NO;
}

- (void)request:(FMWebDAVRequest*)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    if ([challenge previousFailureCount] == 0) {
        
        NSURLCredential *cred = [NSURLCredential credentialWithUser:@"gus"
                                                           password:@"foo"
                                                        persistence:NSURLCredentialPersistenceForSession];
        
        [[challenge sender] useCredential:cred forAuthenticationChallenge:challenge];
        
        return;
    }
}


- (void)requestDidCreateDirectory:(FMWebDAVRequest*)request {
    
    NSInteger responseStatusCode = [[[FMWebDAVRequest requestToURL:request.url] synchronous] propfind].responseStatusCode;
    
    if (207 == responseStatusCode) {
        // ok, let's delete it now...
        [[FMWebDAVRequest requestToURL:request.url delegate:self endSelector:nil contextInfo:nil] delete];
    }
}

- (void)testErrorAction:(id)sender {
    
    // NOTE: the action verb must come after the finish block part if we're doing things synchronous.
    
    __block BOOL hadError = NO;
    
    debug(@"Sending syncronous, ui blocking request.");
    
    [[[[FMWebDAVRequest requestToURL:[NSURL URLWithString:@"http://127.0.0.1/not/a/good/endpoint"]] synchronous] withFinishBlock:^(FMWebDAVRequest *req) {
        debug(@"error code, which should be 404: %ld", [req responseStatusCode]);
        
        hadError = [req responseStatusCode] == 404;
        
    }] get];
    
    if (!hadError) {
        debug(@"WHOA, SOMETHING WRONG HAPPENED.");
    }
    else {
        debug(@"sync test over");
    }
}

- (void)testCopyAction:(id)sender {
    
    NSString *baseURL = @"http://127.0.0.1/webdav/";
    NSString *dirURL  = [baseURL stringByAppendingFormat:@"newdirb-%d/", (int)[NSDate timeIntervalSinceReferenceDate]];
    
    // NOTE: for a synchronous example, look at testErrorAction.  The action method will have to come at the end of the chain.
    // the stuff below only works with the verb before the block set, because of runloop scheduling.  I think.  It might be a bit ify.
    
    [[[FMWebDAVRequest requestToURL:NSStringToURL(dirURL)] createDirectory] withFinishBlock:^(FMWebDAVRequest *createRequest) {
        
        assert([createRequest responseStatusCode] == FMWebDAVCreatedStatusCode);
        
        
        NSURL *putURL    = [[createRequest url] URLByAppendingPathComponent:@"Compass.icns"];
        NSData *data     = [NSData dataWithContentsOfFile:@"/Applications/Safari.app/Contents/Resources/compass.icns"];
        
        debug(@"Directory created!");
        
        [[[FMWebDAVRequest requestToURL:putURL] putData:data] withFinishBlock:^(FMWebDAVRequest *putRequest) {
            
            debug(@"File put!");
            
            assert([createRequest responseStatusCode] == FMWebDAVCreatedStatusCode);
            
            [[[FMWebDAVRequest requestToURL:putURL] get] withFinishBlock:^(FMWebDAVRequest *getRequest) {
                
                assert([getRequest responseStatusCode] == FMWebDAVOKStatusCode);
                
                debug(@"Got the data!");
                
                [[getRequest responseData] writeToFile:@"/tmp/compass2.icns" atomically:YES];
                system("open /tmp/compass2.icns");
                
                [[[FMWebDAVRequest requestToURL:putURL] delete] withFinishBlock:^(FMWebDAVRequest *deleteRequest) {
                    
                    debug(@"Deleted file!");
                    
                    [[[FMWebDAVRequest requestToURL:NSStringToURL(dirURL)] delete] withFinishBlock:^(FMWebDAVRequest *deleteRequest) {
                        debug(@"Deleted dir.");
                    }];
                }];
            }];
        }];
    }];
}

- (void)testBadUrlAction:(id)sender {
    
    [[[FMWebDAVRequest requestToURL:NSStringToURL(@"http://someurlthatdoesnotexistfoo.com.barkingmad/haha/")] createDirectory] withFinishBlock:^(FMWebDAVRequest *createRequest) {
        debug(@"Done with stupid request");
    }];
}

- (void)testReleaseStuffAction:(id)sender {
    
    NSString *baseURL = @"http://127.0.0.1/webdav/";
    FMWebDAVRequest *req = [FMWebDAVRequest requestToURL:NSStringToURL(baseURL)];
    
    [req releaseWhenClosed];
    
    [[req fetchDirectoryListing] withFinishBlock:^(FMWebDAVRequest *dirFectcherWeIgnore) {
        NSArray *ar = [req directoryListing];
        debug(@"ar: '%@'", ar);
        // we just add an NSLog to the dealloc method of FMWebDAVRequest to make sure it's gone.
    }];
}

@end
