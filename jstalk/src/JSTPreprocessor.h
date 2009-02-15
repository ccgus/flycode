//
//  JSTPreprocessor.h
//  jstalk
//
//  Created by August Mueller on 2/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JSTPreprocessor : NSObject {

}

+ (NSString*) preprocessCode:(NSString*)sourceString;

@end





@interface JSTPObjcCall : NSObject {
    
    NSMutableArray *_subs;
    
    JSTPObjcCall *_parent;
    
    NSString *_iName;
    NSString *_lastString;
    NSMutableString *_selector;
}

@property (retain) NSMutableArray *subs;
@property (retain) NSMutableString *selector;


- (void) addSymbol:(id)whatever;
- (id) push;
- (id) pop;

@end




