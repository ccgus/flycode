//
//  CToxicProgressIndicator.h
//  ToxicGadgets
//
//  Created by Jonathan Wight on 11/07/2005.
//  Copyright 2005 Toxic Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CToxicProgressIndicator : NSProgressIndicator {
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

- (void)setFromDefaults;

- (BOOL)isHalted;
- (void)setHalted:(BOOL)inHalted;

- (NSImage *)haltedImage;
- (void)setHaltedImage:(NSImage *)inHaltedImage;

- (BOOL)isPieChartStyle;

- (float)frameWidth;
- (void)setFrameWidth:(float)inFrameWidth;

- (NSColor *)frameColor;
- (void)setFrameColor:(NSColor *)inFrameColor;

- (NSColor *)wedgeColor;
- (void)setWedgeColor:(NSColor *)inWedgeColor;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)inBackgroundColor;


// The radial step count dictates whether the indicator will "snap to" 
// a certain number of steps in the pie, or whether it will show as many
// gradations as possible along the way from empty to full.
//
// For example:
//
//		0 stepCount -> "infinite gradation".
//		1 stepCount -> jumps from empty to full.
//		2 stepCount -> jumps from empty to half-full to full
//		3 - in thirds, 4 in fourths, etc.
//
// NOTE: stepCount is a convenience interface to the
// useSteps and stepAngle attributes.
//
- (int)stepCount;
- (void)setStepCount:(int)radialSteps;

- (BOOL)useSteps;
- (void)setUseSteps:(BOOL)inUseSteps;

- (double)stepAngle;
- (void)setStepAngle:(double)inStepAngle;

- (BOOL)overFillFirstStep;
- (void)setOverFillFirstStep:(BOOL)inOverFillFirstStep;

- (void)drawHaltedInRect:(NSRect)inFrame;
- (void)drawPieChartInRect:(NSRect)inFrame;;

@end
