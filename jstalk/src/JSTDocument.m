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

@implementation JSTDocument

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
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
    
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    JSCocoaController *jsController = [jstalk jsController];
    
    [jstalk pushObject:self withName:@"_jstDocument" inController:jsController];
    [jsController evalJSString:@"function print(s) { _jstDocument.print(s); }"];
    
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


@end
