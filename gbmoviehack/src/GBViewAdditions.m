//
//  GBViewAdditions.m
//  flyopts
//
//  Created by August Mueller on 11/28/07.
//  Copyright 2007 Flying Meat Inc. All rights reserved.
//

#import "GBViewAdditions.h"
#import "GBMovieWindowController.h"
#import <QTKit/QTKit.h>

@interface NSObject (GBViewAdditions)

- (id) movieController;
- (id) QTMovie;
- (BOOL) play;

@end

@implementation NSView (GBViewAdditions)

- (void) gbVideo:(id)sender {

    NSWindow *w = [self window];
    QTMovie *movie = [(id)[[w windowController] movieController] QTMovie];
    
    if (!movie) {
        NSBeep();
        return;
    }
    
    // Yes, we're just leaking.  It's a hack, I don't care.
    GBMovieWindowController *wc = [[GBMovieWindowController alloc] initWithWindowNibName:@"MovieWindow"];
    [wc wakeUpWithMovie:movie];
}

@end
