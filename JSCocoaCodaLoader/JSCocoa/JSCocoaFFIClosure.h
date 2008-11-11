//
//  JSCocoaFFIClosure.h
//  JSCocoa
//
//  Created by Patrick Geiller on 29/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JavascriptCore/JavascriptCore.h>
#import "JSCocoaFFIArgument.h"
#define MACOSX
#import <ffi/ffi.h>


@interface JSCocoaFFIClosure : NSObject {

	JSValueRef		jsFunction;
	JSContextRef	ctx;

	ffi_cif			cif;
	ffi_closure		closure;
	ffi_type**		argTypes;
	
	NSMutableArray*	encodings;
	
	JSObjectRef		jsThisObject;
	
	BOOL			isObjC;
}

- (void)setJSFunction:(JSValueRef)fn inContext:(JSContextRef)ctx argumentEncodings:(NSMutableArray*)argumentEncodings objC:(BOOL)objC;
- (void*)functionPointer;
- (void)calledByClosureWithArgs:(void**)args returnValue:(void*)returnValue;

@end
