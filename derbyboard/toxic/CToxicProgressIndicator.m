	//
//  CToxicProgressIndicator.m
//  ToxicGadgets
//
//  Created by Jonathan Wight on 11/07/2005.
//  Copyright 2005 Toxic Software. All rights reserved.
//

#import "CToxicProgressIndicator.h"

#define debug NSLog

@implementation CToxicProgressIndicator



- (id)initWithFrame:(NSRect)inFrame
{
    if ((self = [super initWithFrame:inFrame]) != NULL)
	{
        [self setFromDefaults];
	}
    return(self);
}

- (void)dealloc
{
    [self setHaltedImage:NULL];
//
    [frameColor release];
    frameColor = NULL;
//
    [wedgeColor release];
    wedgeColor = NULL;
//
    [backgroundColor release];
    backgroundColor = NULL;
//
    [super dealloc];
}

#pragma mark -

- (void)drawRect:(NSRect)inRect {   
    [self drawPieChartInRect:[self bounds]];
}

#pragma mark -

- (void)setDoubleValue:(double)inValue
{
    [super setDoubleValue:inValue];
    [self setNeedsDisplay:YES];
}

- (void)setMinValue:(double)inNewMinimum {
    [super setMinValue:inNewMinimum];
    [self setNeedsDisplay:YES];
}

- (void)setMaxValue:(double)inNewMaximum {
    [super setMaxValue:inNewMaximum];
    [self setNeedsDisplay:YES];
}

#pragma mark -

- (void)setFromDefaults
{
    [self setHalted:NO];
    NSImage *theImage = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"ProgressIndicatorHalted"]] autorelease];
    [theImage setFlipped:YES];
    [self setHaltedImage:theImage];
    [self setDoubleValue:25.0];
    [self setFrameWidth:2.0f];
    [self setFrameColor:[NSColor whiteColor]];
    [self setWedgeColor:[NSColor whiteColor]];
    [self setBackgroundColor:[NSColor colorWithDeviceWhite:0.0f alpha:0.0f]];;
    [self setUseSteps:NO];
    //[self setStepAngle:360.0 / 12.0];
    [self setOverFillFirstStep:NO]; // For DCJ
}

#pragma mark -

- (BOOL)isHalted
{
    return(halted);
}

- (void)setHalted:(BOOL)inHalted;
{
    if (halted != inHalted)
	{
        halted = inHalted;
        [self setNeedsDisplay:YES];
	}
}

- (NSImage *)haltedImage
{
    return(haltedImage);
}

- (void)setHaltedImage:(NSImage *)inHaltedImage
{
    if (haltedImage != inHaltedImage)
	{
        [haltedImage autorelease];
        haltedImage = [inHaltedImage retain];
        [self setNeedsDisplay:YES];
	}
}

- (BOOL)isPieChartStyle
{
    return([self isIndeterminate] == NO && [self style] == NSProgressIndicatorSpinningStyle);
}

- (float)frameWidth
{
    return(frameWidth);
}

- (void)setFrameWidth:(float)inFrameWidth
{
    if (frameWidth != inFrameWidth)
	{
        frameWidth = inFrameWidth;
        [self setNeedsDisplay:YES];
	}
}

#pragma mark -

- (NSColor *)frameColor
{
    return(frameColor);
}

- (void)setFrameColor:(NSColor *)inFrameColor
{
    if (frameColor != inFrameColor)
	{
        [frameColor autorelease];
        frameColor = [inFrameColor retain];
        [self setNeedsDisplay:YES];
	}
}

- (NSColor *)wedgeColor
{
    return(wedgeColor);
}

- (void)setWedgeColor:(NSColor *)inWedgeColor
{
    if (wedgeColor != inWedgeColor)
	{
        [wedgeColor autorelease];
        wedgeColor = [inWedgeColor retain];
        [self setNeedsDisplay:YES];
	}
}

- (NSColor *)backgroundColor
{
    return(backgroundColor);
}

- (void)setBackgroundColor:(NSColor *)inBackgroundColor
{
    if (backgroundColor != inBackgroundColor)
	{
        [backgroundColor autorelease];
        backgroundColor = [inBackgroundColor retain];
        [self setNeedsDisplay:YES];
	}
}

- (BOOL)useSteps
{
    return(useSteps);
}

- (void)setUseSteps:(BOOL)inUseSteps
{
    if (useSteps != inUseSteps)
	{
        useSteps = inUseSteps;
        [self setNeedsDisplay:YES];
	}
}

- (double)stepAngle
{
    return(stepAngle);
}

