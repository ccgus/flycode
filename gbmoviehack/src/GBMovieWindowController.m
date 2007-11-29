//
//  GBMovieWindowController.m
//  flyopts
//
//  Created by August Mueller on 11/28/07.
//  Copyright 2007 Flying Meat Inc. All rights reserved.
//

#import "GBMovieWindowController.h"


@implementation GBMovieWindowController

- (QTMovieView *)movieView {
    return movieView;
}

- (void) wakeUpWithMovie:(QTMovie*)movie {
    
    NSValue *movieSize = [[movie movieAttributes] objectForKey:QTMovieCurrentSizeAttribute];
    
    NSSize s = [movieSize sizeValue];
    
    [[self window] setContentSize:s];
    
    [[self window] center];
    
    [[self window] makeKeyAndOrderFront:self];
    
    [movieView setMovie:movie];
}

@end
