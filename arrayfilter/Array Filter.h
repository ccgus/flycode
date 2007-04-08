//
//  Array Filter.h
//  Array Filter
//
//  Created by August Mueller on 4/8/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>

@interface Array_Filter : AMBundleAction 
{
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;

@end
