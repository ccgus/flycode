#import "LCLua.h"
#import "LuaObjCBridge.h"
#import "LCLuaFoundation.h"
#import "LCCoreGraphics.h"
#include "lposix.h"

NSString *LCRunningInLuaKey = @"LCRunningInLua";

@implementation LCLua

+ (id) readyLua {
    
    LCLua *lua = [[[self alloc] init] autorelease];
    
    [lua setup];
    
    return lua;
}

- (void)dealloc {
    [self tearDown];
	[super dealloc];
}

- (lua_State*) state {
    return L;
}

- (void) setup {
    L = (lua_State*)lua_objc_init();
    
    lua_objc_help_init(L);
    lua_extrastring_init(L);
    luaopen_posix(L);
    lua_coregraphics_init(L);
    
    // I suppose it would be cleaner to do this in c...
    [self runBuffer:@"function objc.enumToIterator(anEnum) return function() return anEnum:nextObject() end end"];
}

- (void) tearDown {
    if (L) {
        lua_close(L);
        L = 0x00;
    }
}

- (void) error:(const char *)fmt, ... {
    va_list argp;
    va_start(argp, fmt);
    vfprintf(stderr, fmt, argp);
    NSString *errString = [[NSString alloc] initWithFormat: [NSString stringWithUTF8String:fmt] arguments: argp];
    va_end(argp);
    
    NSLog(@"%@", errString);
	[errString release];
}

- (void) runBuffer:(NSString*)buf {
    
    // oh geeze, don't tell anyone i'm using threadDictionary!
    [[[NSThread currentThread] threadDictionary] setObject:[NSNumber numberWithBool:YES] forKey:LCRunningInLuaKey];
    
    if (luaL_loadbuffer(L, [buf UTF8String], [buf length], nil) || lua_pcall(L, 0, 0, 0)) {
        [self error:"Error: %s\n", lua_tostring(L, -1)];
    }
    
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:LCRunningInLuaKey];
}
- (void) runFileAtPath:(NSString*)filePath {
    
    [[[NSThread currentThread] threadDictionary] setObject:[NSNumber numberWithBool:YES] forKey:LCRunningInLuaKey];
    
    [self pushAsLuaString:filePath withName:@"LCLuaRunFile"];
    [self pushAsLuaString:[filePath stringByDeletingLastPathComponent] withName:@"LCLuaRunFileDirectory"];
    
    if (luaL_loadfile(L, [filePath fileSystemRepresentation]) || lua_pcall(L, 0, 0, 0)) {
        [self error:"Error: %s\n", lua_tostring(L, -1)];
    }
    
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:LCRunningInLuaKey];
}

- (BOOL) int:(int*)val named:(NSString*)name {
    
    lua_getglobal(L, [name UTF8String]);
    
    if (!lua_isnumber(L, -1)) {
        [self error:"%s should be a number\n", [name UTF8String]];
        return NO;
    }
    
    *val = (int)lua_tonumber(L, -1);
    
    return YES;
}

- (BOOL) bool:(BOOL*)val named:(NSString*)name {
    
    lua_getglobal(L, [name UTF8String]);
    
    if (!(lua_type(L, -1) == LUA_TBOOLEAN)) {
        [self error:"%s should be a boolean\n", [name UTF8String]];
        return NO;
    }
    
    *val = lua_toboolean(L, -1);
    
    return YES;
}

- (BOOL) float:(float*)val named:(NSString*)name {
    
    lua_getglobal(L, [name UTF8String]);
    
    if (!lua_isnumber(L, -1)) {
        [self error: "%s should be a float\n", [name UTF8String]];
        return NO;
    }
    
    *val = (float)lua_tonumber(L, -1);
    
    return YES;
}

- (BOOL) double:(double*)val named:(NSString*)name {
    
    lua_getglobal(L, [name UTF8String]);
    
    if (!lua_isnumber(L, -1)) {
        [self error:"%s should be a number\n", [name UTF8String]];
        return NO;
    }
    
    *val = lua_tonumber(L, -1);
    
    return YES;
}

- (NSNumber*) numberNamed:(NSString*)name {
    
    double val = 0;
    
    if (![self double:&val named:name]) {
        return nil;
    }
    
    return [NSNumber numberWithDouble:val];
    
}

