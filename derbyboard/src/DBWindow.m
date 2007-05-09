#import "DBWindow.h"


@interface NSObject (VoodooPadWindowNSObjectAdditions)
- (BOOL)window:(NSWindow*)window shouldConstrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen;

@end

@implementation DBWindow

- (void) awakeFromNib {
    [self setMovableByWindowBackground:YES];
    NSRect backBounds = [self frame];
    backBounds.origin = NSZeroPoint;
    
    NSClipView *colorView = [[NSClipView alloc] initWithFrame:backBounds];
    [colorView setBackgroundColor:[NSColor blackColor]];
    [colorView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[self contentView] addSubview:colorView positioned:NSWindowBelow relativeTo:nil];
    
    [[self contentView] setAutoresizesSubviews:YES];
}


- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:shouldConstrainFrameRect:toScreen:)]) {
        if (![[self delegate] window:self shouldConstrainFrameRect:frameRect toScreen:screen]) {
            return frameRect;
        }
    }
    
    return [super constrainFrameRect:frameRect toScreen:screen];
}




@end

