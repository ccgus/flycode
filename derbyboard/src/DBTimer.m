//
//  DBTimer.m
//  DerbyBoard
//
//  Created by August Mueller on 5/8/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import "DBTimer.h"


@implementation DBTimer

+ (id) timer {
    return [[[self alloc] init] autorelease];
}

- (NSTimeInterval)elapsedTime {
    return _elapsedTime;
}
- (void)setElapsedTime:(NSTimeInterval)newElapsedTime {
    _elapsedTime = newElapsedTime;
}


- (NSTimeInterval)timerStart {
    return _timerStart;
}
- (void)setTimerStart:(NSTimeInterval)newTimerStart {
    _timerStart = newTimerStart;
}


- (NSTimer *)timer {
    return _timer; 
}
- (void)setTimer:(NSTimer *)newTimer {
    
    if (_timer) {
        [_timer invalidate];
    }
    
    [newTimer retain];
    [_timer release];
    _timer = newTimer;
}


- (void) toggle {
    
    if (_timer) {
        [self setTimer:nil];
    }
    else {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(timerHit:) userInfo:nil repeats:YES];
        [self setTimer:timer];
        _timerStart = [NSDate timeIntervalSinceReferenceDate];
    }
}

- (void) start {
    _elapsedTime = 0;
    [self setTimer:nil];
    [self toggle];
}

- (void) stop {
    [self setTimer:nil];
}

- (void) timerHit:(NSTimer*)timer {
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    _elapsedTime += now - _timerStart;
    
    _timerStart = [NSDate timeIntervalSinceReferenceDate];
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(timerDidUpdate:)]) {
        [[self delegate] timerDidUpdate:self];
    }
}

- (BOOL) isRunning {
    return (_timer != nil);
}

- (id)delegate {
    return delegate; 
}
- (void)setDelegate:(id)newDelegate {
    [newDelegate retain];
    [delegate release];
    delegate = newDelegate;
}




@end
