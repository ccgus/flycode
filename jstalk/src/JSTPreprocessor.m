//
//  JSTPreprocessor.m
//  jstalk
//
//  Created by August Mueller on 2/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTPreprocessor.h"
#import "TDTokenizer.h"
#import "TDToken.h"
#import "TDWhitespaceState.h"
#import "TDCommentState.h"

@implementation JSTPreprocessor

+ (NSString*) preprocessForObjCStrings:(NSString*)sourceString {
    
    NSMutableString *buffer = [NSMutableString string];
    TDTokenizer *tokenizer  = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    tokenizer.commentState.reportsCommentTokens = YES;
    
    TDToken *eof                    = [TDToken EOFToken];
    TDToken *tok                    = 0x00;
    TDToken *nextToken              = 0x00;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        if (tok.isSymbol && [[tok stringValue] isEqualToString:@"@"]) {
            
            // woo, it's special objc stuff.
            
            nextToken = [tokenizer nextToken];
            if (nextToken.quotedString) {
                [buffer appendFormat:@"[NSString stringWithString:%@]", [nextToken stringValue]];
            }
            else {
                [buffer appendString:[tok stringValue]];
                [buffer appendString:[nextToken stringValue]];
            }
        }
        else {
            [buffer appendString:[tok stringValue]];
        }
    }
    
    return buffer;
}

+ (NSString*) preprocessForObjCMessagesToJS:(NSString*)sourceString {
    
    NSMutableString *buffer = [NSMutableString string];
    TDTokenizer *tokenizer  = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    tokenizer.commentState.reportsCommentTokens = YES;
    
    TDToken *eof                    = [TDToken EOFToken];
    TDToken *tok                    = nil;
    TDToken *lastToken              = nil;
    BOOL lastWasWord                = NO;
    NSUInteger bracketCount         = 0;
    JSTPObjcCall *currentObjcCall   = 0x00;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        NSLog(@"[tok stringValue]: %@", [tok stringValue]);
        
        if (tok.isSymbol && !lastWasWord && [tok.stringValue isEqualToString:@"["]) {
            
            tokenizer.whitespaceState.reportsWhitespaceTokens = NO;
            
            if (!bracketCount) {
                currentObjcCall = [[[JSTPObjcCall alloc] init] autorelease];
            }
            else {
                currentObjcCall = [currentObjcCall push];
            }
            
            bracketCount++;
        }
        else if (bracketCount && tok.isSymbol && [tok.stringValue isEqualToString:@"]"]) {
            
            bracketCount--;
            
            if (!bracketCount) {
                // we're done!
                
                [buffer appendString:[currentObjcCall description]];
                
                tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
                
            }
            
            currentObjcCall = [currentObjcCall pop];
            
        }
        else if (bracketCount) {
            [currentObjcCall addSymbol:[tok stringValue]];
        }
        else {
            [buffer appendString:[tok stringValue]];
        }
        
        lastWasWord = tok.isWord;
        
        lastToken = tok;
    }
    
    return buffer;
}


+ (NSString*) preprocessCode:(NSString*)sourceString {
    
    sourceString = [self preprocessForObjCStrings:sourceString];
    sourceString = [self preprocessForObjCMessagesToJS:sourceString];
    
    return sourceString;
}

@end




@implementation JSTPObjcCall
@synthesize args=_args;
@synthesize selector=_selector;
@synthesize target=_target;
@synthesize lastString=_lastString;

- (void)dealloc {
    [_args release];
    [_selector release];
    [_target release];
    [_lastString release];
    [super dealloc];
}


- (void) addSymbol:(id)aSymbol {
    
    if (!_target) {
        self.target = aSymbol;
        return;
    }
    
    if (!_selector) {
        self.selector = [NSMutableString stringWithString:aSymbol];
        return;
    }
    
    if ([aSymbol isKindOfClass:[NSString class]] && [aSymbol isEqualToString:@":"]) {
        
        if (_lastString) {
            [self.selector appendString:_lastString];
            self.lastString = 0x00;
            [_args removeLastObject];
        }
        
        [self.selector appendString:aSymbol];
        
        return;
    }
    
    if ([aSymbol isKindOfClass:[NSString class]] && [aSymbol isEqualToString:@","]) {
        // vargs, meh.
        return;
    }
    
    if ([aSymbol isKindOfClass:[NSString class]]) {
        self.lastString = aSymbol;
    }
    
    if (!_args) {
        self.args = [NSMutableArray array];
    }
    
    [_args addObject:aSymbol];
}

- (id) push {
    
    JSTPObjcCall *foo = [[[JSTPObjcCall alloc] init] autorelease];
    
    foo->_parent = self;
    
    [self addSymbol:foo];
    
    return foo;
}

- (id) pop {
    
    return _parent;
    
}

- (NSString*) description {
    
    NSMutableString *ret = [NSMutableString string];
    
    NSString *method = [self.selector stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    
    [ret appendFormat:@"%@.%@(", _target, method];
    
    for (id foo in _args) {
        [ret appendFormat:@"%@, ", [foo description]];
    }
    
    // get rid of the last comma
    if ([_args count]) {
        [ret deleteCharactersInRange:NSMakeRange([ret length] - 2 , 2)];
    }
    
    
    [ret appendString:@")"];
    
    return ret;
}


@end





