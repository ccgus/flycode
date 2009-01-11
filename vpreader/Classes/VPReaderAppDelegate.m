//
//  VPReaderAppDelegate.m
//  vpreader
//
//  Created by August Mueller on 1/9/09.
//  Copyright Flying Meat Inc 2009. All rights reserved.
//

#import "VPReaderAppDelegate.h"
#import "RootViewController.h"


@implementation VPReaderAppDelegate

@synthesize window;
@synthesize navigationController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	debug(@"whut?");
	// Configure and show the window
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
}


- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}

+ (NSString*)documentFolder {
    
    NSArray *paths                  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory    = [paths objectAtIndex:0];
    
    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory attributes:nil];
    }
    
    return documentsDirectory;
}

@end
