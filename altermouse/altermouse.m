/*

seriously hacked up from alterkeys.c, stolen from http://osxbook.com .

The whole point of this app, is to let me have my custom mouse behaviors 
when running a dev build of the OS where USBOverdrive doesn't work so well...

Complile using the following command line:
  gcc -Wall -o altermouse altermouse.m -framework ApplicationServices -framework Carbon

You need superuser privileges to create the event tap, unless accessibility
is enabled. To do so, select the "Enable access for assistive devices"
checkbox in the Universal Access system preference pane.
*/

#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

// This callback will be invoked every time there is a mouse press.
//
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    // Paranoid sanity check.
    if ((type != kCGEventOtherMouseDown) && (type != kCGEventOtherMouseUp))
        return event;
    
    // The incoming keycode.
    int code = CGEventGetIntegerValueField(event, kCGMouseEventButtonNumber);
    
    printf("code: %d\n", code);
    
    CGInhibitLocalEvents(true);
    CGEnableEventStateCombining(false);
    
    if (code == 6) {
        CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)116, true);
        CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)116, false);
    }
    else if (code == 7) {
        CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)121, true);
        CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)121, false);
        
    }
    else if (code == 2) {
        if (type == kCGEventOtherMouseDown) {
            CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)99, true); // f1 = 122 , f3 = 99
            CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)99, false);
        }
        
        event = nil;
        goto exit;
        
    }
    else if (code == 3) {
        CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)58, true);
        
        CGPostMouseEvent(CGEventGetLocation(event), false, 1, true);
        CGPostMouseEvent(CGEventGetLocation(event), false, 1, false);
        
        CGPostMouseEvent(CGEventGetLocation(event), false, 1, true);
        CGPostMouseEvent(CGEventGetLocation(event), false, 1, false);
        
        CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)58, false);
        
        event = nil;
        goto exit;
    }
    
    exit:
    
    CGEnableEventStateCombining(true);
    CGInhibitLocalEvents(false);
    
    return event;
}

static OSStatus handleAppFrontSwitched(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData) {
    /* [(id)inUserData appDidChange]; */
    printf("foo\n");
    return 0;
}



int
main(void)
{
    CFMachPortRef       eventTap;
    CGEventMask         eventMask;
    CFRunLoopSourceRef  runLoopSource;
    EventHandlerRef     frontAppSwitchedHandlerRef;
    
    // Create an event tap. We are interested in key presses.
    eventMask = ((1 << kCGEventOtherMouseDown)); // | (1 << kCGEventOtherMouseUp));
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, myCGEventCallback, NULL);
    if (!eventTap) {
        fprintf(stderr, "failed to create event tap\n");
        exit(1);
    }
    
    // Create a run loop source.
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    
    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    
    // Enable the event tap.
    CGEventTapEnable(eventTap, true);
    
    
    
    EventTypeSpec spec = { kEventClassApplication, kEventAppFrontSwitched };
    
    OSStatus err = InstallApplicationEventHandler(NewEventHandlerUPP(handleAppFrontSwitched), 1, &spec, nil, &frontAppSwitchedHandlerRef);
    
    if (err) {
        fprintf(stderr, "err!");
    }
    
    // Set it all running.
    CFRunLoopRun();
    
    // In a real program, one would have arranged for cleaning up.
    
    exit(0);
}