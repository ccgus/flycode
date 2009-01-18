#import <Cocoa/Cocoa.h>
#import "JSTListener.h"
#import "JSTalk.h"

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString *s = [NSString stringWithContentsOfFile:@"/Volumes/srv/Users/gus/Projects/flycode/jstalk/sample.jstalk"
                                            encoding:NSUTF8StringEncoding
                                               error:nil];
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    
    [t executeString:s];
    
    //[JSTListener sendJavascript:msg toBundleId:[jsBundleId stringValue] response:&res];
    
    

    [pool release];
    
    
}
