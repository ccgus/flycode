//
//  BLIPEchoClient.h
//  MYNetwork
//
//  Created by Jens Alfke on 5/24/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//  Adapted from Apple sample code "CocoaEcho":
//  http://developer.apple.com/samplecode/CocoaEcho/index.html
//

#import <Cocoa/Cocoa.h>
@class BLIPConnection;


@interface BLIPEchoClient : NSObject
{
    IBOutlet NSTextField * inputField;
    IBOutlet NSTextField * responseField;
    IBOutlet NSTableView * serverTableView;
    
    NSNetServiceBrowser * _serviceBrowser;
    NSMutableArray * _serviceList;

    BLIPConnection *_connection;
}

@property (readonly) NSMutableArray *serviceList;

- (IBAction)sendText:(id)sender;

@end
