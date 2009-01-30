//
//  ScriptStuffPlugin.m
//  ScriptStuff
//
//  Created by August Mueller on 10/25/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "ScriptStuffPlugin.h"


@implementation ScriptStuffPlugin



- (void) didRegister {
    id <VPPluginManager> pluginManager = [self pluginManager];
    
    [pluginManager addPluginsMenuTitle:@"Run as AppleScript"
                    withSuperMenuTitle:@"Script"
                                target:self
                                action:@selector(doAppleScript:)
                         keyEquivalent:@""
             keyEquivalentModifierMask:0];
    
    NSString *junk;
    
    // make sure the script is around.
    if (junk = [self findPythonScript]) {
        
        [pluginManager addPluginsMenuTitle:@"Format Python Code"
                        withSuperMenuTitle:@"Python"
                                    target:self
                                    action:@selector(doPythonFormat:)
                             keyEquivalent:@""
                 keyEquivalentModifierMask:0];
    }
}

- (NSString*) findPythonScript {
    
    NSBundle *b = [NSBundle bundleForClass:[self class]];
    
    return [b pathForResource:@"py2html" ofType:@"py"];
    
    
}

- (void) doPythonFormat:(id<VPPluginWindowController>)windowController; {

    NSTextView *textView    = [windowController textView];
    NSString *junk          = [[textView textStorage] string];
    
    NSRange selectedRange   = [textView selectedRange];
    if (selectedRange.length > 0) {
        junk = [junk substringWithRange:selectedRange];
    }
    else {
        selectedRange = NSMakeRange(0, [junk length]);
    }
    
    NSString *pythonFile    = @"/tmp/vp_script_stuff_python_format.py";
    NSString *htmlFile      = @"/tmp/vp_script_stuff_python_format.py.html";
    
    [[junk dataUsingEncoding:NSUTF8StringEncoding] writeToFile:pythonFile atomically:NO];
    
    NSString *pythonScriptPath = [self findPythonScript];
    
    if (pythonScriptPath) {
        chdir([[pythonScriptPath stringByDeletingLastPathComponent] UTF8String]);
    }
    
    
    NSTask *t = [NSTask launchedTaskWithLaunchPath:pythonScriptPath
                                         arguments:[NSArray arrayWithObject:pythonFile]];
    
    
    [t waitUntilExit];
    int status = [t terminationStatus];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (status == 0 && [fileManager fileExistsAtPath:htmlFile]) {
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        [options setValue:[NSNumber numberWithInt:1] forKey:@"UseWebKit"];
        
        NSString *html = [NSString stringWithContentsOfFile:htmlFile];
        
        NSAttributedString *as = [[[NSAttributedString alloc]
                                        initWithHTML:[html dataUsingEncoding:NSUTF8StringEncoding]
                                        options:options
                                  documentAttributes:nil]
                                    autorelease];
        
        if (as) {
            
            
            
            
            [textView fmReplaceCharactersInRange:selectedRange
                            withAttributedString:as];
        }
        
    }
    else {
        
        NSRunAlertPanel(@"Sorry", @"An error occured.", @"OK", nil, nil);
        
    }
    
}

- (void) doAppleScript:(id<VPPluginWindowController>)windowController; {
    
    NSString *junk = [[[windowController textView] textStorage] string];
    
    if (junk) {
        NSAppleScript *as = [[[NSAppleScript alloc] initWithSource:junk] autorelease];
        
        NSDictionary *errorDict;
        
        NSAppleEventDescriptor *desc = [as executeAndReturnError:&errorDict];
        
        if (!desc) {
            
            // uh oh.
            NSLog(@"%@", errorDict);
            
            NSRunAlertPanel([errorDict objectForKey:NSAppleScriptErrorBriefMessage],
                            [errorDict objectForKey:NSAppleScriptErrorMessage],
                            @"OK", nil, nil);
        }
    }
}



@end
