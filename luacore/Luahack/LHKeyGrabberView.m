//
//  LHKeyGrabberView.m
//  Luahack
//
//  Created by August Mueller on 10/13/06.
//  Copyright 2006 Flying Meat Inc.. All rights reserved.
//

#import "LHKeyGrabberView.h"
#import "LHKeyGrabber.h"

@implementation LHKeyGrabberView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

- (void) keyDown: (NSEvent*) anEvent {
    NSString *key = [anEvent charactersIgnoringModifiers];
    debug(@"key: %@", key);

    [[[self window] delegate] setGrabbedKeys:key];
    [[[self window] delegate] allDone:self];
}

@end
