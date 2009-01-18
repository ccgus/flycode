//
//  JSTalk.h
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSCocoaController.h"

@interface JSTalk : NSObject {
    NSMutableDictionary *_T;
}

@property (retain) NSMutableDictionary *T;

- (void) executeString:(NSString*) str;
- (BOOL) sendJavascript:(NSString*)msg toBundleId:(NSString*)bundleId response:(NSString**)response;
- (void) pushObject:(id)obj withName:(NSString*)name inController:(JSCocoaController*)jsController;

- (JSCocoaController*) jsController;
- (id) callFunctionNamed:(NSString*)name withArguments:(NSArray*)args;

@end
