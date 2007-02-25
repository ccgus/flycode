//
//  LHKeyGrabber.m
//  Luahack
//
//  Created by August Mueller on 10/13/06.
//  Copyright 2006 Flying Meat Inc.. All rights reserved.
//

#import "LHKeyGrabber.h"


@implementation LHKeyGrabber

+ (id) sharedKeyGrabber {
    
    static id me = nil;
    
    if (!me) {
        me = [[self alloc] initWithWindowNibName:@"KeyGrabber"];
    }
    
    return me;
}

- (void) grabNextKey {
    [[self window] makeFirstResponder:grabberView];
    [NSApp runModalForWindow:[self window]];
}

- (IBAction) allDone:(id)sender {
    [NSApp stopModal];
    [[self window] orderOut:self];
}

- (NSString *)keysToGrab {
    return keysToGrab; 
}
- (void)setKeysToGrab:(NSString *)newKeysToGrab {
    [newKeysToGrab retain];
    [keysToGrab release];
    keysToGrab = newKeysToGrab;
}

- (NSString *)grabbedKeys {
    return grabbedKeys; 
}
- (void)setGrabbedKeys:(NSString *)newGrabbedKeys {
    [newGrabbedKeys retain];
    [grabbedKeys release];
    grabbedKeys = newGrabbedKeys;
}


@end


