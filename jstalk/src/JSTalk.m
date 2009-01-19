//
//  JSTalk.m
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTalk.h"
#import "JSTListener.h"
#import "JSTScanner.h"
#import <ScriptingBridge/ScriptingBridge.h>
#include "mach_inject_bundle.h"

@implementation JSTalk
@synthesize T=_T;
@synthesize printController=_printController;

+ (void) load {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_T release];
    [super dealloc];
}

/*
- (id) injectApp:(NSString*)app withSource:(NSString*) source {
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"JSTalk" ofType:@"bundle"];
    
    //mach_error_t err = mach_inject_bundle_pid([bundlePath fileSystemRepresentation], pid );
    
}
*/

- (id) bridgeApp:(NSString*)appName {
    NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
    
    if (!appPath) {
        NSLog(@"Could not find application '%@'", appName);
        return nil;
    }
    
    NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
    NSString *bundleId  = [appBundle bundleIdentifier];
    
    return [SBApplication applicationWithBundleIdentifier:bundleId];
}


- (id) callApp:(NSString*)app withSource:(NSString*)source shouldInject:(BOOL)inject {
    
    NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:app];
    
    if (!appPath) {
        NSLog(@"Could not find application '%@'", app);
        return [NSNumber numberWithBool:NO];
    }
    
    NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
    NSString *bundleId  = [appBundle bundleIdentifier];
    
    // make sure it's running
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:bundleId
                                                         options:NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync
                                  additionalEventParamDescriptor:nil
                                                launchIdentifier:nil];
    
    NSString *port = [NSString stringWithFormat:@"%@.JSTalk", bundleId];
    
    inject = NO; // alright, this isn't working at all.
    if (inject) {
        
        NSUInteger pid = 0;
        for (NSDictionary *appInfo in [[NSWorkspace sharedWorkspace] launchedApplications]) {
            if ([bundleId isEqualToString:[appInfo objectForKey:@"NSApplicationBundleIdentifier"]]) {
                debug(@"appInfo: %@", appInfo);
                
                pid = [[appInfo objectForKey:@"NSApplicationProcessIdentifier"] unsignedIntegerValue];
            }
        }
        
        NSString *bundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
        
        if (pid && bundlePath) {
            mach_error_t err = mach_inject_bundle_pid([bundlePath fileSystemRepresentation], pid);
            
            if (err == err_mach_inject_bundle_couldnt_load_framework_bundle) {
                debug(@"err_mach_inject_bundle_couldnt_load_framework_bundle");
            }
            else if (err == err_mach_inject_bundle_couldnt_find_injection_bundle) {
                debug(@"err_mach_inject_bundle_couldnt_find_injection_bundle");
            }
            else if (err == err_mach_inject_bundle_couldnt_load_injection_bundle) {
                debug(@"err_mach_inject_bundle_couldnt_load_injection_bundle");
            }
            else if (err == err_mach_inject_bundle_couldnt_find_inject_entry_symbol) {
                debug(@"err_mach_inject_bundle_couldnt_find_inject_entry_symbol");
            }
            
            if (err) {
                return nil;
            }
        }
    }
    
    
    CFMessagePortRef remotePort = 0x00;
    
    NSUInteger tries = 0;
    
    while (!remotePort && tries < 10) {
        remotePort = CFMessagePortCreateRemote(kCFAllocatorDefault, (CFStringRef)port);
        tries++;
        if (!remotePort) {
            debug(@"Sleeping, waiting for %@ to open its port", app);
            sleep(1);
        }
    }
    
    if (!remotePort) {
        NSLog(@"Could not connect to %@", app);
        return [NSNumber numberWithBool:NO];
    }
    
    NSMutableDictionary *sendDictionary = [NSMutableDictionary dictionary];
    
    [sendDictionary setObject:_T forKey:@"T"];
    [sendDictionary setObject:source forKey:@"source"];
    
    
    NSString *err = 0x00;
    NSData *sendData = [NSPropertyListSerialization dataFromPropertyList:sendDictionary
                                                                  format:NSPropertyListBinaryFormat_v1_0
                                                        errorDescription:&err];
    
    [source dataUsingEncoding:NSUTF8StringEncoding];
    
    id returnValue = 0x00;
    
    CFDataRef reply = 0x00;
    
    SInt32 res = CFMessagePortSendRequest(remotePort, 0, (CFDataRef)sendData, 1, 1, kCFRunLoopDefaultMode, &reply);
    
    if (res == kCFMessagePortSuccess && reply) {
        
        NSPropertyListFormat format;
        NSDictionary *responseDict = [NSPropertyListSerialization propertyListFromData:(id)reply
                                                                      mutabilityOption:kCFPropertyListImmutable
                                                                                format:&format
                                                                      errorDescription:&err];
        
        if ([responseDict objectForKey:@"T"]) {
            
            self.T = [[[responseDict objectForKey:@"T"] mutableCopy] autorelease];
            
            [self pushObject:self.T withName:@"T" inController:[JSCocoaController sharedController]];
        }
        
        returnValue = [responseDict objectForKey:@"returnValue"];
        
    }
    
    CFRelease(remotePort);
    
    //return [NSNumber numberWithBool:(res == kCFMessagePortSuccess)];
    return returnValue;
}

