//
//  DBController.m
//  DerbyBoard
//
//  Created by August Mueller on 5/8/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import "DBController.h"

@implementation DBController

+ (void)initialize {
    
	NSMutableDictionary *defaultValues 	= [NSMutableDictionary dictionary];
    NSUserDefaults      *defaults 	 	= [NSUserDefaults standardUserDefaults];
    
    [defaultValues setObject:[NSNumber numberWithInt:15]  forKey:@"periodLength"];
    [defaultValues setObject:[NSNumber numberWithInt:120] forKey:@"jamLength"];
    [defaultValues setObject:@"Derby Girls From Hell" forKey:@"leagueName"];
    
    [defaults registerDefaults: defaultValues];
}

- (void) awakeFromNib {
    
    [self updatePrefs];
    
    [jamProgress setDoubleValue:0];
    
    [self setPeriodTimer:[DBTimer timer]];
    [[self periodTimer] setDelegate:self];
    [self setJamTimer:[DBTimer timer]];
    [[self jamTimer] setDelegate:self];
    
    [self updatePeriodTime];
    [self updateScore];
    
    
    
    id defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    
    [defaultsController addObserver:self
                         forKeyPath:@"values.periodLength" 
                            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                            context:NULL];
    
    [defaultsController addObserver:self
                         forKeyPath:@"values.jamLength" 
                            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                            context:NULL];
    
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self updatePrefs];
}

- (void) updatePrefs {
    
    [jamProgress setMaxValue:[self jamLength]];
    [jamProgress setMinValue:0];
    
    [self updatePeriodTime];
}

- (int) periodLength {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"periodLength"] * 60;
}

- (int) jamLength {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"jamLength"];
}

- (void) toggleJam:(id)sender {
    
    if ([[self jamTimer] isRunning]) {
        [[self jamTimer] stop];
    }
    else {
        [[self jamTimer] start];
        
        if (![[self periodTimer] isRunning]) {
            [[self periodTimer] toggle];
        }
    }
}

- (void) resetJam:(id)sender {
    [[self jamTimer] stop];
    [jamProgress setDoubleValue:0];
}

- (void) updatePeriodTime {
    
    NSTimeInterval delta = [self periodLength] - [_periodTimer elapsedTime];
    
    int minutes = delta / 60;
    
    NSString *minutesS = [NSString stringWithFormat:@"%d", minutes];
    if (minutes < 10) {
        minutesS = [NSString stringWithFormat:@"0%d", minutes];
    }
    
    int seconds = ((int)delta) % 60;
    NSString *secondsS = [NSString stringWithFormat:@"%d", seconds];
    if (seconds < 10) {
        secondsS = [NSString stringWithFormat:@"0%d", seconds];
    }
    
    [periodTime setStringValue:[NSString stringWithFormat:@"%@:%@", minutesS, secondsS]];
}

- (void) updateScore {
    
    [teamAScore setStringValue:[NSString stringWithFormat:@"%d", _teamAScoreCount]];
    [teamBScore setStringValue:[NSString stringWithFormat:@"%d", _teamBScoreCount]];
    
}

- (void) timerDidUpdate:(DBTimer*)timer {
    
    if (timer == _periodTimer) {
        [self updatePeriodTime];
    }
    else if (timer == _jamTimer) {
        [jamProgress setDoubleValue:[[self jamTimer] elapsedTime]];
        
        if ([[self jamTimer] elapsedTime] > [self jamLength]) {
            [self toggleJam:nil];
        }
    }
}


- (void) startPeriod:(id)sender {
    [[self periodTimer] start];
    [[self jamTimer] stop];
    [self toggleJam:self];
}

- (void) resetPeriod:(id)sender{
    [[self periodTimer] stop];
    [[self periodTimer] setElapsedTime:0];
    
    [[self jamTimer] stop];
    [[self jamTimer] setElapsedTime:0];
    
    [self updatePeriodTime];
    [jamProgress setDoubleValue:0];
}

- (void) togglePeriodTimer:(id)sender {
    [[self periodTimer] toggle];
    
    if ([[self periodTimer] isRunning]) {
        [[self jamTimer] start];
    }
    else {
        [[self jamTimer] stop];
    }
}

- (void) movePeriodBackOneSecond:(id)sender {
    [_periodTimer setElapsedTime:[_periodTimer elapsedTime] - 1];
    [self updatePeriodTime];
}

- (void) movePeriodForwardOneSecond:(id)sender {
    [_periodTimer setElapsedTime:[_periodTimer elapsedTime] + 1];
    [self updatePeriodTime];
}

- (void) movePeriodForwardOneMinute:(id)sender {
    [_periodTimer setElapsedTime:[_periodTimer elapsedTime] + 60];
    [self updatePeriodTime];
}

- (void) movePeriodBackOneMinute:(id)sender {
    [_periodTimer setElapsedTime:[_periodTimer elapsedTime] - 60];
    [self updatePeriodTime];
}


- (void) periodStep:(NSTimer*)timer {
    
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _periodStartTime;
    
    if (delta > [self periodLength]) {
        [self resetPeriod:self];
    }
    
    [self updatePeriodTime];
}



- (BOOL)window:(NSWindow*)aWindow shouldConstrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
    
    BOOL inFullScreen = (_preFullScreenFrame.size.width != 0);
    
    if ((aWindow == [self window]) && inFullScreen) {
        return NO;
    }
    
    return YES;
}

- (BOOL) isInFullScreen {
    return (_preFullScreenFrame.size.width != 0);
}

- (IBAction) toggleFullScreen:(id)sender {
    
    BOOL inFullScreen = [self isInFullScreen];
    
    [[self window] setShowsResizeIndicator:inFullScreen]; // remember, we're about to change from full to not.
    
    if (inFullScreen) {
        SetSystemUIMode(kUIModeNormal, 0);
        [[self window] setFrame:_preFullScreenFrame display:YES animate:NO];
        _preFullScreenFrame = NSZeroRect;
    }
    else {
        _preFullScreenFrame = [[self window] frame];
        
        NSScreen *windowScreen = [[self window] screen];
        
        if ([[NSScreen screens] objectAtIndex:0] == windowScreen) {
            // ie, we're the screen with the menu bar.
            SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
        }
                
        float windowBarHeight = [[self window] frame].size.height - ([[[self window] contentView] frame].size.height);
        
        NSRect frame = [[NSScreen mainScreen] frame];
        frame.size.height += windowBarHeight;
        
        [[self window] setFrame:frame display:YES animate:NO];
    }
}

- (DBTimer *)jamTimer {
    return _jamTimer; 
}
- (void)setJamTimer:(DBTimer *)newJamTimer {
    [newJamTimer retain];
    [_jamTimer release];
    _jamTimer = newJamTimer;
}




- (DBTimer *)periodTimer {
    return _periodTimer; 
}
- (void)setPeriodTimer:(DBTimer *)newPeriodTimer {
    [newPeriodTimer retain];
    [_periodTimer release];
    _periodTimer = newPeriodTimer;
}

- (void) addPointToTeamA:(id)sender {
    _teamAScoreCount++;
    [self updateScore];
}

- (void) addPointToTeamB:(id)sender {
    _teamBScoreCount++;
    [self updateScore];
}

- (void) subtractPointToTeamA:(id)sender {
    _teamAScoreCount--;
    [self updateScore];
}

- (void) subtractPointToTeamB:(id)sender {
    _teamBScoreCount--;
    [self updateScore];
}


@end
