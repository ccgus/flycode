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
    TDToken *tok                    = nil;
    NSString *lastTokenStr          = nil;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        if (tok.quotedString && [lastTokenStr isEqualToString:@"@"]) {
            [buffer deleteCharactersInRange:NSMakeRange([buffer length] - 1 , 1)];
            [buffer appendFormat:@"[NSString stringWithString:%@]", [tok stringValue]];
        }
        else {
            [buffer appendString:[tok stringValue]];
        }
        
        lastTokenStr = [tok stringValue];
    }
    
    return buffer;
    
}

+ (NSString*) preprocessCode:(NSString*)sourceString {
    
    sourceString = [self preprocessForObjCStrings:sourceString];
    
    debug(@"sourceString: %@", sourceString);
    
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









@end




@implementation JSTPObjcCall
@synthesize subs=_subs;
@synthesize selector=_selector;

- (void)dealloc {
    [_subs release];
    [_selector release];
    [super dealloc];
}


- (void) addSymbol:(id)whatever {
    
    if (!_iName) {
        _iName = whatever;
        return;
    }
    
    if (!_selector) {
        self.selector = [NSMutableString stringWithString:whatever];
        return;
    }
    
    if ([whatever isKindOfClass:[NSString class]] && [whatever isEqualToString:@":"]) {
        
        if (_lastString) {
            [self.selector appendString:_lastString];
            _lastString = 0x00;
            [_subs removeLastObject];
        }
        
        [self.selector appendString:whatever];
        
        return;
    }
    
    if ([whatever isKindOfClass:[NSString class]]) {
        _lastString = whatever;
    }
    
    
    if (!_subs) {
        self.subs = [NSMutableArray array];
    }
    
    [_subs addObject:whatever];
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
    
    [ret appendFormat:@"%@.%@(", _iName, method];
    
    for (id foo in _subs) {
        [ret appendFormat:@"%@, ", [foo description]];
    }
    
    // get rid of the last comma
    if ([_subs count]) {
        [ret deleteCharactersInRange:NSMakeRange([ret length] - 2 , 2)];
    }
    
    
    [ret appendString:@")"];
    
    return ret;
}


@end





