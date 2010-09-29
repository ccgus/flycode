//
//  DictObject.m
//  MYUtilities
//
//  Created by Jens Alfke on 8/6/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "DictObject.h"
#import <objc/runtime.h>


@implementation DictObject

- (id) initWithDictionary: (NSDictionary*)dict {
    Assert(dict);
    self = [super init];
    if (self != nil) {
        _dict = [dict copy];
    }
    return self;
}

- (id) initMutableWithDictionary: (NSDictionary*)dict {
    self = [super init];
    if (self != nil) {
        _dict = dict ?[dict mutableCopy] :$mdict();
        _mutable = YES;
    }
    return self;
}

- (id) init {
    return [self initMutableWithDictionary:nil];
}

- (void) dealloc
{
    [_dict release];
    [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone {
    if (_mutable)
        return [[[self class] allocWithZone: zone] initWithDictionary: _dict];
    else
        return [self retain];
}

- (id) mutableCopyWithZone: (NSZone*)zone {
    return [[[self class] allocWithZone: zone] initMutableWithDictionary: _dict];
}

@synthesize dictionary=_dict, isMutable=_mutable;

- (NSMutableDictionary*) mutableDictionary {
    Assert(_mutable, @"Attempt to access mutable dictionary of immutable instance %@", self);
    return _dict;
}

- (NSString*) description {
    return $sprintf(@"%@%s%@", [self class], (_mutable ?"*" :""), _dict.description);
}

- (BOOL) isEqual: (id)other {
    return [other isKindOfClass: [DictObject class]] && [_dict isEqual: ((DictObject*)other)->_dict];
}

- (NSUInteger) hash {
    return [_dict hash];
}

- (void) makeImmutable {
    _mutable = NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// The rest of this class implementation is adapted from Apple's sample code:
// http://developer.apple.com/samplecode/DynamicProperties


// to speed this code up, should create a map from SEL to NSString mapping selectors to their keys.

// converts a getter selector to an NSString, equivalent to NSStringFromSelector().
NS_INLINE NSString *getterKey(SEL sel) {
    return [NSString stringWithUTF8String:sel_getName(sel)];
}

// converts a setter selector, of the form "set<Key>:" to an NSString of the form @"<key>".
NS_INLINE NSString *setterKey(SEL sel) {
    const char* name = sel_getName(sel) + 3; // skip past 'set'
    int length = strlen(name);
    char buffer[1 + length];
    strcpy(buffer, name);
    buffer[0] = tolower(buffer[0]);
    buffer[length - 1] = '\0';
    return [NSString stringWithUTF8String:buffer];
}

// Generic accessor methods for property types id, double, and NSRect.

static void setIdProperty(DictObject *self, SEL name, id value) {
    CAssert(self->_mutable, @"Attempt to call %s on an immutable %@", sel_getName(name),[self class]);
    NSString *key = setterKey(name);
    if (value )
        [self->_dict setObject:value forKey: key];
    else
        [self->_dict removeObjectForKey: key];
}

static id getIdProperty(DictObject *self, SEL name) {
    return [self->_dict objectForKey:getterKey(name)];
}

static void setIntProperty(DictObject *self, SEL name, int value) {
    CAssert(self->_mutable, @"Attempt to call %s on an immutable %@", sel_getName(name),[self class]);
    [self->_dict setObject:[NSNumber numberWithInt:value] forKey:setterKey(name)];
}

static int getIntProperty(DictObject *self, SEL name) {
    return [[self->_dict objectForKey:getterKey(name)] intValue];
}

static void setDoubleProperty(DictObject *self, SEL name, double value) {
    CAssert(self->_mutable, @"Attempt to call %s on an immutable %@", sel_getName(name),[self class]);
    [self->_dict setObject:[NSNumber numberWithDouble:value] forKey:setterKey(name)];
}

static double getDoubleProperty(DictObject *self, SEL name) {
    id number = [self->_dict objectForKey:getterKey(name)];
    return number ?[number doubleValue] :0.0;
}


static const char* getPropertyType(objc_property_t property, BOOL *outIsSettable) {
    *outIsSettable = YES;
    const char *result = "@";
    
    // Copy property attributes into a writeable buffer:
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    
    // Scan the comma-delimited sections of the string:
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        switch (attribute[0]) {
            case 'T':       // Property type in @encode format
                result = (const char *)[[NSData dataWithBytes: (attribute + 1) 
                                                       length: strlen(attribute)] bytes];
                break;
            case 'R':       // Read-only indicator
                *outIsSettable = NO;
                break;
        }
    }
    return result;
}

static BOOL getPropertyInfo(Class cls, 
                            NSString *propertyName, 
                            BOOL setter,
                            Class *propertyClass,
                            const char* *propertyType) {
    const char *name = [propertyName UTF8String];
    while (cls != NULL && cls != [DictObject class]) {
        objc_property_t property = class_getProperty(cls, name);
        if (property) {
            *propertyClass = cls;
            BOOL isSettable;
            *propertyType = getPropertyType(property, &isSettable);
            if (setter && !isSettable)
                return NO;
            return YES;
        }
        cls = class_getSuperclass(cls);
    }
    return NO;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    const char *name = sel_getName(sel);
    Class propertyClass;
    const char *propertyType;
    IMP accessor = NULL;
    const char *signature = NULL;
    
    // TODO:  handle more property types. This code handles id, int, and double.
    if (strncmp("set", name, 3) == 0) {
        // choose an appropriately typed generic setter function.
        if (getPropertyInfo(self, setterKey(sel), YES, &propertyClass, &propertyType)) {
            switch (propertyType[0]) {
                case _C_ID:
                    accessor = (IMP)setIdProperty;
                    signature = "v@:@"; 
                    break;
                case _C_INT:
                    accessor = (IMP)setIntProperty;
                    signature = "v@:i"; 
                    break;
                case _C_DBL:
                    accessor = (IMP)setDoubleProperty;
                    signature = "v@:d"; 
                    break;
                default:
                    Warn(@"Unsupported value type '%s' for setter %s of DictObject subclass %@", 
                         propertyType,name,self);
                    break;
            }
        }
    } else {
        // choose an appropriately typed getter function.
        if (getPropertyInfo(self, getterKey(sel), NO, &propertyClass, &propertyType)) {
            switch (propertyType[0]) {
                case _C_ID:
                    accessor = (IMP)getIdProperty;
                    signature = "@@:"; 
                    break;
                case _C_INT:
                    accessor = (IMP)getIntProperty;
                    signature = "i@:"; 
                    break;
                case _C_DBL:
                    accessor = (IMP)getDoubleProperty;
                    signature = "d@:"; 
                    break;
                default:
                    Warn(@"Unsupported value type '%s' for getter %s of DictObject subclass %@", 
                         propertyType, name,self);
                    break;
            }
        }
    }
    if (accessor && signature) {
        Log(@"Creating dynamic accessor method -[%@ %s]", self, name);
        class_addMethod(propertyClass, sel, accessor, signature);
        return YES;
    }
    return NO;
}

///////////////////////////////////////////////////////////////////////////////////////////////////


@end




#if DEBUG

@interface TestDictObject : DictObject
@property (readwrite,copy) NSString *stringy;
@property (readonly) int intey;
@property (readwrite) double doubley;
@end

@implementation TestDictObject
@dynamic stringy, intey, doubley;
@end


TestCase(DictObject) {
    TestDictObject *test = [[TestDictObject alloc] initWithDictionary: $dict()];
    Log(@"Testing empty object: %@", test);
    CAssertEqual(test.dictionary, $dict());
    CAssertEqual(test.stringy, nil);
    CAssertEq(test.intey, 0);
    CAssertEq(test.doubley, 0.0);
    [test release];
    
    NSDictionary *dict = $dict( {@"stringy", @"String value"},
                                {@"intey", $object(-6789)} );
    test = [[TestDictObject alloc] initMutableWithDictionary: dict];
    Log(@"Testing immutable object: %@", test);
    CAssertEqual(test.dictionary, dict);
    Log(@"test.stringy = %@", test.stringy);
    CAssertEqual(test.stringy, @"String value");
    Log(@"test.intey = %i", test.intey);
    CAssertEq(test.intey, -6789);
    Log(@"test.doubley = %g", test.doubley);
    CAssertEq(test.doubley, 0.0);
    
    test.stringy = nil;
    CAssertEqual(test.stringy, nil);
    test.doubley = 123.456;
    CAssertEq(test.doubley, 123.456);
    
    CAssert(![test respondsToSelector: @selector(setIntey:)]);
    CAssert(![test respondsToSelector: @selector(size)]);
    
    [test makeImmutable];
    @try{
        test.doubley = 1.0;
        CAssert(NO, @"setting doubley should have failed");
    }@catch( NSException *x ) {
    }
}

#endif DEBUG
