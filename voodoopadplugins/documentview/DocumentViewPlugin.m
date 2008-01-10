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
    NSString *lineBreak             = [NSString stringWithFormat: @"\n%C", NSFormFeedCharacter];
    
#define DocumentViewPagesList @"documentviewpagelist"
    
    NSArray *pagesList = [[windowController document] keys];
    
    if ([pagesList containsObject:DocumentViewPagesList]) {
        id <VPData> vpData = [[windowController document] pageForKey:DocumentViewPagesList];
        
        if ([vpData type] != VPPageType) {
            NSBeep();
            NSLog(@"Um... DocumentViewPagesList isn't a page.");
            return;
        }
        
        // ok, "lowercaseString" isn't exactly the algorithm VoodooPad uses for key names... but it's close enough for this.
        NSCharacterSet *newlineCharSet = [NSCharacterSet newlineCharacterSet];
        pagesList = [[[[vpData dataAsAttributedString] mutableString] lowercaseString] componentsSeparatedByCharactersInSet:newlineCharSet];
    }
    
    NSEnumerator *e                 = [pagesList objectEnumerator];
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
