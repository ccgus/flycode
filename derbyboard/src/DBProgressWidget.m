//
//  DBProgressWidget.m
//  DerbyBoard
//
//  Created by August Mueller on 5/6/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import "DBProgressWidget.h"


@implementation DBProgressWidget

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
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

- (void)drawRect:(NSRect)rect {
    [NSGraphicsContext saveGraphicsState];
    
    NSRect theBounds = rect;
    
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

@end
