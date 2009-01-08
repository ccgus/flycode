//
//  JSCocoa.h
//  JSCocoa
//
//  Created by Patrick Geiller on 09/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define MACOSX
#import <ffi/ffi.h>
#import <JavascriptCore/JavascriptCore.h>
#import "BridgeSupportController.h"
#import "JSCocoaPrivateObject.h"
#import "JSCocoaFFIArgument.h"
#import "JSCocoaFFIClosure.h"


// JS value container, used by methods wanting a straight JSValue and not a converted JS->ObjC value.
struct	JSValueRefAndContextRef
{
	JSValueRef		value;
	JSContextRef	ctx;
};


typedef struct	JSValueRefAndContextRef JSValueRefAndContextRef;

@interface JSCocoaController : NSObject {

	JSGlobalContextRef	ctx;

	id	closureHash;
	// Given a jsFunction, retrieve its selector
	id	jsFunctionSelectors;
	// Given a jsFunction, retrieve which class it's attached to
	id	jsFunctionClasses;
	
	// Given a class + methodName, retrieve its jsFunction
	id	jsFunctionHash;
	
	// Instance stats
	id	instanceStats;
	
	// Used to convert callbackObject (zero call)
	JSObjectRef	callbackObjectValueOfCallback;
	
	BOOL	useAutoCall;
	BOOL	isSpeaking;
}

@property BOOL useAutoCall;
@property BOOL isSpeaking;

+ (id)sharedController;
+ (void)garbageCollect;
//+ (void)garbageCollectNow;

+ (void)upJSCocoaPrivateObjectCount;
+ (void)downJSCocoaPrivateObjectCount;
+ (int)JSCocoaPrivateObjectCount;

+ (void)upJSValueProtectCount;
+ (void)downJSValueProtectCount;
+ (int)JSValueProtectCount;

+ (void)logInstanceStats;

+ (JSObjectRef)jsCocoaPrivateObjectInContext:(JSContextRef)ctx;
+ (NSMutableArray*)parseObjCMethodEncoding:(const char*)typeEncoding;
+ (NSMutableArray*)parseCFunctionEncoding:(NSString*)xml functionName:(NSString**)functionNamePlaceHolder;

- (JSGlobalContextRef)ctx;
- (id)instanceStats;
- (JSObjectRef)callbackObjectValueOfCallback;
- (void)ensureJSValueIsObjectAfterInstanceAutocall:(JSValueRef)value;
- (NSString*)formatJSException:(JSValueRef)exception;
- (BOOL)evalJSFile:(NSString*)path;
- (JSValueRefAndContextRef)evalJSString:(NSString*)script;
- (BOOL)isMaybeSplitCall:(NSString*)start forClass:(id)class;


- (BOOL)loadFrameworkWithName:(NSString*)name;
- (BOOL)loadFrameworkWithName:(NSString*)frameworkName inPath:(NSString*)path;


- (id)selectorForJSFunction:(JSObjectRef)function;

- (BOOL)overloadInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext;
- (BOOL)overloadClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext;

- (BOOL)addClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding;
- (BOOL)addInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding;



@end


id	NSStringFromJSValue(JSValueRef value, JSContextRef ctx);

void* malloc_autorelease(size_t size);


//
// From PyObjC : when to call objc_msgSendStret, for structure return
//		Depending on structure size & architecture, structures are returned as function first argument (done transparently by ffi) or via registers
//

#if defined(__ppc__)
#   define SMALL_STRUCT_LIMIT	4
#elif defined(__ppc64__)
#   define SMALL_STRUCT_LIMIT	8
#elif defined(__i386__) 
#   define SMALL_STRUCT_LIMIT 	8
#elif defined(__x86_64__) 
#   define SMALL_STRUCT_LIMIT	16
#else
#   error "Unsupported MACOSX platform"
#endif

