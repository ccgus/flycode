//
//  MYXMLUtils.h
//  FeedMe
//
//  Created by Jens Alfke on 11/3/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSXMLElement (MYUtilities)

/*  Follow an XPath, returning the result as a single string.
    If multiple nodes match, only the text of the first one is returned. */
- (NSString*) my_stringAtXPath: (NSString*) xpath error: (NSError**)error;

/* Follow an XPath, returning the result as a single URL. */
- (NSURL*) my_URLAtXPath: (NSString*) xpath error: (NSError**)error;

@end
