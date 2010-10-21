//
//  VPScriptletWriter.h
//  HTMLTools
//
//  Created by August Mueller on 10/12/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VPScriptletWriter : NSObject {
    NSMutableString *_buffer;
}

@property (retain) NSMutableString *buffer;

@end
