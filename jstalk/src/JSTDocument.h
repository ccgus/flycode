//
//  JSTDocument.h
//  JSTalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright Flying Meat Inc 2009 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <TDParseKit/TDParseKit.h>
#import "MarkerLineNumberView.h"
#import "JSTTextView.h"

@interface JSTDocument : NSDocument {
    IBOutlet JSTTextView *jsTextView;
    IBOutlet NSTextView *outputTextView;
    IBOutlet NSSplitView *splitView;
    
    
	NoodleLineNumberView	*lineNumberView;
    TDTokenizer *_tokenizer;
}

@property (retain) TDTokenizer *tokenizer;

- (void) executeScript:(id)sender;
- (void) parseCode:(id)sender;

@end




