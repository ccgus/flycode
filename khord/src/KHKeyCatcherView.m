//
//  KHKeyCatcherView.m
//  khord
//
//  Created by August Mueller on 8/3/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import "KHKeyCatcherView.h"


@implementation KHKeyCatcherView
@synthesize keysPressed=_keysPressed;

- (void)awakeFromNib {
	self.keysPressed = [NSMutableDictionary dictionary];
}



- (NSMutableString*) keysForDictionary:(NSDictionary*)dictKeys {
    NSMutableString *prefix = [NSMutableString string];
    
    for (NSString *c in [dictKeys keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)]) {
        [prefix appendString:c];
    }
    
    return prefix;
}

- (NSString*) applescriptPathForKeys:(NSDictionary*)dictKeys {
    
    NSMutableString *prefix = [self keysForDictionary:dictKeys];;
    
    [prefix appendString:@"-"];
    
    for (NSString *path in [[NSFileManager defaultManager] directoryContentsAtPath:[@"~/Library/Scripts/" stringByExpandingTildeInPath]]) {
        
        if ([path hasPrefix:prefix]) {
            
            return [[@"~/Library/Scripts" stringByAppendingPathComponent:path] stringByExpandingTildeInPath];
        }
    }
    
    return nil;
}

- (void) clear {
    [[[theTextView textStorage] mutableString] setString:@" "];
    [_keysPressed removeAllObjects];
}

- (void) keyDown:(NSEvent*)theEvent {
    
    NSString *key = [theEvent charactersIgnoringModifiers];
    
    [_keysPressed setObject:key forKey:key];
    
    [[[theTextView textStorage] mutableString] setString:[self keysForDictionary:_keysPressed]];
}

- (void)keyUp:(NSEvent *)theEvent {
    
    [[self window] orderOut:self];
    
    NSString *asPath = [self applescriptPathForKeys:_keysPressed];
    
    if (!asPath) {
        return;
    }
    
    NSDictionary *err = 0x00;
    
    NSAppleScript *as = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:asPath] error:&err];
    
    if (err) {
        NSLog(@"error opening applescript: %@", err);
        return;
    }
    
    [as executeAndReturnError:&err];
    if (err) {
        NSLog(@"error executing applescript: %@", err);
        return;
    }
}

@end
