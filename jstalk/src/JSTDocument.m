//
//  JSTDocument.m
//  JSTalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright Flying Meat Inc 2009 . All rights reserved.
//

#import "JSTDocument.h"
#import "JSTListener.h"
#import "JSTalk.h"
#import "JSCocoaController.h"

@implementation JSTDocument

@synthesize jsSrc=_jsSrc;


- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSString *)windowNibName {
    return @"JSTDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
}

- (void)awakeFromNib {
	
    if (_jsSrc) {
        [[[jsTextView textStorage] mutableString] setString:_jsSrc];
    }
    
    
}



- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    
    NSData *d = [[[jsTextView textStorage] string] dataUsingEncoding:NSUTF8StringEncoding];
    

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    
	return d;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    NSString *j = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    self.jsSrc = j;
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}



- (void) send:(id)sender {
    [[[[JSTalk alloc] init] autorelease] executeString:[[jsTextView textStorage] string]];
    
}














@end
