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
    
    [pluginManager addPluginsMenuTitle:@"Save Document as PDF"
                    withSuperMenuTitle:@"Miscellaneous"
                                target:self
                                action:@selector(pdfDocument:)
                         keyEquivalent:@"o"
             keyEquivalentModifierMask:NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask];
    
}


- (void)dealloc {
	[super dealloc];
    
}

- (NSMutableAttributedString *) makeAttributedStringFromDocument:(id<VPPluginDocument>)document {
    
    NSMutableAttributedString *as   = [[[NSMutableAttributedString alloc] init] autorelease];
    NSString *lineBreak             = [NSString stringWithFormat: @"\n%C", NSFormFeedCharacter];
    
#define DocumentViewPagesList @"documentviewpagelist"
    
    NSArray *pagesList = [document keys];
    
    if ([pagesList containsObject:DocumentViewPagesList]) {
        id <VPData> vpData = [document pageForKey:DocumentViewPagesList];
        
        if ([vpData type] != VPPageType) {
            NSBeep();
            NSLog(@"Um... DocumentViewPagesList isn't a page.");
            return nil;
        }
        
        // ok, "lowercaseString" isn't exactly the algorithm VoodooPad uses for key names... but it's close enough for this.
        NSCharacterSet *newlineCharSet = [NSCharacterSet newlineCharacterSet];
        pagesList = [[[[vpData dataAsAttributedString] mutableString] lowercaseString] componentsSeparatedByCharactersInSet:newlineCharSet];
    }
    
    NSEnumerator *e                 = [pagesList objectEnumerator];
    NSString *key                   = [e nextObject];
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    while (key) {
        
        id <VPData> vpData = [document pageForKey:key];
        
        key = [e nextObject];
        
        if ([vpData type] == VPPageType) {
            NSMutableAttributedString *pageAts = [vpData dataAsAttributedString];
            
            if ([pageAts length] == 0) {
                pageAts = [[[NSMutableAttributedString alloc] initWithString:@" "] autorelease];
            }
            
            [pageAts addAttribute:@"VPPageName" value:[vpData displayName] range:NSMakeRange(0, [pageAts length])];
            [as appendAttributedString:pageAts];
            
            if (key) {
                [[as mutableString] appendString:lineBreak];
            }
        }
        
        [pool drain];
        
    }
    
    [pool release];
    
    return as;
}

- (void) pdfDocument:(id<VPPluginWindowController>)windowController {
    
    NSMutableAttributedString *as = [self makeAttributedStringFromDocument:[windowController document]];
    
    DocumentViewWindowController *wc = [[DocumentViewWindowController alloc] initWithWindowNibName:@"DocumentViewWindow"];
    
    [wc loadAttributedString:as];
    
    [(id)wc printDocument:nil];
    
}

- (void) viewDocument:(id<VPPluginWindowController>)windowController {
    
    NSMutableAttributedString *as = [self makeAttributedStringFromDocument:[windowController document]];
    
    DocumentViewWindowController *wc = [[DocumentViewWindowController alloc] initWithWindowNibName:@"DocumentViewWindow"];
    
    [wc loadAttributedString:as];
    
    [[wc window] makeKeyAndOrderFront:self];
    
    [as release];
}



@end