- (void) pushObject:(id)obj withName:(NSString*)name inController:(JSCocoaController*)jsController {
    
    JSContextRef ctx                = [jsController ctx];
    JSStringRef jsName              = JSStringCreateWithUTF8CString([name UTF8String]);
    JSObjectRef jsObject            = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
    JSCocoaPrivateObject *private   = JSObjectGetPrivate(jsObject);
    private.type = @"@";
    [private setObject:obj];
    
    JSObjectSetProperty(ctx, JSContextGetGlobalObject(ctx), jsName, jsObject, 0, NULL);
    JSStringRelease(jsName);  
    
}

- (void) executeString:(NSString*) str {
    
    
    JSTScanner *scanner = [JSTScanner scannerWithString:str];
    
    [scanner scan];
    
    NSMutableString *newSource = [NSMutableString string];
    
    for (NSDictionary *frame in [scanner frames]) {
        
        NSString *appName = [frame objectForKey:@"appName"];
        NSString *script = [frame objectForKey:@"script"];
        
        if ([@".local" isEqualToString:appName]) {
            [newSource appendString:script];
            [newSource appendString:@"\n"];
        }
        else {
            
            script = [script stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            
            script = [script stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
            script = [script stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
            script = [script stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n\\\n"];
            
            [newSource appendFormat:@"JSTalk.callApp_withSource_shouldInject(\"%@\", \"\\\n%@\", true);\n", appName, script];
        }
    }
    
    
    [newSource replaceOccurrencesOfString:@"JSApp(\"" withString:@"JSTalk.bridgeApp(\"" options:0 range:NSMakeRange(0, [newSource length])];
    [newSource replaceOccurrencesOfString:@"JSTalk." withString:@"JSTalkx." options:0 range:NSMakeRange(0, [newSource length])];
    
    JSCocoaController *jsController = [JSCocoaController sharedController];
    
    if (!_T) {
        self.T = [NSMutableDictionary dictionary];
    }
    
    [self pushObject:_T withName:@"T" inController:jsController];
    [self pushObject:NSApp withName:@"App" inController:jsController];
    [self pushObject:NSApp withName:@"Application" inController:jsController];
    [self pushObject:self withName:@"JSTalkx" inController:jsController];
    [self pushObject:jsController withName:@"jsc" inController:jsController];
    
    @try {
        [jsController setUseAutoCall:NO];
        [jsController evalJSString:@"function print(s) { JSTalkx.print(s); }"];
        [jsController evalJSString:newSource];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    @finally {
        //
    }
}


- (BOOL) sendJavascript:(NSString*)msg toBundleId:(NSString*)bundleId response:(NSString**)response {
    
    NSString *port = [NSString stringWithFormat:@"%@.JSTalk", bundleId];
    
    CFMessagePortRef remotePort = CFMessagePortCreateRemote(kCFAllocatorDefault, (CFStringRef)port);
    if (!remotePort) {
        return NO;
    }
    
    NSData *sendData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    
    CFDataRef reply = 0x00;
    
    SInt32 res = CFMessagePortSendRequest(remotePort, 0, (CFDataRef)sendData, 1, 1, kCFRunLoopDefaultMode, &reply);
    
    if (res == kCFMessagePortSuccess && reply) {
        *response = [[[NSString alloc] initWithData:(id)reply encoding:NSUTF8StringEncoding] autorelease];
        debug(@"reply: %@", reply);
        debug(@"here is our return data: %@\n", *response);
        CFRelease(reply);
    }
    
    CFRelease(remotePort);
    
    return (res == kCFMessagePortSuccess);
    
}

- (JSCocoaController*) jsController {
    // right now we just return a shared one.
    return [JSCocoaController sharedController];
}

- (id) callFunctionNamed:(NSString*)name withArguments:(NSArray*)args {
    
    JSCocoaController *jsController = [self jsController];
    JSContextRef ctx = [jsController ctx];
    
    
    JSValueRef exception            = 0x00;   
    JSStringRef functionName        = JSStringCreateWithUTF8CString([name UTF8String]);
    JSValueRef functionValue        = JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), functionName, &exception);
    
    JSStringRelease(functionName);  
    
    JSValueRef returnValue = [jsController callJSFunction:functionValue withArguments:args];
    
    id returnObject;
    [JSCocoaFFIArgument unboxJSValueRef:returnValue toObject:&returnObject inContext:ctx];
    
    return returnObject;
}

+ (void) listen {
    [JSTListener listen];
}

- (void) print:(NSString*)s {
    
    if (_printController && [_printController respondsToSelector:@selector(print:)]) {
        [_printController print:s];
    }
    else {
        NSLog(@"%@", s);
    }
}

@end
