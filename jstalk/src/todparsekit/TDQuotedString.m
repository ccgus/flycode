//
//  TDQuotedString.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 7/13/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <TDParseKit/TDQuotedString.h>
#import <TDParseKit/TDToken.h>

@implementation TDQuotedString

+ (id)quotedString {
    return [[[self alloc] initWithString:nil] autorelease];
}


- (BOOL)qualifies:(id)obj {
    TDToken *tok = (TDToken *)obj;
    return tok.isQuotedString;
}

@end
