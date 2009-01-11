//
//  BLIPEchoClient.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/24/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//  Adapted from Apple sample code "CocoaEcho":
//  http://developer.apple.com/samplecode/CocoaEcho/index.html
//

#import "BLIPEchoClient.h"
#import "BLIP.h"
#import "Target.h"


@implementation BLIPEchoClient

@synthesize serviceList=_serviceList;

- (void)awakeFromNib 
{
    _serviceBrowser = [[NSNetServiceBrowser alloc] init];
    _serviceList = [[NSMutableArray alloc] init];
    [_serviceBrowser setDelegate:self];
    
    [_serviceBrowser searchForServicesOfType:@"_blipecho._tcp." inDomain:@""];
}

#pragma mark -
#pragma mark NSNetServiceBrowser delegate methods

// We broadcast the willChangeValueForKey: and didChangeValueForKey: for the NSTableView binding to work.

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    if (![_serviceList containsObject:aNetService]) {
        [self willChangeValueForKey:@"serviceList"];
        [_serviceList addObject:aNetService];
        [self didChangeValueForKey:@"serviceList"];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    if ([_serviceList containsObject:aNetService]) {
        [self willChangeValueForKey:@"serviceList"];
        [_serviceList removeObject:aNetService];
        [self didChangeValueForKey:@"serviceList"];
    }
}

#pragma mark -
#pragma mark BLIPConnection support

/* Opens a BLIP connection to the given address. */
- (void)openConnection: (NSNetService*)service 
{
    _connection = [[BLIPConnection alloc] initToNetService: service];
    if( _connection )
        [_connection open];
    else
        NSBeep();
}

/* Closes the currently open BLIP connection. */
- (void)closeConnection
{
    [_connection close];
    [_connection release];
    _connection = nil;
}

#pragma mark -
#pragma mark GUI action methods

- (IBAction)serverClicked:(id)sender {
    NSTableView * table = (NSTableView *)sender;
    int selectedRow = [table selectedRow];
    
    [self closeConnection];
    if (-1 != selectedRow)
        [self openConnection: [_serviceList objectAtIndex:selectedRow]];
}

/* Send a BLIP request containing the string in the textfield */
- (IBAction)sendText:(id)sender 
{
    BLIPRequest *r = [_connection request];
    r.bodyString = [sender stringValue];
    BLIPResponse *response = [r send];
    response.onComplete = $target(self,gotResponse:);
}

/* Receive the response to the BLIP request, and put its contents into the response field */
- (void) gotResponse: (BLIPResponse*)response
{
    [responseField setObjectValue: response.bodyString];
}    


@end

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}
