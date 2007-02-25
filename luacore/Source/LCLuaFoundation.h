
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>


extern int luaToNSString (lua_State *lua);
extern int nsToLuaString (lua_State *lua);

extern int luaToNSRange(lua_State *lua);
extern int nsToLuaRange(lua_State *lua);

extern int luaToNSPoint(lua_State *lua);
extern int nsToLuaPoint(lua_State *lua);

extern int luaToNSRect(lua_State *lua);
extern int nsToLuaRect(lua_State *lua);

extern int luaNSMakeRect(lua_State *lua);
extern int nsBeep(lua_State *lua);

extern int nsAlert(lua_State *lua);

NSString *stringFromArgument(lua_State *lua, int idx);

NSDictionary * dictionaryFromCurrentTable(lua_State *lua);
NSArray * arrayFromCurrentTable(lua_State *lua);
NSArray * arrayFromTable(lua_State *lua, int argIdx) ;

void lerror (lua_State *L, const char *fmt, ...);

void lua_objc_help_init(lua_State* state);
void lua_extrastring_init(lua_State* state);

