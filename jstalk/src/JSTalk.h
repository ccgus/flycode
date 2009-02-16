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
    id _printController;
    id _errorController;
}

@property (retain) NSMutableDictionary *T;

@property (assign) id printController;
@property (assign) id errorController;

- (void) executeString:(NSString*) str;
- (BOOL) sendJavascript:(NSString*)msg toBundleId:(NSString*)bundleId response:(NSString**)response;
- (void) pushObject:(id)obj withName:(NSString*)name inController:(JSCocoaController*)jsController;

- (JSCocoaController*) jsController;
- (id) callFunctionNamed:(NSString*)name withArguments:(NSArray*)args;

+ (void) listen;

@end
