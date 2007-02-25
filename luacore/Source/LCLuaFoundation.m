
#import "LCLuaFoundation.h"
#import "LuaObjCBridge.h"
#include "unistd.h"

extern int luaToNSString (lua_State *lua) {
    
    const char *luaString = luaL_checkstring (lua, 1);
    
    NSString *nsString = [NSString stringWithUTF8String:luaString];
    
    lua_objc_pushid(lua, nsString);
    return 1;  /* number of results */
    
}

extern int nsToLuaString (lua_State *lua) {
    
    if (!lua_objc_isid(lua, 1)) {
        NSLog(@"Could not convert to string");
        return 0;
    }
    
    id o = lua_objc_toid(lua, 1);
    
    if (!o) {
        NSLog(@"Could not convert to string");
        return 0;
    }
    
    lua_pushstring(lua, [[o description] UTF8String]);
    
    return 1; /* number of results */
}


extern int nsToLuaRange(lua_State *lua) {
    if (!lua_isuserdata(lua, 1)) {
        NSLog(@"Could not convert to id");
        return 0;
    }
    
    NSRange r;
    memcpy( &(r), lua_touserdata(lua, 1), sizeof(NSRange));
    
    lua_newtable(lua);
    int tableIdx = lua_gettop(lua);
    
	lua_pushstring(lua,"location");
	lua_pushnumber(lua, r.location);
	lua_settable(lua,   tableIdx);
    
	lua_pushstring(lua,"length");
	lua_pushnumber(lua, r.length);
	lua_settable(lua,   tableIdx);
    
    return 1;
}

extern int luaToNSRange(lua_State *lua) {
    
    if (!lua_istable(lua, 1)) {
        NSLog(@"Cound not convert to NSRange");
        return 0;
    }
    
    NSRange r = NSMakeRange(0, 0);
    
    NSDictionary *d = dictionaryFromCurrentTable(lua);
        
    if (!([d objectForKey:@"location"] && [d objectForKey:@"length"])) {
        printf("Cound not find both location and length keys in table\n");
        return 0;
    }
    
    r.location  = [[d objectForKey:@"location"] intValue];
    r.length    = [[d objectForKey:@"length"] intValue];
    
    void* result = lua_newuserdata(lua, sizeof(NSRange));
    memcpy(result, &(r), sizeof(NSRange));
    
    return 1;
}

extern int nsToLuaPoint(lua_State *lua) {
    if (!lua_isuserdata(lua, 1)) {
        NSLog(@"Could not convert to id");
        return 0;
    }
    
    NSPoint p;
    memcpy( &(p), lua_touserdata(lua, 1), sizeof(NSPoint));
    
    lua_newtable(lua);
    int tableIdx = lua_gettop(lua);
    
	lua_pushstring(lua,"x");
	lua_pushnumber(lua, p.x);
	lua_settable(lua,   tableIdx);
    
	lua_pushstring(lua,"y");
	lua_pushnumber(lua, p.y);
	lua_settable(lua,   tableIdx);
    
    return 1;
}

extern int luaToNSPoint(lua_State *lua) {
    
    if (!lua_istable(lua, 1)) {
        NSLog(@"Cound not convert to NSRange");
        return 0;
    }
    
    NSPoint p = NSMakePoint(0, 0);
    
    NSDictionary *d = dictionaryFromCurrentTable(lua);
    
    if (!([d objectForKey:@"x"] && [d objectForKey:@"y"])) {
        printf("Cound not find both x and y keys in table\n");
        return 0;
    }
    
    p.x  = [[d objectForKey:@"x"] floatValue];
    p.y  = [[d objectForKey:@"y"] floatValue];
    
    void* result = lua_newuserdata(lua, sizeof(NSPoint));
    memcpy(result, &(p), sizeof(NSPoint));
    
    return 1;
}





