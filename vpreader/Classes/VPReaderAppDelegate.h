//
//  vpreaderAppDelegate.h
//  vpreader
//
//  Created by August Mueller on 1/9/09.
//  Copyright Flying Meat Inc 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VPReaderAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

+ (NSString*)documentFolder;

@end

