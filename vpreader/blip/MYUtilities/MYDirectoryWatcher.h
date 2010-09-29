//
//  MYDirectoryWatcher.h
//  Murky
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/* A wrapper for FSEvents, which notifies its delegate when filesystem changes occur. */
@interface MYDirectoryWatcher : NSObject 
{
    NSString *_path, *_standardizedPath;
    id _target;
    SEL _action;
    UInt64 _lastEventID;
    BOOL _historyDone;
    CFTimeInterval _latency;
    NSMutableSet* _modes;
    FSEventStreamRef _stream;
}

- (id) initWithDirectory: (NSString*)path target: (id)target action: (SEL)action;

@property (readonly,nonatomic) NSString* path;

@property (nonatomic) UInt64 lastEventID;
@property (nonatomic) CFTimeInterval latency;
@property (retain, nonatomic) NSMutableSet* runLoopModes;

- (BOOL) start;
- (void) pause;
- (void) stop;
- (void) stopTemporarily;               // stop, but re-start on next runloop cycle

@end



@interface MYDirectoryEvent : NSObject
{
    MYDirectoryWatcher *watcher;
    NSString *path;
    UInt64 eventID;
    UInt32 flags;
}

@property (readonly, nonatomic) MYDirectoryWatcher *watcher;
@property (readonly, nonatomic) NSString *path, *relativePath;
@property (readonly, nonatomic) UInt64 eventID;
@property (readonly, nonatomic) UInt32 flags;

@property (readonly, nonatomic) BOOL mustScanSubdirectories;
@property (readonly, nonatomic) BOOL eventsWereDropped;
@property (readonly, nonatomic) BOOL isHistorical;   
@property (readonly, nonatomic) BOOL rootChanged;

@end
