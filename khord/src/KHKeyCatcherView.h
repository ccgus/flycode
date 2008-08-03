//
//  KHKeyCatcherView.h
//  khord
//
//  Created by August Mueller on 8/3/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KHKeyCatcherView : NSView {
    NSMutableDictionary *_keysPressed;
    IBOutlet NSTextView *theTextView;
}

@property (retain) NSMutableDictionary *keysPressed;

- (void) clear;

@end
