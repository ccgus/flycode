//
//  MYTableView.h
//  FeedMe
//
//  Created by Jens Alfke on 11/3/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTableView (MYUtilities)

- (void) my_selectRow: (NSInteger)row;

@end
