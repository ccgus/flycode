//
//  DictObject.h
//  MYUtilities
//
//  Created by Jens Alfke on 8/6/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/** A generic object whose properties are stored in an NSDictionary.
    You can subclass this and declare properties in the subclass without needing to implement them
    or make instance variables; simply note them as '@dynamic' in the @implementation.
    The property values will automatically be stored in the object's dictionary. */
@interface DictObject : NSObject <NSCopying, NSMutableCopying>
{
  @private
    NSMutableDictionary *_dict;
    BOOL _mutable;
}

/** Creates an immutable instance with the given property values. */
- (id) initWithDictionary: (NSDictionary*)dict;

/** Creates a mutable instance with the given property values (none, if dict is nil.) */
- (id) initMutableWithDictionary: (NSDictionary*)dict;

/** The object's property dictionary. */
@property (readonly) NSDictionary* dictionary;

/** The object's property dictionary in mutable form.
    Calling this will raise an exception if the object is immutable. */
@property (readonly) NSMutableDictionary* mutableDictionary;

@property (readonly) BOOL isMutable;

/** Makes the object immutable from now on. 
    Any further attempt to set a property value will result in a runtime exception. */
- (void) makeImmutable;

@end
