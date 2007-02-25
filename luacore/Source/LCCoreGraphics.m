#import "LCCoreGraphics.h"
#import <QuartzCore/QuartzCore.h>
#import "LuaObjCBridge.h"
#import "LCLuaFoundation.h"

#include "unistd.h"


#define BEST_BYTE_ALIGNMENT 16
#define COMPUTE_BEST_BYTES_PER_ROW(bpr)		( ( (bpr) + (BEST_BYTE_ALIGNMENT-1) ) & ~(BEST_BYTE_ALIGNMENT-1) )

extern int lua_CGBitmapContextCreateImage(lua_State *L);
extern int lua_CGBitmapContextCreateImage(lua_State *L) {
    
    CGContextRef context = (CGContextRef)lua_objc_toid(L, 1);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    if (imageRef) {
        lua_objc_pushid(L, (id)imageRef);
        return 1;
    }
    
    NSLog(@"Could not make CGImageRef");
    
    return 0;
}

extern int lua_CGColorSpaceCreateDeviceRGB(lua_State *L);
extern int lua_CGColorSpaceCreateDeviceRGB(lua_State *L) {
    
    lua_objc_pushid(L, (id)CGColorSpaceCreateDeviceRGB());
    
    return 1;
}

extern int lua_CGColorSpaceRelease(lua_State *L);
extern int lua_CGColorSpaceRelease(lua_State *L) {
    
    CGColorSpaceRelease((CGColorSpaceRef)lua_objc_toid(L, 1));
    
    return 0;
}
extern int lua_CGBitmapContextCreate(lua_State *L);
extern int lua_CGBitmapContextCreate(lua_State *L) {
    
    float width  = lua_tonumber(L, 1);
    float height = lua_tonumber(L, 2);
    
    CGContextRef context;
    size_t bytesPerRow = width*4;
    
    bytesPerRow = COMPUTE_BEST_BYTES_PER_ROW(bytesPerRow);
    
    unsigned char *rasterData = calloc(1, bytesPerRow * height);
    if (!rasterData) {
        fprintf(stderr, "Couldn't allocate the needed amount of memory!\n");
        return 0;
    }
    
    
    context = CGBitmapContextCreate(rasterData, width, height, 8, bytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst);
    
    if(context == NULL){
		// If the context couldn't be created, release the raster memory.
		free(rasterData);
		fprintf(stderr, "Couldn't create the context!\n");
		return 0;
    }
    
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    lua_objc_pushid(L, (id)context);
    
    return 1;
}

extern int lua_CGBitmapContextRelease(lua_State *L);
extern int lua_CGBitmapContextRelease(lua_State *L) {
    
    CGContextRef context = (CGContextRef)lua_objc_toid(L, 1);
    
    unsigned char *base = CGBitmapContextGetData(context);
    
    CGContextRelease(context);
    free(base);
    
    return 0;
}

extern int lua_CFRelease(lua_State *L);
extern int lua_CFRelease(lua_State *L) {
    CFRelease((CFTypeRef)lua_objc_toid(L, 1));
    return 0;
}

extern int lua_CGImageRelease(lua_State *L);
extern int lua_CGImageRelease(lua_State *L) {
    CGImageRelease((CGImageRef)lua_objc_toid(L, 1));
    return 0;
}

extern int lua_CGImageSourceCreateWithData(lua_State *L);
extern int lua_CGImageSourceCreateWithData(lua_State *L) {
    
    CFDataRef data                  = (CFDataRef)lua_objc_toid(L, 1);
    CFDictionaryRef dict            = (CFDictionaryRef)lua_objc_toid(L, 2);
    
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData(data, dict);
    
    if (!imageSourceRef) {
        return 0;
    }
    
    lua_objc_pushid(L, (id)imageSourceRef);
    
    return 1;
}