- (NSString*) stringNamed:(NSString*)name {
    
    NSString *val = nil;
    
    lua_getglobal(L, [name UTF8String]);
    
    if (!lua_isstring(L, -1)) {
        [self error: "%s should be a string\n", [name UTF8String]];
        return val;
    }
    
    return [NSString stringWithUTF8String:lua_tostring(L, -1)];
}

- (id) objectNamed:(NSString*)name {
    
    lua_getglobal(L, [name UTF8String]);
    
    id ret = lua_objc_topropertylist(L, -1);
    
    if (ret == [NSNull null]) {
        return nil;
    }
    
    return ret;
    
}

- (void) pushGlobalObject:(id)object withName:(NSString*)name {
    lua_pushstring(L, [name UTF8String]);
    lua_objc_pushid(L, object);
    lua_settable(L, LUA_GLOBALSINDEX);
}

- (void) pushAsLuaString:(NSString*)s withName:(NSString*)name {
    lua_pushstring(L, [name UTF8String]);
    lua_pushstring(L, [s UTF8String]);
    lua_settable(L, LUA_GLOBALSINDEX);
}

- (void) pushShallowDictionary:(NSDictionary*)d {
    
    lua_newtable(L);
    int table = lua_gettop(L);
    NSEnumerator* enumerator = [d keyEnumerator];
    id key;
    while((key = [enumerator nextObject])) {
        lua_objc_pushpropertylist(L, key);
        if (!lua_objc_pushpropertylist(L, [d objectForKey:key])) {
            lua_objc_pushid(L, [d objectForKey:key]);
        }
        lua_rawset(L,table);
    }
    
}

- (void) pushDictionaryAsTable:(NSDictionary*)d withName:(NSString*)name {
    lua_pushstring(L, [name UTF8String]);
    [self pushShallowDictionary:d];
    lua_settable(L, LUA_GLOBALSINDEX);
}

- (void) callEmptyFunctionNamed:(NSString*)functionName {
    
    // Push the function name onto the stack
    lua_pushstring (L, [functionName UTF8String]);
    
    // Function is located in the Global Table
    lua_gettable (L, LUA_GLOBALSINDEX);  
    
    lua_pcall (L, 0, 0, 0);
}


- (void) callFunction:(NSString*)functionName withArg:(id)arg {
    
    int functionCount = 0;
    
    [[[NSThread currentThread] threadDictionary] setObject:[NSNumber numberWithBool:YES] forKey:LCRunningInLuaKey];
    
    lua_getglobal(L, [functionName UTF8String]);
    
    if (arg) {
        lua_objc_pushid(L, arg);
        functionCount = 1;
    }
    
    if (lua_pcall(L, functionCount, 0, 0) != 0) {
        NSLog(@"Error running function '%@': %s", functionName, lua_tostring(L, -1));
    }
    
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:LCRunningInLuaKey];
}

+ (NSString*) runScriptInBundle:(NSString*)scriptName withInput:(NSString*)input named:(NSString*)inputNamed recievingOuputNamed:(NSString*)outName {
    
    NSString *scriptPath = nil;
    
    // first, check and see if this path is around- we'll use the scripts in this folder so we don't 
    // have to rebuild our app again just to copy in a changed lua script.  This way, we can modify 
    // the script in our editor and not have to relaunch the app.
    
    // defaults write com.MacWarriors.Kiwi devScriptFolder /Volumes/srv/Users/gus/Projects/kiwi/Source/Lua
    NSString *devPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"devScriptFolder"];
    if (devPath) {
        scriptPath = [NSBundle pathForResource:scriptName ofType:@"lua" inDirectory:devPath];
    }
    
    // now check in our resources script folder.
    if (!scriptPath) {
        scriptPath = [[NSBundle mainBundle] pathForResource:scriptName ofType:@"lua"];
    }
    
    
    if (!scriptPath) {
        NSLog(@"Could not find script '%@'", scriptName);
        return nil;
    }
    
    LCLua *lua = [LCLua readyLua];
    [lua pushAsLuaString:input withName:inputNamed];
    [lua runFileAtPath:scriptPath];
    
    NSString *s = [lua stringNamed:outName];
    
    [lua tearDown];
    
    return s;
}

@end
