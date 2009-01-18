//
//  JSTDocument.h
//  JSTalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright Flying Meat Inc 2009 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface JSTDocument : NSDocument {
    IBOutlet NSTextView *jsTextView;
    IBOutlet NSTextField *jsBundleId;
    
    NSString *_jsSrc;
    
}

@property (retain) NSString *jsSrc;

- (void) send:(id)sender;

@end
