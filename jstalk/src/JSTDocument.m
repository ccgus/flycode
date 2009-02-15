//
//  JSTDocument.m
//  JSTalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright Flying Meat Inc 2009 . All rights reserved.
//

#import "JSTDocument.h"
#import "JSTListener.h"
#import "JSTalk.h"
#import "JSCocoaController.h"
#import "JSTPreprocessor.h"


@implementation JSTDocument
@synthesize tokenizer=_tokenizer;

- (id)init
{
    self = [super init];
    if (self) {
        
        self.tokenizer = [[[TDTokenizer alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_tokenizer release];
    _tokenizer = 0x00;
    
    [super dealloc];
}


- (NSString *)windowNibName {
    return @"JSTDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
    
    if ([self fileURL]) {
        
        NSError *err = 0x00;
        NSString *src = [NSString stringWithContentsOfURL:[self fileURL] encoding:NSUTF8StringEncoding error:&err];
        
        if (err) {
            NSBeep();
            NSLog(@"err: %@", err);
        }
        
        if (src) {
            [[[jsTextView textStorage] mutableString] setString:src];
        }
        
        [[aController window] setFrameAutosaveName:[self fileName]];
        [splitView setAutosaveName:[self fileName]];
    }
    
    lineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:[jsTextView enclosingScrollView]];
    [[jsTextView enclosingScrollView] setVerticalRulerView:lineNumberView];
    [[jsTextView enclosingScrollView] setHasHorizontalRuler:NO];
    [[jsTextView enclosingScrollView] setHasVerticalRuler:YES];
    [[jsTextView enclosingScrollView] setRulersVisible:YES];
    
    [outputTextView setTypingAttributes:[jsTextView typingAttributes]];
    
    
    [[jsTextView textStorage] setDelegate:self];
    [self parseCode:nil];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    
    NSData *d = [[[jsTextView textStorage] string] dataUsingEncoding:NSUTF8StringEncoding];
    

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    
	return d;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (void) print:(NSString*)s {
    [[[outputTextView textStorage] mutableString] appendFormat:@"%@\n", s];
}

- (void) runScript:(NSString*)s {
    
    s = [JSTPreprocessor preprocessCode:s];
    
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    JSCocoaController *jsController = [jstalk jsController];
    
    [jstalk pushObject:self withName:@"_jstDocument" inController:jsController];
    
    
    jstalk.printController = self;
    
    
    [jstalk executeString:s];
}

- (void) executeScript:(id)sender { 
    [self runScript:[[jsTextView textStorage] string]];
}

- (void) executeSelectedScript:(id)sender {
    
    NSRange r = [jsTextView selectedRange];
    
    if (r.length == 0) {
        r = NSMakeRange(0, [[jsTextView textStorage] length]);
    }
    
    NSString *s = [[[jsTextView textStorage] string] substringWithRange:r];
    
    [self runScript:s];
    
}

- (void) textStorageDidProcessEditing:(NSNotification *)note {
    [self parseCode:nil];
}

- (void) preprocessCodeAction:(id)sender {
    
    NSString *code = [JSTPreprocessor preprocessCode:[[jsTextView textStorage] string]];
    
    debug(@"code: %@", code);
}

- (void) parseCode:(id)sender {
    
    // we should really do substrings...
    
    NSString *sourceString = [[jsTextView textStorage] string];
    TDTokenizer *tokenizer = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.commentState.reportsCommentTokens = YES;
    
    [tokenizer.symbolState add:@"for"];
    [tokenizer.symbolState add:@"print"];
    
    TDToken *eof = [TDToken EOFToken];
    TDToken *tok = nil;
    
    [[jsTextView textStorage] beginEditing];
    
    
    NSRange lastRange = NSMakeRange(0, [sourceString length]);
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        NSRange foundRange = [sourceString rangeOfString:tok.stringValue options:0 range:lastRange];
        NSColor *fontColor = 0x00;
        
        if (foundRange.location != NSNotFound) {
            
            if (tok.quotedString) {
                fontColor = [NSColor grayColor];
            }
            else if (tok.isNumber) {
                fontColor = [NSColor blueColor];
            }
            else if (tok.isComment) {
                fontColor = [NSColor redColor];
            }
            else if (tok.isSymbol) {
                fontColor = [NSColor blackColor];
            }
            else if (tok.isWord) {
                fontColor = [NSColor blueColor];
            }
            
            lastRange.location = NSMaxRange(foundRange);
            lastRange.length   = [sourceString length] - lastRange.location;
        }
        else {
            debug(@"Can't find the string!");
            break;// wtf?
        }
        
        if (fontColor) {
            [[jsTextView textStorage] addAttribute:NSForegroundColorAttributeName value:fontColor range:foundRange];
        }
    }
    
    
    [[jsTextView textStorage] endEditing];
    
}


@end
