//
//  LuahackExtraFunctions.m
//  Luahack
//
//  Created by August Mueller on 10/13/06.
//  Copyright 2006 Flying Meat Inc.. All rights reserved.
//

#import "LHExtraFunctions.h"
#import "LHKeyGrabber.h"
#import <objc/objc-runtime.h>

extern int lua_uppercase(lua_State *L) {
    
    const char *c = luaL_checkstring (L, 1);
    NSString *s = [NSString stringWithUTF8String:c];
	
    s = [s uppercaseString];
    
    lua_pushfstring(L, [s UTF8String]);
    
    return 1;
}

extern int lua_grab_next_key(lua_State *L) {
    
    NSString *s = [NSString stringWithUTF8String:luaL_checkstring (L, 1)];
    
    LHKeyGrabber *grabber = [LHKeyGrabber sharedKeyGrabber];
    [grabber setKeysToGrab:s];
    [grabber grabNextKey];
    
    lua_pushfstring(L, [[grabber grabbedKeys] UTF8String]);
    return 1;
}


extern int lua_grab_view(lua_State *L) {
    
    NSEvent  *event;
    NSCursor *cursor = [NSCursor crosshairCursor];  
    
    [cursor push];
    
    NSView *selectedView = 0x00;
    
    do {
        event = [NSApp nextEventMatchingMask:~0 untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
    }
    while ([event type] != NSLeftMouseDown && selectedView == nil);
    
    [cursor pop];
    
    selectedView = [[[[event window] contentView] superview] hitTest:[event locationInWindow]];
    
    if (selectedView) {
        lua_objc_pushid(L, selectedView);
        return 1;
    }
    
    return 0;
}


extern int lua_methodNamesForObject(lua_State *L) {
    
    id o = (id)lua_objc_toid(L, 1);
    Class c = [o class];
    
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    do {
        void *iterator = 0;
        struct objc_method_list *mlist = class_nextMethodList(c, &iterator);
        while (mlist != NULL) {
            int i;
            for (i = 0; i < mlist->method_count; i++) {
                Method method = &(mlist->method_list[i]);
                if (method == NULL) {
                    continue;
                }
                SEL sel = method->method_name;
                NSString *methodName = NSStringFromSelector(sel);
                [d setObject:methodName forKey:methodName];
            }
            mlist = class_nextMethodList(c, &iterator);
        }
    }
    while (c = [c superclass]);
    
    lua_objc_pushid(L, [d keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)]);
    
    return 1;
}


const luaL_reg lua_luahacks_extras_functions[]={
    
	{"nextKey", lua_grab_next_key},
	{"grabView", lua_grab_view},
	{"methodNamesForObject", lua_methodNamesForObject},
	{"uppercase", lua_uppercase},
	{NULL,NULL},
};

void lua_luahacks_extras_init(lua_State* state) {
    luaL_openlib(state, "_G", lua_luahacks_extras_functions, 0);
}

