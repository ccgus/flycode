#import <Foundation/Foundation.h>
#import <LuaCore/LuaCore.h>

// you'll want to change this
#define TESTDIR @"/Volumes/srv/Users/gus/Projects/flycode/luacore/TestApp"

@interface TestClass : NSObject {
    int i;
}

- (int) setI:(int) j;
- (void) setI2:(int) j;

@end

@implementation TestClass

- (int) setI:(int) j {
	i = j;
	NSLog(@"set I     to %d",i);
	return i;
}

- (void) setI2:(int) j {
	i = j;
	NSLog(@"set I (2) to %d",i);
}

- (int) getI {
    return i;
}

@end

void runTest(NSString *testName) {
    
    NSLog(@"******* running %@", testName);
    
    LCLua *lua = [LCLua readyLua];
    
    [lua runFileAtPath:[TESTDIR stringByAppendingPathComponent:testName]];
    
    [lua tearDown];
    
    NSLog(@"******* done with %@", testName);
}

void makeInterpreterFromScratch(NSString *testName) {
    // this is what you have to do without the wrapper.
    NSLog(@"******* running without wrapper %@", testName);
    
    
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    
    char *buf = "print('hello world')";
    
    if (luaL_loadbuffer(L, buf, strlen(buf), nil) || lua_pcall(L, 0, 0, 0)) {
        printf("err: %s\n", lua_tostring(L, -1));
    }
    
    // put a variable in there
    lua_pushstring(L, "s");
    lua_pushstring(L, "this is the value of s");
    lua_settable(L, LUA_GLOBALSINDEX);
    
    buf = "print(s)";
    if (luaL_loadbuffer(L, buf, strlen(buf), nil) || lua_pcall(L, 0, 0, 0)) {
        printf("err: %s\n", lua_tostring(L, -1));
    }
    
    lua_close(L);
    
    
    NSLog(@"******* done with %@", testName);
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    runTest(@"simpletest.lua");
    runTest(@"cgtest.lua");
    
    makeInterpreterFromScratch(@"simpletest.lua");
    
    runTest(@"classtest.lua");
    
    [pool release];
    return 0;
}