extern int lua_CGImageSourceCreateImageAtIndex(lua_State *L);
extern int lua_CGImageSourceCreateImageAtIndex(lua_State *L) {
    
    CGImageSourceRef imageSourceRef = (CGImageSourceRef)lua_objc_toid(L, 1);
    size_t index                    = lua_tonumber(L, 2);
    CFDictionaryRef opts            = (CFDictionaryRef)lua_objc_toid(L, 3);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, index, opts);
    
    lua_objc_pushid(L, (id)imageRef);
    
    return 1;
}

extern int lua_CGContextDrawImage(lua_State *L);
extern int lua_CGContextDrawImage(lua_State *L) {
    
    CGContextRef context    = (CGContextRef)lua_objc_toid(L, 1);
    NSArray *ar             = arrayFromTable(L, 2);
    CGImageRef image        = (CGImageRef)lua_objc_toid(L, 3);
    
    CGRect rect = CGRectMake([[ar objectAtIndex:0] floatValue],
                             [[ar objectAtIndex:1] floatValue],
                             [[ar objectAtIndex:2] floatValue],
                             [[ar objectAtIndex:3] floatValue]);
    
    CGContextDrawImage(context, rect, image);
    
    return 0;
}

extern int lua_CGImageDestinationCreateWithData(lua_State *L);
extern int lua_CGImageDestinationCreateWithData(lua_State *L) {
    
    CFMutableDataRef data   = (CFMutableDataRef)lua_objc_toid(L, 1);
    CFStringRef utiType     = (CFStringRef)[NSString stringWithUTF8String:lua_tostring(L,  2)];
    size_t count            = lua_tonumber(L, 3);
    CFDictionaryRef options = (CFDictionaryRef)lua_objc_toid(L, 2);
    
    CGImageDestinationRef destRef = CGImageDestinationCreateWithData(data, utiType, count, options);
    
    if (!destRef) {
        return 0;
    }
    
    lua_objc_pushid(L, (id)destRef);
    
    return 1;
}

extern int lua_CGImageDestinationAddImage(lua_State *L);
extern int lua_CGImageDestinationAddImage(lua_State *L) {
        
    CGImageDestinationRef idst  = (CGImageDestinationRef)lua_objc_toid(L, 1);
    CGImageRef image            = (CGImageRef)lua_objc_toid(L,2);
    CFDictionaryRef properties  = (CFDictionaryRef)lua_objc_toid(L,3);
    
    CGImageDestinationAddImage(idst, image, properties);
    
    return 0;
}
extern int lua_CGImageDestinationFinalize(lua_State *L);
extern int lua_CGImageDestinationFinalize(lua_State *L) {
    
    CGImageDestinationFinalize((CGImageDestinationRef)lua_objc_toid(L, 1));
    
    return 0;
}

extern int lua_CGImageGetWidth(lua_State *L);
extern int lua_CGImageGetWidth(lua_State *L) {
    
    lua_pushnumber(L, CGImageGetWidth((CGImageRef)lua_objc_toid(L, 1)));    
    
    return 1;
}

extern int lua_CGImageGetHeight(lua_State *L);
extern int lua_CGImageGetHeight(lua_State *L) {
    
    lua_pushnumber(L, CGImageGetHeight((CGImageRef)lua_objc_toid(L, 1)));    

    return 1;
}

extern int lua_CGContextSaveGState(lua_State *L);
extern int lua_CGContextSaveGState(lua_State *L) {
    
    CGContextSaveGState((CGContextRef)lua_objc_toid(L, 1));
    
    return 0;
}

extern int lua_CGContextRestoreGState(lua_State *L);
extern int lua_CGContextRestoreGState(lua_State *L) {
    
    CGContextRestoreGState((CGContextRef)lua_objc_toid(L, 1));
    
    return 0;
}
extern int lua_CGContextTranslateCTM(lua_State *L);
extern int lua_CGContextTranslateCTM(lua_State *L) {
    
    CGContextRef context    = (CGContextRef)lua_objc_toid(L, 1);
    float tx                = lua_tonumber(L, 2);
    float ty                = lua_tonumber(L, 3);
    
    CGContextTranslateCTM(context, tx, ty);
    
    return 0;
}

