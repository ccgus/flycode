//
//  KHAppDelegate.h
//  khord
//
//  Created by August Mueller on 8/3/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTKeyComboPanel.h"
#import "PTHotKey.h"
#import "PTHotKeyCenter.h"
#import "KHKeyCatcherView.h"

@interface KHAppDelegate : NSObject {
    IBOutlet NSWindow *hotkeyWindow;
    IBOutlet NSWindow *popupWindow;
    IBOutlet NSTextField *hotkeyField;
    
    IBOutlet KHKeyCatcherView *catcherView;
    
    PTHotKey *_hotKey;
}

@property (retain) PTHotKey *hotKey;

- (void) setHotkey:(id)sender;

@end
