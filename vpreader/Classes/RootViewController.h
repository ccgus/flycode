//
//  RootViewController.h
//  vpreader
//
//  Created by August Mueller on 1/9/09.
//  Copyright Flying Meat Inc 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SyncViewController.h"
#import "WebViewController.h"

@interface RootViewController : UITableViewController {
    SyncViewController *syncViewController;
    WebViewController *webViewController;
    NSMutableArray *_documentNames;
    
    BOOL _hasLoadedSyncViewOnce;
}


@property (nonatomic,retain) SyncViewController *syncViewController;
@property (nonatomic,retain) WebViewController *webViewController;
@property (nonatomic,retain) NSMutableArray *documentNames;



@end
