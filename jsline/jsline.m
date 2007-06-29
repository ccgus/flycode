#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

#define debug NSLog

// I'm a theif:
// http://www.cocoabuilder.com/archive/message/cocoa/2005/9/27/147038

@interface InputHandler : NSObject {
    BOOL finished;
    JSGlobalContextRef ctx;
}

@end

@implementation InputHandler

- (id) init {
    if ((self = [super init])) {
        
        ctx = JSGlobalContextCreate(NULL);
        
        // Read from stdin
        NSFileHandle *inHandle = [NSFileHandle fileHandleWithStandardInput];
        
        // Listen for incoming data notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stdinDataAvailable)
                                                     name:NSFileHandleDataAvailableNotification
                                                   object:inHandle];
        
        [inHandle waitForDataInBackgroundAndNotify];
    }
    
    return self;
}

- (void) dealloc {
    // Release JavaScript execution context.
    // not that we ever get here.
    JSGlobalContextRelease(ctx);

    [super dealloc];
}

- (BOOL) isFinished {
    return finished;
}


- (void) evaluate:(NSString*)script {
    
    // Evaluate script.
    JSStringRef scriptJS = JSStringCreateWithCFString((CFStringRef)script);
    JSValueRef result = JSEvaluateScript(ctx, scriptJS, NULL, NULL, 0, NULL);
    JSStringRelease(scriptJS);
    
    // Convert result to string, unless result is NULL.
    CFStringRef resultString;
    if (result) {
        JSStringRef resultStringJS = JSValueToStringCopy(ctx, result, NULL);
        resultString = JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
        JSStringRelease(resultStringJS);
        
        [(NSString *)resultString autorelease];
        
        printf("%s\n", [(NSString *)resultString UTF8String]);
        
    }
    else {
        printf("[Exception]\n");
    }
}

- (void) stdinDataAvailable {
    NSFileHandle *inHandle = [NSFileHandle fileHandleWithStandardInput];
    NSData *theData = [inHandle availableData];
    
    if ([theData length] == 0) {
        finished = YES;
        return;
    }
    
    NSString *theScript = [[[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding] autorelease];
    
    if ([theScript length] > 1) {
        [self evaluate:theScript];
    }
    
    // Listen for more
    [inHandle waitForDataInBackgroundAndNotify];
}


@end


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    
    // Create the input handler
    InputHandler *ih = [[[InputHandler alloc] init] autorelease];
    
    while (![ih isFinished]) {
        // Kick the run loop
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    }
    
    
    
    [pool release];
    return 0;
}
