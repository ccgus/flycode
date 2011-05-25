//
//  AppDelegate.h
//  davtest
//
//  Created by August Mueller on 8/6/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject {
    BOOL waitingOnAuthentication;
}

- (void)testErrorAction:(id)sender;
- (void)testCopyAction:(id)sender;
- (void)testBadUrlAction:(id)sender;
- (void)testReleaseStuffAction:(id)sender;
@end
