//
//  SyncViewController.m
//  vpreader
//
//  Created by August Mueller on 1/9/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "SyncViewController.h"
#import "VPReaderAppDelegate.h"
#import "BLIP.h"



id VPPropertyListFromData(NSData *data) {
    
    if (!data) {
        return nil;
    }
    
    NSPropertyListFormat format;
    NSString *err = 0x00;
    
    id o = [NSPropertyListSerialization propertyListFromData:data
                                            mutabilityOption:kCFPropertyListMutableContainersAndLeaves
                                                      format:&format
                                            errorDescription:&err];
    if (err) {
        NSLog(@"Error reading data: %@", err);
    }
    
    return o;
    
}

NSData* VPDataFromPropertyListWithFormat(id propList, NSPropertyListFormat format) {
    
    if (!propList) {
        return nil;
    }
    
    NSString *err = 0x00;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:propList
                                                              format:format
                                                    errorDescription:&err];
    if (err) {
        NSLog(@"Error creating data: %@", err);
    }
    
    return data; 
}


NSData* VPDataFromPropertyList(id propList) {
    return VPDataFromPropertyListWithFormat(propList, NSPropertyListBinaryFormat_v1_0);
}

@interface BLIPRequest (VPExtras)
- (void) respondWithData: (NSData*)data contentType: (NSString*)contentType profile:(NSString*) profile;
@end

@implementation BLIPRequest (VPExtras)

- (void) respondWithData: (NSData*)data contentType: (NSString*)contentType profile:(NSString*) profile {
    
    BLIPResponse *response = self.response;
    response.body = data;
    response.contentType = contentType;
    response.profile = profile;
    
    [response send];
}

@end


@implementation SyncViewController

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:@"Sync"];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [_listener close];
    [_listener release];
    _listener = 0x00;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _listener = [[BLIPListener alloc] initWithPort: 11978];
    _listener.delegate = self;
    _listener.pickAvailablePort = YES;
    _listener.bonjourServiceType = @"_vpiphonesync._tcp";
    [_listener open];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_listener close];
    [_listener release];
    _listener = 0x00;
}



- (NSString *) pathForDocumentOfName:(NSString*)docName {
    
    NSString *documentFolder = [VPReaderAppDelegate documentFolder];
    BOOL isDir = 0x00;
    
    NSString *voodooPadDocumentsDirectory = [documentFolder stringByAppendingPathComponent:docName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:voodooPadDocumentsDirectory isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:voodooPadDocumentsDirectory attributes:nil];
    }
    
    return voodooPadDocumentsDirectory;
}




- (void) listenerDidOpen: (TCPListener*)listener {
    
}

- (void) listener: (TCPListener*)listener failedToOpen: (NSError*)error {
    
}

- (void) listener: (TCPListener*)listener didAcceptConnection: (TCPConnection*)connection {
    //debug(@"Accepted connection from %@", connection.address);
    connection.delegate = self;
}

- (void) connection: (TCPConnection*)connection failedToOpen: (NSError*)error {

}

- (void) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request {
    
    NSString *profile = request.profile;
    
    if ([@"stat" isEqualToString:profile]) {
        
        UIDevice *device = [UIDevice currentDevice];
        NSString *uniqueIdentifier = [device uniqueIdentifier];
        NSString *name = [device name];
        NSString *systemName = [device systemName];
        NSString *systemVersion = [device systemVersion];
        NSString *model = [device model];
        NSString *localizedModel = [device localizedModel];
        
        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:uniqueIdentifier,                              @"uniqueIdentifier",
                                                                     name ? name : @"unknown",                      @"name", 
                                                                     systemName ? systemName : @"unknown",          @"systemName", 
                                                                     systemVersion ? systemVersion : @"unknown",    @"systemVersion", 
                                                                     model ? model : @"unknown",                    @"model", 
                                                                     localizedModel ? localizedModel : @"unknown",  @"localizedModel", 
                                                                     nil];
        
        [request respondWithData:VPDataFromPropertyList(d)
                     contentType:@"binary/plist"
                     profile:@"statResponse"];
    }
    else if ([@"data" isEqualToString:profile]) {
        
        NSData *d = request.body;
        NSString *docName = [request valueOfProperty:@"documentName"];
        NSString *fileName = [request valueOfProperty:@"fileName"];
        
        NSString *docDir = [self pathForDocumentOfName:docName];
        NSString *filePath = [docDir stringByAppendingPathComponent:fileName];
        
        [d writeToURL:[NSURL fileURLWithPath:filePath] atomically:NO];
    }
    else {
        NSString *msg = [NSString stringWithFormat:@"Unknown profile '%@'", profile];
        [request respondWithString:msg];
    }
}

- (void) connectionDidClose: (TCPConnection*)connection {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    //label.text = [NSString stringWithFormat: @"Connection closed from %@", connection.address];
}











@end