extern int nsToLuaRect(lua_State *lua) {
    
    if (!lua_isuserdata(lua, 1)) {
        NSLog(@"Could not convert to id");
        return 0;
    }
    
    NSRect r;
    memcpy( &(r), lua_touserdata(lua, 1), sizeof(NSRect));
    
    lua_newtable(lua);
    int tableIdx = lua_gettop(lua);
    
	lua_pushstring(lua,"x");
	lua_pushnumber(lua, r.origin.x);
	lua_settable(lua,   tableIdx);
    
	lua_pushstring(lua,"y");
	lua_pushnumber(lua, r.origin.y);
	lua_settable(lua,   tableIdx);
    
	lua_pushstring(lua,"width");
	lua_pushnumber(lua, r.size.width);
	lua_settable(lua,   tableIdx);
    
	lua_pushstring(lua,"height");
	lua_pushnumber(lua, r.size.height);
	lua_settable(lua,   tableIdx);
    
    return 1;
}


extern int luaToNSRect(lua_State *lua) {
    
    if (!lua_istable(lua, 1)) {
        NSLog(@"Cound not convert to NSRect");
        return 0;
    }
    
    NSRect r = NSMakeRect(0, 0, 0, 0);
    
    NSDictionary *d = dictionaryFromCurrentTable(lua);
    
    if (!([d objectForKey:@"x"] && [d objectForKey:@"y"] && [d objectForKey:@"width"] && [d objectForKey:@"height"])) {
        printf("Cound not find both x and y keys in table\n");
        return 0;
    }
    
    r.origin.x      = [[d objectForKey:@"x"] floatValue];
    r.origin.y      = [[d objectForKey:@"y"] floatValue];
    r.size.width    = [[d objectForKey:@"width"] floatValue];
    r.size.height   = [[d objectForKey:@"height"] floatValue];
    
    void* result = lua_newuserdata(lua, sizeof(NSRect));
    memcpy(result, &(r), sizeof(NSRect));
    
    return 1;
}

extern int luaNSMakeRect(lua_State *lua) {
    
    float x = lua_tonumber(lua, 1);
    float y = lua_tonumber(lua, 2);
    float w = lua_tonumber(lua, 3);
    float h = lua_tonumber(lua, 4);
    
    NSRect rect = NSMakeRect(x, y, w, h);
    
    void* result = lua_newuserdata(lua, sizeof(NSRect));
    memcpy(result, &(rect), sizeof(NSRect));
    
    return 1;
}



NSString *stringFromArgument(lua_State *lua, int idx) {
    
    if (lua_objc_isid(lua, idx)) {
        
        id o = lua_objc_toid(lua, idx);
        
        if (!o) {
            NSLog(@"Could not convert to string");
            return nil;
        }
        
        return [o description];
    }
    else if (lua_type(lua, idx) == LUA_TSTRING) {
        const char *luaString = luaL_checkstring(lua, idx);
        return [NSString stringWithUTF8String:luaString];
    }
    else if (lua_type(lua, idx) == LUA_TNUMBER) {
        return [[NSNumber numberWithDouble:lua_tonumber(lua, idx)] description];
    }
    
    return nil;
}


extern int nsAlert(lua_State *lua) {
    
    NSString *title = stringFromArgument(lua, 1);
    NSString *msg   = stringFromArgument(lua, 2);
    NSString *one   = stringFromArgument(lua, 3);
    NSString *two   = stringFromArgument(lua, 4);
    NSString *three = stringFromArgument(lua, 5);
    
    title = title ? title : @"Alert!";
    msg   = msg   ? msg   : @"";
    
    int res = NSRunAlertPanel(title, msg, one, two, three);
    
    lua_pushnumber(lua, res);
    
    return 1;
}

extern int nsBeep(lua_State *lua) {
    NSBeep();
    
    return 0;
}

NSDictionary * dictionaryFromCurrentTable(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TTABLE);
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    lua_pushnil(lua);  /* first key */
    while (lua_next(lua, 1) != 0) {
        /* `key' is at index -2 and `value' at index -1 */
        
        int keyType     = lua_type(lua, -2);
        int valueType   = lua_type(lua, -1);
        
        if (keyType != LUA_TSTRING) {
            // we only handle strings for this guy... for um.. some reason.
            printf("Could not convert all types in table to dictionary\n");
            continue;
        }
        
        NSString *key   = [NSString stringWithUTF8String:lua_tostring(lua,  -2)];
        id value        = 0x00;
        
        if (valueType == LUA_TNUMBER) {
            value = [NSNumber numberWithDouble:lua_tonumber(lua, -1)];
        }
        else if (valueType == LUA_TSTRING) {
            value = [NSString stringWithUTF8String:lua_tostring(lua,  -1)];
        }
        else {
            printf("Could not determine type to convert %s to.", [key UTF8String]);
        }
        
        [dict setObject:value forKey:key];
        
        lua_pop(lua, 1);  /* removes `value'; keeps `key' for next iteration */
    }
    
    return dict;
}

