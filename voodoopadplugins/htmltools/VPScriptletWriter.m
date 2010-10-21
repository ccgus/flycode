//
//  VPScriptletWriter.m
//  HTMLTools
//
//  Created by August Mueller on 10/12/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "VPScriptletWriter.h"


@implementation VPScriptletWriter
@synthesize buffer=_buffer;

- (id) init {
	self = [super init];
	if (self != nil) {
		_buffer = [[NSMutableString alloc] init];
	}
	return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_buffer release];
    [super dealloc];
}

- (void)write:(NSString*)s {
    [_buffer appendString:s];
}

- (void)writeln:(NSString*)s {
    [_buffer appendString:s];
    [_buffer appendString:@"\n"];
}



@end
