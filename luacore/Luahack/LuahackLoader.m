//
//  LuahackLoader.m
//  Luahack
//
//  Created by August Mueller on 10/13/06.
//  Copyright 2006 Flying Meat Inc.. All rights reserved.
//

#import "LuahackLoader.h"
#import <LuaCore/LuaCore.h>
#import "LHExtraFunctions.h"

@implementation LuahackLoader

+ (void) load {
	[self performSelector:@selector(install:) withObject:nil afterDelay:0.0];
}

+ (void)install:(id)sender {
    
    NSMenu *mainMenu    = [NSApp mainMenu];
    
    if (!mainMenu) {
        NSLog(@"crap.");
        return;
    }
    
    // install a separatorItem because it looks prettier that way.
    NSMenuItem *editMenu = [mainMenu itemWithTitle:@"Edit"];
    [[editMenu submenu] addItem:[NSMenuItem separatorItem]];

    // install our expansion stuff.
    NSMenuItem *luaItem = [[editMenu submenu] addItemWithTitle:@"Lua Expand" action:@selector(luaExpand:) keyEquivalent:@"l"];
    [luaItem  setKeyEquivalentModifierMask: NSCommandKeyMask | NSControlKeyMask];
    
    
    // make the folder to install our app specific handler.
    NSString *hacksPath = [@"~/Library/Application Support/Luahacks" stringByExpandingTildeInPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:hacksPath]) {
        [fileManager createDirectoryAtPath:hacksPath attributes:nil];
    }
    
    // install our app specific handler
    NSString *bundleId      = [[NSBundle mainBundle] bundleIdentifier];
    NSString *luahacksFile  = [hacksPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.lua", bundleId]];
    if ([fileManager fileExistsAtPath:luahacksFile]) {
        NSMenuItem *item = [[editMenu submenu] addItemWithTitle:@"Luahack" action:@selector(luahack:) keyEquivalent:@";"];
        [item setKeyEquivalentModifierMask: NSCommandKeyMask | NSControlKeyMask];
        [item setRepresentedObject:luahacksFile];
    }

    // xcode shit
    
    NSMenuItem *pop = [[editMenu submenu] addItemWithTitle:@"Popup" action:@selector(popSymbolsPopUp:) keyEquivalent:@";"];
    [pop  setKeyEquivalentModifierMask: NSControlKeyMask];
    
}

@end

@implementation NSObject (NSObjectLuahackAdditions)

- (void) luahack:(id)sender {
    static LCLua *olua = nil;
    
    NSString *hacksPath = [sender representedObject];
    
    if (!olua) {
        olua = [[LCLua readyLua] retain];
        lua_luahacks_extras_init([olua state]);
    }
    
    [olua pushGlobalObject:self          withName:@"self"];
    [olua pushGlobalObject:NSApp         withName:@"NSApp"];
    
    [olua runFileAtPath:hacksPath];
}

@end

@implementation NSTextView (NSTextViewLuahackAdditions) 

- (void) XCcompletionPlaceholderSelect {
    if ([self respondsToSelector:@selector(completionPlaceholderSelect:)]) {
        [self performSelector:@selector(completionPlaceholderSelect:) withObject:self];
    }
}

- (void) wipeCurrentWord {
    
    NSRange selectedRange = [self selectedRange];
    
    if (selectedRange.location > 0) {
        if (selectedRange.length == 0) {
            selectedRange.location--;
            selectedRange = [self selectionRangeForProposedRange:selectedRange granularity:NSSelectByWord];
        }
        
        if ([self shouldChangeTextInRange:selectedRange replacementString:@""]) {
            [self replaceCharactersInRange:selectedRange withString:@""];
        }
    }
}

- (void) luaExpand:(id)sender {
    static LCLua *lua = nil;
    
    //NSString *scriptPath = [[NSBundle bundleForClass:[LuahackLoader class]] pathForResource:@"expand" ofType:@"lua"];
    
    NSString *scriptPath = @"/Volumes/srv/Users/gus/Projects/luacore/Luahack/expand.lua";
    
    if (!scriptPath) {
        NSLog(@"Can't find expand.lua");
        return;
    }
    
    NSString *selectedWord = @"";
    NSRange selectedRange = [self selectedRange];
    if (selectedRange.location > 0) {
        if (selectedRange.length == 0) {
            selectedRange.location--;
            selectedRange = [self selectionRangeForProposedRange:selectedRange granularity:NSSelectByWord];
        }
        selectedWord = [[[self textStorage] mutableString] substringWithRange:selectedRange];
    }
    
    if (!lua) {
        lua = [[LCLua readyLua] retain];
        lua_luahacks_extras_init([lua state]);
    }
    
    [lua pushAsLuaString:selectedWord  withName:@"selectedWord"];
    [lua pushGlobalObject:self          withName:@"textView"];
    [lua pushGlobalObject:NSApp         withName:@"NSApp"];
    
    [lua runFileAtPath:scriptPath];
    
    BOOL success = NO;
    
    if (![lua bool:&success named:@"success"]) {
        NSLog(@"Could not find success in expand.lua");
    }
    
    if (!success) {
        [self complete:sender];
    }
}

@end
