//
//  SyncViewController.h
//  vpreader
//
//  Created by August Mueller on 1/9/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLIPConnection.h"

@interface SyncViewController : UIViewController <TCPListenerDelegate, BLIPConnectionDelegate> {
    BLIPListener *_listener;
}

@end
