//
//  PTKeyComboPanel.h
//  Protein
//
//  Created by Quentin Carnicelli on Sun Aug 03 2003.
//  Copyright (c) 2003 Quentin D. Carnicelli. All rights reserved.
//

#import <AppKit/AppKit.h>

@class PTKeyBroadcaster;
@class PTKeyCombo;
@class PTHotKey;

@interface PTKeyComboPanel : NSWindowController
{
	IBOutlet NSTextField*		mTitleField;
	IBOutlet NSTextField*		mComboField;
	IBOutlet PTKeyBroadcaster*	mKeyBcaster;

	NSString*				mTitleFormat;
	NSString*				mKeyName;
	PTKeyCombo*				mKeyCombo;

}

+ (PTKeyComboPanel*)sharedPanel;

- (int)runModal;
- (void)runModalForHotKey: (PTHotKey*)hotKey;

- (void)runSheeetForModalWindow: (NSWindow*)wind target: (id)obj;
	//Calls hotKeySheetDidEndWithReturnCode: (NSNumber*) on target object

- (void)setKeyCombo: (PTKeyCombo*)combo;
- (PTKeyCombo*)keyCombo;

- (void)setKeyBindingName: (NSString*)name;
- (NSString*)keyBindingName;

- (IBAction)ok: (id)sender;
- (IBAction)cancel: (id)sender;
- (IBAction)clear: (id)sender;
@end
