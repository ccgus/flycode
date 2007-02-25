//
//  FMLua.h
//  luatest
//
//  Created by August Mueller on 12/4/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

extern NSString *FMRunningInLuaKey;

@interface LCLua : NSObject {
    lua_State *L;
}

+ (id) readyLua;

- (lua_State*) state;

- (void) setup;
- (void) tearDown;

- (void) runBuffer:(NSString*)buf;
- (void) runFileAtPath:(NSString*)filePath;

- (BOOL) int:(int*)val named:(NSString*)name;
- (BOOL) bool:(BOOL*)val named:(NSString*)name;
- (BOOL) float:(float*)val named:(NSString*)name;
- (BOOL) double:(double*)val named:(NSString*)name;

- (NSNumber*) numberNamed:(NSString*)name;
- (NSString*) stringNamed:(NSString*)name;
- (id) objectNamed:(NSString*)name;

- (void) pushGlobalObject:(id)object withName:(NSString*)name;
- (void) pushDictionaryAsTable:(NSDictionary*)d withName:(NSString*)name;
- (void) pushAsLuaString:(NSString*)s withName:(NSString*)name;
- (void) callEmptyFunctionNamed:(NSString*)functionName;
- (void) callFunction:(NSString*)functionName withArg:(id)arg;

+ (NSString*) runScriptInBundle:(NSString*)scriptName withInput:(NSString*)input named:(NSString*)inputNamed recievingOuputNamed:(NSString*)outName;

@end
