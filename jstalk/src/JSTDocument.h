//
//  JSTDocument.h
//  JSTalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright Flying Meat Inc 2009 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MarkerLineNumberView.h"
#import "JSTTextView.h"

@interface JSTDocument : NSDocument {
    IBOutlet JSTTextView *jsTextView;
    IBOutlet NSTextView *outputTextView;
    IBOutlet NSSplitView *splitView;
    
    
	NoodleLineNumberView	*lineNumberView;
}

- (void) executeScript:(id)sender;

@end