NSArray * arrayFromTable(lua_State *lua, int argIdx) {
    
    luaL_checktype(lua, argIdx, LUA_TTABLE);
    
    NSMutableArray *ar = [NSMutableArray array];
    
    int count = lua_objlen(lua, argIdx);
    int i;
    //lua_pushnil(lua); 
    for (i = 1; i <= count; i++) {
        
        lua_rawgeti(lua, argIdx, i);
        
        int valueType   = lua_type(lua, -1);
        
        id value        = 0x00;
        
        if (valueType == LUA_TNUMBER) {
            value = [NSNumber numberWithDouble:lua_tonumber(lua, -1)];
        }
        else if (valueType == LUA_TSTRING) {
            value = [NSString stringWithUTF8String:lua_tostring(lua,  -1)];
        }
        
        if (value) {
            [ar addObject:value];
        }
    }
    
    return ar;
}

NSArray * arrayFromCurrentTable(lua_State *lua) {
    return arrayFromTable(lua, 1);
}



const luaL_reg lua_objc_help_functions[]={
    
	{"NSStringFromLuaString", luaToNSString},
    {"LuaStringFromNSString", nsToLuaString},
    
    {"NSRangeFromLuaTable", luaToNSRange},
    {"LuaTableFromNSRange", nsToLuaRange},
    
    {"NSPointFromLuaTable", luaToNSPoint},
    {"LuaTableFromNSPoint", nsToLuaPoint},
    
    {"NSRectFromLuaTable", luaToNSRect},
    {"LuaTableFromNSRect", nsToLuaRect},
    {"NSMakeRect", luaNSMakeRect},
    
    {"NSAlert", nsAlert},
    {"NSBeep", nsBeep},
    
	{NULL,NULL},
};

void lua_objc_help_init(lua_State* state) {
    luaL_openlib(state, "objc", lua_objc_help_functions, 0);
}


static const char *fml_lmemfind (const char *s1, size_t l1,
                             const char *s2, size_t l2) {
    if (l2 == 0) return s1;  /* empty strings are everywhere */
    else if (l2 > l1) return NULL;  /* avoids a negative `l1' */
    else {
        const char *init;  /* to search for a `*s2' inside `s1' */
        l2--;  /* 1st char will be checked by `memchr' */
        l1 = l1-l2;  /* `s2' cannot be found after that */
        while (l1 > 0 && (init = (const char *)memchr(s1, *s2, l1)) != NULL) {
            init++;   /* 1st char is already checked */
            if (memcmp(init, s2+1, l2) == 0)
                return init-1;
            else {  /* correct `l1' and `s1' to try again */
                l1 -= init-s1;
                s1 = init;
            }
        }
        return NULL;  /* not found */
    }
}



extern int lua_str_replace(lua_State *L);

extern int lua_str_replace(lua_State *L) {
    size_t l1, l2, l3;
    const char *src = luaL_checklstring(L, 1, &l1);
    const char *p = luaL_checklstring(L, 2, &l2);
    const char *p2 = luaL_checklstring(L, 3, &l3);
    const char *s2;
    int n = 0;
    int init = 0;
    
    luaL_Buffer b;
    luaL_buffinit(L, &b);
    
    while (1) {
        s2 = fml_lmemfind(src+init, l1-init, p, l2);
        if (s2) {
            luaL_addlstring(&b, src+init, s2-(src+init));
            luaL_addlstring(&b, p2, l3);
            init = init + (s2-(src+init)) + l2;
            n++;
        } else {
            luaL_addlstring(&b, src+init, l1-init);
            break;
        }
    }
    
    luaL_pushresult(&b);
    lua_pushnumber(L, (lua_Number)n);  /* number of substitutions */
    return 2;
}


#pragma mark String Extras

const luaL_reg lua_objc_extrastring_functions[]={
    
	{"replace", lua_str_replace},
	{NULL,NULL},
};

void lua_extrastring_init(lua_State* state) {
    luaL_openlib(state, "string", lua_objc_extrastring_functions, 0);
}




