//
//  MYXMLUtils.m
//  FeedMe
//
//  Created by Jens Alfke on 11/3/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYXMLUtils.h"

#import "Logging.h"


@implementation NSXMLElement (MYUtilities)


/* Follow an XPath, returning the result as a single string */
- (NSString*) my_stringAtXPath: (NSString*) xpath error: (NSError**)error
{
    NSArray *nodes = [self nodesForXPath: xpath error: error];
    if (!nodes) {
        // Can't avoid QName errors so don't report them
        if (!error || [[*error description] rangeOfString: @"can't resolve QName for"].length==0)
            Warn(@"XPath error for '%@': %@", xpath, (error ?*error :nil));
        return nil;
    }
    if( [nodes count] == 0 ) {
        if (error) *error = nil;
        return nil;
    }
    if( [nodes count] > 1 )
        Warn(@"stringAtXPath: Got %u results for '%@'", [nodes count],xpath);
    return [[nodes objectAtIndex: 0] stringValue];
}


/* Follow an XPath, returning the result as a single URL */
- (NSURL*) my_URLAtXPath: (NSString*) xpath error: (NSError**)error
{
    NSString *str = [self my_stringAtXPath: xpath error: error];
    if( ! str )
        return nil;
    NSURL *url = [NSURL URLWithString: str];
    if( ! url ) {
        Warn(@"Invalid URL <%@> for '%@'",str,xpath);
        if (error) *error = nil;
    }
    return url;
}


@end
