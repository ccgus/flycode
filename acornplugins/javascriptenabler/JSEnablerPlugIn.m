#import "JSEnablerPlugIn.h"
#import "JSCocoaController.h"
#import "ACPlugin.h"

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
    /*
      
      this space intentionally left blank.
      
    */
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
                            keyEquivalent:@"j"
                keyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask
                               userObject:[pluginDir stringByAppendingPathComponent:fileName]];
        
    }
}





- (CIImage*) executeScriptForImage:(CIImage*)image scriptPath:(NSString*)scriptPath {
    
    NSError *err            = 0x00;
    NSString *theJavaScript = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:&err];
    
	JSCocoaController *jsController     = [JSCocoaController sharedController];
    JSGlobalContextRef ctx              = [jsController ctx];
    
    // first load up the script.
    [jsController evalJSString:theJavaScript];
    
    
    // now we're going to call our main(img) function in the javascript file.
    // IT BETTER BE THERE OR ELSE!
    JSValueRef exception            = 0x00;   
    JSStringRef functionName        = JSStringCreateWithUTF8CString("main");
    JSValueRef functionValue        = JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), functionName, &exception);
    
    JSStringRelease(functionName);  
    
    if (exception) {
        NSLog(@"%@", [jsController formatJSException:exception]);
        return nil;
    }
    
    JSObjectRef jsFunctionObject = JSValueToObject(ctx, functionValue, &exception);
    
    if (exception) {
        NSLog(@"%@", [jsController formatJSException:exception]);
        return nil;
    }
    
    JSValueRef imageArgRef;
    [JSCocoaFFIArgument boxObject:image toJSValueRef:&imageArgRef inContext:ctx];
    
    JSValueRef mainFunctionArgs[1] = { imageArgRef };
    
    JSValueRef returnValue = JSObjectCallAsFunction(ctx, jsFunctionObject, nil, 1, mainFunctionArgs, &exception);
    
    if (exception) {
        NSLog(@"%@", [jsController formatJSException:exception]);
        return nil;
    }
    
    CIImage *acornReturnValue = 0x00;
    
    if (![JSCocoaFFIArgument unboxJSValueRef:returnValue toObject:&acornReturnValue inContext:ctx]) {
        return nil;
    }
    
    return acornReturnValue;
}

@end



/*

An alternative way to call our function.

- (CIImage*) executeScriptForImage:(CIImage*)image scriptPath:(NSString*)scriptPath {
    
    NSError *err            = 0x00;
    NSString *theJavaScript = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:&err];
    
	JSCocoaController *jsController     = [JSCocoaController sharedController];
    JSGlobalContextRef ctx              = [jsController ctx];
    
    // first load up the script.
    [jsController evalJSString:theJavaScript];
    
    
    // now we're going to put the image that we're handed into the javascript context
    JSStringRef jsName = JSStringCreateWithUTF8CString("_acornPrivateCIImageVar");
    JSObjectRef jsObject = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
    JSCocoaPrivateObject *private = JSObjectGetPrivate(jsObject);
    private.type = @"@";
    [private setObject:image];
    
    JSObjectSetProperty(ctx, JSContextGetGlobalObject(ctx), jsName, jsObject, 0, NULL);
    JSStringRelease(jsName);  
    
    
    // now, we're going to call the main() function that should have been in the script.
    // we're also going to assign the return value to "_acornReturnValue", which we'll pluck out below
    [jsController evalJSString:@"_acornReturnValue = main(_acornPrivateCIImageVar);"];
    
    // ok, let the plucking begin.
    JSStringRef returnName = JSStringCreateWithUTF8CString("_acornReturnValue");
    JSValueRef exception = 0x00;
    JSValueRef returnValueValue = JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), returnName, &exception);
    
    CIImage *x_acornReturnValue = 0x00;
    
    if (exception) {
        NSLog(@"%@", [jsController formatJSException:exception]);
    }    
    else if ([JSCocoaFFIArgument unboxJSValueRef:returnValueValue toObject:&x_acornReturnValue inContext:ctx]) {
        // woo hoo!
    }
    JSStringRelease(returnName);  
    
    // because I'm paranoid.
    [jsController evalJSString:@"x_acornReturnValue = null;"];
    
    // return our ciimage
    return x_acornReturnValue;
}




 */
 








