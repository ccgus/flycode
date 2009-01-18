//
//  JSTAppDelegate.m
//  jstalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTAppDelegate.h"

#import "JSTListener.h"

@implementation JSTAppDelegate

- (void)awakeFromNib {
    [JSTListener listen];
}


@end
