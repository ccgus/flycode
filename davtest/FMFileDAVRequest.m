//
//  FMFileDAVRequest.m
//  davtest
//
//  Created by August Mueller on 12/28/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "FMFileDAVRequest.h"


@implementation FMFileDAVRequest

- (void) sendRequest:(NSMutableURLRequest *)req {
    // wait, what?
    
}

- (NSString*) filePath {
    if (![_url isFileURL]) {
        [[NSException exceptionWithName:@"Invalid URL" reason:@"The URL passed is not a file URL" userInfo:nil] raise];
    }
    
    return [_url path];
}

- (void) callback {
    
    // I feel this is ... ugly.
    
    if (self.delegate && [self.delegate respondsToSelector:_endSelector]) {
        [self.delegate performSelector:_endSelector withObject:self];
    }
    
    [self autorelease];
}

- (FMWebDAVRequest*) createDirectory {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidCreateDirectory:);
    }
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if (![fileManager fileExistsAtPath:[self filePath]]) {
        self.responseStatusCode = [fileManager createDirectoryAtPath:[self filePath] attributes:nil] ? FMWebDAVCreatedStatusCode : FMHTTPNotImplementedErrorCode;
    }
    else {
        self.responseStatusCode = FMWebDAVMethodNotAllowedStatusCode;
    }
    
    
    [fileManager release];
    
    if (!_synchronous) {
        [self performSelector:@selector(callback) withObject:nil afterDelay:0];
    }
    
    return self;
}

- (FMWebDAVRequest*) delete {
    if (!_endSelector) {
        _endSelector = @selector(requestDidDelete:);
    }
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    self.responseStatusCode = [fileManager removeFileAtPath:[self filePath] handler:nil] ? FMWebDAVNoContentStatusCode : FMHTTPNotImplementedErrorCode;
    
    [fileManager release];
    
    if (!_synchronous) {
        [self performSelector:@selector(callback) withObject:nil afterDelay:0];
    }
    
    return self;
}

- (FMWebDAVRequest*) putData:(NSData*)data {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidPutData:);
    }
    
    self.responseStatusCode = [data writeToURL:_url atomically:YES] ? FMWebDAVNoContentStatusCode : FMHTTPNotImplementedErrorCode;
    
    if (!_synchronous) {
        [self performSelector:@selector(callback) withObject:nil afterDelay:0];
    }
    
    return self;
}

- (FMWebDAVRequest*) get {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidGet:);
    }
    
    self.responseData = [NSData dataWithContentsOfURL:_url];
    
    self.responseStatusCode = _responseData ? FMWebDAVOKStatusCode : FMWebDAVNotFoundStatusCode;
    
    
    if (!_synchronous) {
        [self performSelector:@selector(callback) withObject:nil afterDelay:0];
    }
    
    return self;
}

- (FMWebDAVRequest*) copyToDestinationURL:(NSURL*)dest {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidCopy:);
    }
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager copyItemAtPath:[self filePath] toPath:[dest path] error:nil]) {
        self.responseStatusCode = FMWebDAVOKStatusCode;
    }
    
    [fileManager release];
    
    if (!_synchronous) {
        [self performSelector:@selector(callback) withObject:nil afterDelay:0];
    }
    
    return self;
}

- (FMWebDAVRequest*) moveToDestinationURL:(NSURL*)dest {

    if (!_endSelector) {
        _endSelector = @selector(requestDidCopy:);
    }

    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:[dest path]] && ![fileManager removeItemAtPath:[dest path] error:nil]) {
        NSLog(@"Could not delete item at %@", [dest path]);
    }
    
    if ([fileManager moveItemAtPath:[self filePath] toPath:[dest path] error:nil]) {
        self.responseStatusCode = FMWebDAVOKStatusCode;
    }
    
    [fileManager release];
    
    if (!_synchronous) {
        [self performSelector:@selector(callback) withObject:nil afterDelay:0];
    }
    
    return self;
}

- (FMWebDAVRequest*) head {
    debug(@"unimplemented!!");
    debug(@"%s:%d", __FUNCTION__, __LINE__);
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
    return [self fetchDirectoryListingWithDepth:depth extraToPropfind:@""];
}

- (FMWebDAVRequest*) fetchDirectoryListingWithDepth:(NSUInteger)depth extraToPropfind:(NSString*)extra {
    
    if (!_endSelector) {
        _endSelector = @selector(requestDidFetchDirectoryListing:);
    }
    
    self.responseData = [NSData data]; // it wants to know that something was there.
    
    self.responseStatusCode = 207;
    
    if (!_synchronous) {
        [self performSelector:@selector(callback) withObject:nil afterDelay:0];
    }
    
    return self;
}

- (NSArray*) directoryListing {
    
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    
    NSString *directory = [self filePath];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:directory error:nil];
    NSMutableArray *returnFiles = [NSMutableArray array];
    NSEnumerator *e = [files objectEnumerator];
    NSString *file;
    BOOL isDir;

    while ((file = [e nextObject])) {
        
    	if ([fileManager fileExistsAtPath:[directory stringByAppendingPathComponent:file] isDirectory:&isDir] && isDir) {
            [returnFiles addObject:[NSString stringWithFormat:@"%@/", file]];
        }
        else {
            [returnFiles addObject:file];
        }
    }
    
    return returnFiles;
    
}

- (NSArray*) directoryListingWithAttributes {
    debug(@"unimplemented!!");
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return 0x00;
}

@end
