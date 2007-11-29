//
//  GBMovieWindowController.h
//  flyopts
//
//  Created by August Mueller on 11/28/07.
//  Copyright 2007 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface GBMovieWindowController : NSWindowController {
    IBOutlet QTMovieView *movieView;
}

- (QTMovieView *)movieView;
- (void) wakeUpWithMovie:(QTMovie*)movie;

@end
