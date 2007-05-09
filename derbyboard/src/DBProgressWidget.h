//
//  DBProgressWidget.h
//  DerbyBoard
//
//  Created by August Mueller on 5/6/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DBProgressWidget : NSProgressIndicator {
	BOOL halted;
	NSImage *haltedImage;
    
	float frameWidth;
	NSColor *frameColor;
	NSColor *wedgeColor;
	NSColor *backgroundColor;
    
	BOOL useSteps;
	double stepAngle;
	BOOL overFillFirstStep;
}

@end
