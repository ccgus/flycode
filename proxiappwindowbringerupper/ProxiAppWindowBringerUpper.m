#import "ProxiAppWindowBringerUpper.h"
#import <Carbon/Carbon.h>

static OSStatus handleAppFrontSwitched(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData);
static OSStatus mouseActivated(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData);

EventHandlerRef MySkankyGlobalFrontAppSwitchedHandlerRef;


@implementation ProxiAppWindowBringerUpper

+ (void) load
{
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    
    EventTypeSpec spec = { kEventClassApplication, kEventAppFrontSwitched };
    
    OSStatus err = InstallApplicationEventHandler(NewEventHandlerUPP(handleAppFrontSwitched), 1, &spec, nil, &MySkankyGlobalFrontAppSwitchedHandlerRef);
    
    if (err) {
        NSLog(@"Error looking for front app.");
    }
}


static OSStatus handleAppFrontSwitched(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData) {
    
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    
    NSDictionary *activeAppDict = [workspace activeApplication];
    ProcessSerialNumber    psn;
    
    psn.highLongOfPSN = [[activeAppDict objectForKey:@"NSApplicationProcessSerialNumberHigh"] intValue];
    psn.lowLongOfPSN  = [[activeAppDict objectForKey:@"NSApplicationProcessSerialNumberLow"] intValue];
    
    SetFrontProcess( &psn );  
    
    // this .. causes a bit o' recursion for some reason.
    //ProcessSerialNumber xpsn = { 0, kCurrentProcess };
    //SetFrontProcess( & xpsn );
    
    return 0;
}

@end