//
//  JSTTextView.m
//  jstalk
//
//  Created by August Mueller on 1/18/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTTextView.h"


@implementation JSTTextView


- (void) insertTab:(id)sender {
    [self insertText:@"    "];
}


- (void) insertNewline:(id)sender {
    
    [super insertNewline:sender];
    
    NSRange r = [self selectedRange];
    if (r.location > 0) {
        r.location --;
    }
    
    r = [self selectionRangeForProposedRange:r granularity:NSSelectByParagraph];
    
    NSString *previousLine = [[[self textStorage] mutableString] substringWithRange:r];
    
    int j = 0;
    
    while (j < [previousLine length] && ([previousLine characterAtIndex:j] == ' ' || [previousLine characterAtIndex:j] == '\t')) {
        j++;
    }
    
    if (j > 0) {
        NSString *foo = [[[self textStorage] mutableString] substringWithRange:NSMakeRange(r.location, j)];
        [self insertText:foo];
    }
    
    
}


@end