- (void)setStepAngle:(double)inStepAngle
{
    if (stepAngle != inStepAngle)
	{
        stepAngle = inStepAngle;
        [self setNeedsDisplay:YES];
	}
}

- (int)stepCount
{
    if ([self useSteps] == NO)
	{
        return 0;
	}
    else
	{
        return (360.0 / [self stepAngle]);
	}
}

- (void)setStepCount:(int)radialSteps
{
    if (radialSteps == 0)
	{
        [self setUseSteps:NO];
	}
    else
	{
        [self setUseSteps:YES];
        [self setStepAngle:(360.0 / radialSteps)];
	}
}

- (BOOL)overFillFirstStep
{
    return(overFillFirstStep);
}

- (void)setOverFillFirstStep:(BOOL)inOverFillFirstStep
{
    overFillFirstStep = inOverFillFirstStep;
    [self setNeedsDisplay:YES];
}

#pragma mark -

- (void)drawHaltedInRect:(NSRect)inFrame
{
    NSImage *theImage = [self haltedImage];
    [theImage drawInRect:inFrame fromRect:NSMakeRect(0.0f, 0.0f, [theImage size].width, [theImage size].height) operation:NSCompositeSourceOver fraction:1.0f];
}

- (void)drawPieChartInRect:(NSRect)inFrame
{
    [NSGraphicsContext saveGraphicsState];
    
    NSRect theBounds = inFrame;
    
// Clip to the border of the pie chart...
    NSBezierPath *thePath = [NSBezierPath bezierPathWithOvalInRect:theBounds];
    [thePath setLineWidth:[self frameWidth]];
    [thePath addClip];
    
    theBounds = NSInsetRect(theBounds, [self frameWidth] / 2.0f, [self frameWidth] / 2.0f);
    
    NSPoint theCenter = {
        .x = theBounds.origin.x + theBounds.size.width / 2.0f,
        .y = theBounds.origin.y + theBounds.size.height / 2.0f,
	};
    
    double theAngle = ([self doubleValue] - [self minValue]) / ([self maxValue] - [self minValue]) * 360.0;
    if ([self useSteps])
	{
	// DCJ: In the interest of not filling the pie until the progress is actually completed,
	// I removed the case for pinning values greater than 0 but less than angle to "angle"
        if (theAngle > 0.0 && theAngle < [self stepAngle] && [self overFillFirstStep])
            theAngle = stepAngle;
        else
            theAngle = floor(theAngle / [self stepAngle]) * [self stepAngle];
	}
    
// Draw piechart background...
    thePath = [NSBezierPath bezierPathWithOvalInRect:theBounds];
    [thePath setLineWidth:[self frameWidth]];
//
    [[self backgroundColor] set];
    [thePath fill];
    
// Draw piechart wedge.
    if (theAngle != 0.0)
	{
        thePath = [NSBezierPath bezierPath];
        [thePath moveToPoint:theCenter];
	//[thePath lineToPoint:NSMakePoint(theCenter.x, theBounds.origin.y + theBounds.size.height)];
        [thePath appendBezierPathWithArcWithCenter:theCenter radius:theBounds.size.width / 2.0f startAngle:270.0f endAngle:270.0f + theAngle];
        [thePath lineToPoint:theCenter];
        [thePath closePath];
        [thePath setLineCapStyle:NSRoundLineCapStyle];
        [thePath setLineJoinStyle:NSRoundLineJoinStyle];
        
        [[self wedgeColor] set];
        [thePath fill];
        
        if (theAngle != 360.0f)
		{
            [thePath setLineWidth:[self frameWidth]];
            [[self frameColor] set];
            [thePath stroke];
		}
	}
    
// Draw piechart border...
    thePath = [NSBezierPath bezierPathWithOvalInRect:theBounds];
    [thePath setLineWidth:[self frameWidth]];
//
    [[self frameColor] set];
    [thePath stroke];
    
    
    
    [NSGraphicsContext restoreGraphicsState];
}

#pragma mark -

- (void)setIndeterminate:(BOOL)inIndeterminate
{
    [self willChangeValueForKey:@"pieChartStyle"];
//
    [super setIndeterminate:inIndeterminate];
//
    [self didChangeValueForKey:@"pieChartStyle"];
}

- (void)setStyle:(NSProgressIndicatorStyle)style;
{
    [self willChangeValueForKey:@"pieChartStyle"];
//
    [super setStyle:style];
//
    [self didChangeValueForKey:@"pieChartStyle"];
}

@end
