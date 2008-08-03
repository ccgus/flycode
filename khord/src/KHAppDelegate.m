//
//  KHAppDelegate.m
//  khord
//
//  Created by August Mueller on 8/3/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import "KHAppDelegate.h"

@implementation KHAppDelegate

@synthesize hotKey=_hotKey;

- (void)awakeFromNib {
	
    id keyComboPlist;
    PTKeyCombo* keyCombo = nil;
    
    // Full Screen hot key
    keyComboPlist   = [[NSUserDefaults standardUserDefaults] objectForKey: @"KhordHotKey"];
    keyCombo        = [[[PTKeyCombo alloc] initWithPlistRepresentation: keyComboPlist] autorelease];
    
    //Create our hot key
    _hotKey = [[PTHotKey alloc] initWithIdentifier:@"KhordHotKey" keyCombo:keyCombo];	
    [_hotKey setName:@"Khord"]; //This is typically used by PTKeyComboPanel
    [_hotKey setTarget:self];
    [_hotKey setAction:@selector( hotKeyHit: ) ];
    //Register it
    [[PTHotKeyCenter sharedCenter] registerHotKey:_hotKey];
    
    
    
   	NSString *desc = [keyCombo description];
   	[hotkeyField setStringValue:desc];
    
}


- (void)hotKeySheetDidEndWithReturnCode: (NSNumber*)resultCode {
	
    if ([resultCode intValue] == NSOKButton) {
        
        //Update our hotkey with the new keycombo
        [_hotKey setKeyCombo: [[PTKeyComboPanel sharedPanel] keyCombo]];
        
        //Re-register it (required)
        [[PTHotKeyCenter sharedCenter] registerHotKey: _hotKey];
        
        [[NSUserDefaults standardUserDefaults] setObject: [[[PTKeyComboPanel sharedPanel] keyCombo] plistRepresentation] forKey: @"KhordHotKey"];
        
        
        NSString *desc = [[_hotKey keyCombo] description];
        [hotkeyField setStringValue:desc];
	}
}

- (void) setHotkey:(id)sender {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    PTKeyComboPanel* panel = [PTKeyComboPanel sharedPanel];
    
    [panel setKeyCombo:[_hotKey keyCombo]];
    [panel setKeyBindingName:[_hotKey name]];
    
    [panel runSheeetForModalWindow:hotkeyWindow target:self];
}


- (void) hotKeyHit:(id)sender {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    [catcherView clear];
    [popupWindow center];
    [popupWindow makeKeyAndOrderFront:self];
    [popupWindow makeFirstResponder:catcherView];
}




@end
