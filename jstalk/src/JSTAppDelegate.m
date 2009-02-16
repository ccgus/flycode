//
//  JSTAppDelegate.m
//  jstalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTAppDelegate.h"

#import "JSTListener.h"

@interface JSTAppDelegate (PrivateStuff)
- (void) restoreWorkspace;
- (void) saveWorkspace;
@end


@implementation JSTAppDelegate

- (void)awakeFromNib {
    [self restoreWorkspace];
    [JSTListener listen];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self saveWorkspace];
}

- (void) restoreWorkspace {
    
    NSArray *ar = [[NSUserDefaults standardUserDefaults] objectForKey:@"workspaceOpenDocuments"];
    
    for (NSString *path in ar) {
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path] display:YES error:nil];
    }
}

- (void) saveWorkspace {
    
    NSMutableArray *openDocs = [NSMutableArray array];
    
    for (NSDocument *doc in [[NSDocumentController sharedDocumentController] documents]) {
        
        if ([doc fileName]) {
            // saving the file alias would be better.
            [openDocs addObject:[doc fileName]];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:openDocs forKey:@"workspaceOpenDocuments"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
