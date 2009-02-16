#import "JSEnablerPlugIn.h"
#import "ACPlugin.h"
#import <JSTalk/JSTalk.h>
#import <JSTalk/JSCocoaController.h>

@interface JSEnablerPlugIn (SuperSecret)
- (void) findJSCocoaScriptsForPluginManager:(id<ACPluginManager>)pluginManager;
@end


@implementation JSEnablerPlugIn

+ (id) plugin {
    return [[[self alloc] init] autorelease];
}

- (void) willRegister:(id<ACPluginManager>)pluginManager {
    [self findJSCocoaScriptsForPluginManager:pluginManager];
}

- (void) didRegister {
    
    // this guy openes up a port to listen for outside JSTalk commands commands
    [JSTalk listen];
}

- (void) findJSCocoaScriptsForPluginManager:(id<ACPluginManager>)pluginManager {
    
    NSString *pluginDir = [@"~/Library/Application Support/Acorn/Plug-Ins/" stringByExpandingTildeInPath];
    NSFileManager *fm   = [NSFileManager defaultManager];
    BOOL isDir          = NO;
    
    if (!([fm fileExistsAtPath:pluginDir isDirectory:&isDir] && isDir)) {
        return;
    }
    
    for (NSString *fileName in [fm contentsOfDirectoryAtPath:pluginDir error:nil]) {
        
        if (!([fileName hasSuffix:@".js"] || [fileName hasSuffix:@".jscocoa"])) {
            continue;
        }
        
        [pluginManager addFilterMenuTitle:[fileName stringByDeletingPathExtension]
                       withSuperMenuTitle:@"JavaScript"
                                   target:self
                                   action:@selector(executeScriptForImage:scriptPath:)
                            keyEquivalent:@""
                keyEquivalentModifierMask:0
                               userObject:[pluginDir stringByAppendingPathComponent:fileName]];
    }
}





- (CIImage*) executeScriptForImage:(CIImage*)image scriptPath:(NSString*)scriptPath {
    
    NSError *err            = 0x00;
    NSString *theJavaScript = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:&err];
    
    if (err) {
        NSBeep();
        NSLog(@"%@", err);
        return nil;
    }
    
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    [jstalk executeString:theJavaScript];
    
    /*
    
    // JSCocoaController is a singleton object which holds a single JavaScript context which gets used over and over.
	JSCocoaController *jsController     = [JSCocoaController sharedController];
    JSGlobalContextRef ctx              = [jsController ctx];
    
    // evaluate our script, which has "function main(image) { ... }" in it somewhere.
    // or at least we hope it does.
    [jsController setUseAutoCall:NO];
    [jsController evalJSString:theJavaScript];
    
    // now we're going to get a reference to our main(image) method, by asking the JS context for it, and stuff it
    // in a var named "jsFunctionObject"
    JSValueRef exception            = 0x00;   
    JSStringRef functionName        = JSStringCreateWithUTF8CString("main");
    JSValueRef functionValue        = JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), functionName, &exception);
    
    JSStringRelease(functionName);  
    
    // Check for errors and bail if there are any.  formatJSException: is a handy way of way of printing out line
    // numbers and such.
    if (exception) { 
        NSLog(@"%@", [jsController formatJSException:exception]);
        return nil;
    }
    
    JSObjectRef jsFunctionObject = JSValueToObject(ctx, functionValue, &exception);
    
    if (exception) { // Once again, check for errors and bail if there are any
        NSLog(@"%@", [jsController formatJSException:exception]);
        return nil;
    }
    
    
    // Now that we've got a handle to the function we want to call, we need to push our cocoa object into a 
    // javascript object, which we'll pass to the main() method.
    
    JSValueRef imageArgRef;
    [JSCocoaFFIArgument boxObject:image toJSValueRef:&imageArgRef inContext:ctx];
    
    // This is the array that holds the args we pass to our main() method.  We've just got one argument, which
    // is our ciiimage
    JSValueRef mainFunctionArgs[1] = { imageArgRef };
    
    // finally, call the function with our arguments.
    JSValueRef returnValue = JSObjectCallAsFunction(ctx, jsFunctionObject, nil, 1, mainFunctionArgs, &exception);
    
    if (exception) { // Bad things?  If yes, bail.
        NSLog(@"%@", [jsController formatJSException:exception]);
        return nil;
    }
    
    // Hurray?
    // The main() method should be returning a value at this point, so we're going to 
    // put it back into a cocoa object.  If it's not there, then it'll be nil and that's 
    // ok for our purposes.
    CIImage *acornReturnValue = 0x00;
    
    if (![JSCocoaFFIArgument unboxJSValueRef:returnValue toObject:&acornReturnValue inContext:ctx]) {
        return nil;
    }
    
    // fin.
    return acornReturnValue;
    */
    
    return nil;
}

@end









