//
//  LHKeyGrabber.h
//  Luahack
//
//  Created by August Mueller on 10/13/06.
//  Copyright 2006 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LHKeyGrabberView.h"

@interface LHKeyGrabber : NSWindowController {
    NSString *keysToGrab;
    NSString *grabbedKeys;
    IBOutlet LHKeyGrabberView *grabberView;
}

+ (id) sharedKeyGrabber;

- (void) grabNextKey;

- (NSString *)keysToGrab;
- (void)setKeysToGrab:(NSString *)newKeysToGrab;

- (NSString *)grabbedKeys;
- (void)setGrabbedKeys:(NSString *)newGrabbedKeys;

- (IBAction) allDone:(id)sender;

@end
