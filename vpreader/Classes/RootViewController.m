//
//  RootViewController.m
//  vpreader
//
//  Created by August Mueller on 1/9/09.
//  Copyright Flying Meat Inc 2009. All rights reserved.
//

#import "RootViewController.h"
#import "VPReaderAppDelegate.h"
#import "VPReaderAppDelegate.h"

@implementation RootViewController
@synthesize syncViewController;
@synthesize webViewController;
@synthesize documentNames=_documentNames;

- (void)viewDidLoad {
    [super viewDidLoad];
    
        
    UIBarButtonItem *syncButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Sync", @"Sync")
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(addDocument:)] autorelease];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem = syncButton;
    
    self.title = NSLocalizedString(@"Documents", @"Documents");
}


- (void) addDocument:(id)sender {
    
    _hasLoadedSyncViewOnce = YES;
    
    if (!syncViewController) {
        self.syncViewController = [[[SyncViewController alloc] initWithNibName:@"SyncViewController" bundle:[NSBundle mainBundle]] autorelease];
    }
    
    [[self navigationController] pushViewController:syncViewController animated:YES];
    
}

- (void) updateDocumentList {
    
    NSString *documentFolder = [VPReaderAppDelegate documentFolder];
    
    _documentNames = [[NSMutableArray array] retain];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *folders = [fm contentsOfDirectoryAtPath:documentFolder error:nil];
    
    for (NSString *docName in [folders sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        if ([docName hasPrefix:@"."]) {
            continue;
        }
        
        [_documentNames addObject:docName];
    }
    
    
    [self.tableView reloadData];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateDocumentList];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];
    if (![_documentNames count] && !_hasLoadedSyncViewOnce) {
        [self addDocument:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_documentNames count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
    
    cell.text = [_documentNames objectAtIndex:indexPath.row];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
    
    NSString *vpFolder = [[VPReaderAppDelegate documentFolder] stringByAppendingPathComponent:[_documentNames objectAtIndex:indexPath.row]];
    
    BOOL shouldLoad = NO;
    
    if (!webViewController || ![webViewController.documentDirectory isEqualToString:vpFolder]) {
        self.webViewController = [[[WebViewController alloc] initWithNibName:@"WebViewController" bundle:[NSBundle mainBundle]] autorelease];
        shouldLoad = YES;
    }
    
    [[self navigationController] pushViewController:webViewController animated:NO];
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    
    if (shouldLoad) {
        [webViewController loadView];
        [webViewController loadDocumentDirectory:vpFolder];
    }
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *docName = [_documentNames objectAtIndex:indexPath.row];
    
    if ([[NSFileManager defaultManager] removeItemAtPath:[[VPReaderAppDelegate documentFolder] stringByAppendingPathComponent:docName] error:nil]) {
        [_documentNames removeObjectAtIndex:indexPath.row];
    }
    
    [tableView reloadData];
}

- (void)dealloc {
    [super dealloc];
}


@end

