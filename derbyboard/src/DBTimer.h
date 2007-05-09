//
//  DBTimer.h
//  DerbyBoard
//
//  Created by August Mueller on 5/8/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DBTimer : NSObject {
    NSTimeInterval _elapsedTime;
    NSTimeInterval _timerStart;
    NSTimer *_timer;
    id delegate;
}

+ (id) timer;

- (NSTimeInterval)elapsedTime;
- (void)setElapsedTime:(NSTimeInterval)newElapsedTime;
- (NSTimeInterval)timerStart;
- (void)setTimerStart:(NSTimeInterval)newTimerStart;
- (NSTimer *)timer;
- (void)setTimer:(NSTimer *)newTimer;
- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (void) toggle;
- (void) start;
- (void) stop;

- (BOOL) isRunning;

@end

@interface NSObject (DBTimerAdditions)

- (void) timerDidUpdate:(DBTimer*)timer;

@end
