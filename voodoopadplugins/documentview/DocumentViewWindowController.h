//
//  DocumentViewWindowController.h
//  DocumentView
//
//  Created by August Mueller on 4/5/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DocumentViewWindowController : NSWindowController {
    IBOutlet NSScrollView *scrollView;
    
    NSLayoutManager *layoutMgr;
    NSTextStorage *textStorage;
}

- (void) loadAttributedString:(NSAttributedString*) ats;

@end
