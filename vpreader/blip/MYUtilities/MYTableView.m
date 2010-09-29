//
//  MYTableView.m
//  FeedMe
//
//  Created by Jens Alfke on 11/3/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYTableView.h"


@implementation NSTableView (MYUtilities)

- (void) my_selectRow: (NSInteger)row {
    NSIndexSet *indexes = [[NSIndexSet alloc] initWithIndex: row];
    [self selectRowIndexes: indexes byExtendingSelection: NO];
    [indexes release];
}

@end
