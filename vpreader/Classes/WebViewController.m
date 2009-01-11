//
//  WebViewController.m
//  vpreader
//
//  Created by August Mueller on 1/9/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "WebViewController.h"


@implementation WebViewController
@synthesize documentDirectory=_documentDirectory;

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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void) loadDocumentDirectory:(NSString*)path {
    
    debug(@"path: %@", path);
    
    self.documentDirectory = path;
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"docinfo.plist"]];
    
    debug(@"d: %@", d);
    
    NSString *startPage = [d objectForKey:@"defaultPage"];
    
    startPage = [path stringByAppendingPathComponent:startPage];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:startPage]];
    [webView loadRequest:req];
    
}

- (void)dealloc {
    [super dealloc];
}


@end