extern int lua_CGContextScaleCTM(lua_State *L);
extern int lua_CGContextScaleCTM(lua_State *L) {
    
    CGContextRef context    = (CGContextRef)lua_objc_toid(L, 1);
    float sx                = lua_tonumber(L, 2);
    float sy                = lua_tonumber(L, 3);
    
    CGContextScaleCTM(context, sx, sy);
    
    return 0;
}

extern int lua_CGContextRotateCTM(lua_State *L);
extern int lua_CGContextRotateCTM(lua_State *L) {
    // not tested
    CGContextRef context    = (CGContextRef)lua_objc_toid(L, 1);
    float angle             = lua_tonumber(L, 2);
    
    CGContextRotateCTM(context, angle);
    
    return 0;
}

extern int lua_CGContextSetLineWidth(lua_State *L);
extern int lua_CGContextSetLineWidth(lua_State *L) {
    // not tested
    CGContextRef context    = (CGContextRef)lua_objc_toid(L, 1);
    float width             = lua_tonumber(L, 2);
    
    CGContextSetLineWidth(context, width);
    
    return 0;
}

extern int lua_CGContextSetLineCap(lua_State *L);
extern int lua_CGContextSetLineCap(lua_State *L) {
    // not tested
    CGContextRef context    = (CGContextRef)lua_objc_toid(L, 1);
    int cap                 = lua_tonumber(L, 2);
    
    CGContextSetLineCap(context, cap);
    
    return 0;
}

extern int lua_CGContextSetAlpha(lua_State *L);
extern int lua_CGContextSetAlpha(lua_State *L) {
    // not tested
    CGContextRef context    = (CGContextRef)lua_objc_toid(L, 1);
    float alpha             = lua_tonumber(L, 2);
    
    CGContextSetAlpha(context, alpha);
    
    return 0;
}




const luaL_reg lua_cg_functions[] = {
    
	
	{"CGColorSpaceCreateDeviceRGB", lua_CGColorSpaceCreateDeviceRGB},
	{"CGColorSpaceRelease", lua_CGColorSpaceRelease},
    
    {"CGBitmapContextCreateImage", lua_CGBitmapContextCreateImage},
	{"CGBitmapContextCreate", lua_CGBitmapContextCreate},
    {"CGBitmapContextRelease", lua_CGBitmapContextRelease},
    
	{"CGImageSourceCreateWithData", lua_CGImageSourceCreateWithData},
	{"CGImageSourceCreateImageAtIndex", lua_CGImageSourceCreateImageAtIndex},
	{"CGImageRelease", lua_CGImageRelease},
	{"CGImageGetWidth", lua_CGImageGetWidth},
	{"CGImageGetHeight", lua_CGImageGetHeight},
    
	{"CGImageDestinationCreateWithData", lua_CGImageDestinationCreateWithData},
	{"CGImageDestinationAddImage", lua_CGImageDestinationAddImage},
	{"CGImageDestinationFinalize", lua_CGImageDestinationFinalize},
    
	{"CFRelease", lua_CFRelease},
    
	{"CGContextDrawImage", lua_CGContextDrawImage},
	{"CGContextSaveGState", lua_CGContextSaveGState},
	{"CGContextRestoreGState", lua_CGContextRestoreGState},
	{"CGContextTranslateCTM", lua_CGContextTranslateCTM},
	{"CGContextScaleCTM", lua_CGContextScaleCTM},
	{"CGContextRotateCTM", lua_CGContextRotateCTM},
	{"CGContextSetLineWidth", lua_CGContextSetLineWidth},
	{"CGContextSetLineCap", lua_CGContextSetLineCap},
	{"CGContextSetAlpha", lua_CGContextSetAlpha},
    
	{NULL,NULL},
};

void lua_coregraphics_init(lua_State* state) {
    luaL_openlib(state, "_G", lua_cg_functions, 0);
}




