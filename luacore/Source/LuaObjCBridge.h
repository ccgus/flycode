/*
 *
 * LuaObjCBridge.h
 *
 * By Tom McClean, 2005/2006
 * tom@pixelballistics.com
 *
 * This file is public domain. It is provided without any warranty whatsoever,
 * and may be modified or used without attribution.
 *
 */

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

extern lua_State* lua_objc_init();
extern int lua_objc_open(lua_State* state);

#ifdef __OBJC__
	#import <Foundation/Foundation.h>

//
//
// C-callable functions (public)
//
//

extern id lua_objc_getid(lua_State* state,int stack_index);
extern void lua_objc_pushid(lua_State* state,id object);
extern int lua_objc_isid(lua_State* state,int stack_index);
extern void lua_objc_setid(lua_State* state,int stack_index,id object);
extern id lua_objc_toid(lua_State* state,int stack_index);

extern BOOL lua_objc_pushpropertylist(lua_State* state,id propertylist);
extern id lua_objc_topropertylist(lua_State* state,int stack_index);

extern void lua_objc_id_setvalues(lua_State* state,int stack_index,NSDictionary* dictionary);
extern NSDictionary* lua_objc_id_getvalues(lua_State* state,int stack_index);

extern unsigned lua_objc_type_alignment(char** typeptr);
extern unsigned lua_objc_type_size(char** typeptr);

//
//
// C-callable functions (recommended for internal use only)
//
//

extern void lua_objc_configuremetatable(lua_State* state, int stack_index,int hook_gc_events);
extern void* lua_objc_topointer(lua_State* state,int stack_index);

//
//
// Lua-callable functions (parameters/results on Lua stack)
//
//

extern int lua_objc_lookup_class(lua_State* state);
extern int lua_objc_methodcall(lua_State* state);
extern int lua_objc_methodlookup(lua_State* state);
extern int lua_objc_release(lua_State* state);

#endif