//
//  ScriptStuffPlugin.m
//  ScriptStuff
//
//  Created by August Mueller on 10/25/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "DocumentViewPlugin.h"
#import "DocumentViewWindowController.h"

@implementation DocumentViewPlugin

- (void) didRegister {
    id <VPPluginManager> pluginManager = [self pluginManager];
    
    [pluginManager addPluginsMenuTitle:@"View Entire Document"
                    withSuperMenuTitle:@"Miscellaneous"
                                target:self
                                action:@selector(viewDocument:)
                         keyEquivalent:@"p"
             keyEquivalentModifierMask:NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask];
    
}


- (void)dealloc {
	[super dealloc];
    
}

- (void) viewDocument:(id<VPPluginWindowController>)windowController {
    
    NSMutableAttributedString *as   = [[NSMutableAttributedString alloc] init];
    NSEnumerator *e                 = [[[windowController document] keys] objectEnumerator];
    NSString *lineBreak             = [NSString stringWithFormat: @"\n%C", NSFormFeedCharacter];
    NSString *key                   = [e nextObject];
    
    while (key) {
        
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
        id <VPData> vpData = [[windowController document] pageForKey:key];
        
        if ([vpData type] == VPPageType) {
            NSMutableAttributedString *pageAts = [vpData dataAsAttributedString];
            
            if ([pageAts length] == 0) {
                pageAts = [[[NSMutableAttributedString alloc] initWithString:@" "] autorelease];
            }
            
            [pageAts addAttribute:@"VPPageName" value:[vpData displayName] range:NSMakeRange(0, [pageAts length])];
            [as appendAttributedString:pageAts];
        }
        
        key = [e nextObject];
        
        if (key) {
            [[as mutableString] appendString:lineBreak];
        }
        
        [pool release];
        
    }
    
    DocumentViewWindowController *wc = [[DocumentViewWindowController alloc] initWithWindowNibName:@"DocumentViewWindow"];
    
    [wc loadAttributedString:as];
    
    [[wc window] makeKeyAndOrderFront:self];
    
    [as release];
}



@end
