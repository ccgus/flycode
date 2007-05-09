//
//  DBController.h
//  DerbyBoard
//
//  Created by August Mueller on 5/8/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "CToxicProgressIndicator.h"
#import "DBTimer.h"

@interface DBController : NSWindowController {
    IBOutlet CToxicProgressIndicator *jamProgress;
    IBOutlet NSTextField *periodTime;
    IBOutlet NSTextField *teamAScore;
    IBOutlet NSTextField *teamBScore;
    
    IBOutlet NSTextField *teamAName;
    IBOutlet NSTextField *teamBName;
    
    DBTimer *_periodTimer;
    DBTimer *_jamTimer;
    
    NSTimeInterval _jamStartTime;
    NSTimeInterval _periodStartTime;
    
    int _teamAScoreCount;
    int _teamBScoreCount;
    
    NSRect          _preFullScreenFrame;
}

- (void) toggleFullScreen:(id)sender;

- (void) toggleJam:(id)sender;
- (void) resetJam:(id)sender;

- (void) startPeriod:(id)sender;
- (void) resetPeriod:(id)sender;
- (void) togglePeriodTimer:(id)sender;
- (void) movePeriodBackOneSecond:(id)sender;
- (void) movePeriodBackOneMinute:(id)sender;
- (void) movePeriodForwardOneSecond:(id)sender;
- (void) movePeriodForwardOneMinute:(id)sender;

- (void) addPointToTeamA:(id)sender;
- (void) addPointToTeamB:(id)sender;
- (void) subtractPointToTeamA:(id)sender;
- (void) subtractPointToTeamB:(id)sender;

- (DBTimer *)jamTimer;
- (void)setJamTimer:(DBTimer *)newJamTimer;

- (DBTimer *)periodTimer;
- (void)setPeriodTimer:(DBTimer *)newPeriodTimer;

- (void) updatePeriodTime;
- (void) updateScore;
- (void) updatePrefs;
- (int) jamLength;
@end
