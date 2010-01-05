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
    
    NSString *startPage = [d objectForKey:@"defaultPage"];
    
    startPage = [path stringByAppendingPathComponent:startPage];
    
    debug(@"startPage: %@", startPage);
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:startPage]];
    [webView loadRequest:req];
    
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView {
    backButton.enabled = webView.canGoBack;
    forwardButton.enabled = webView.canGoForward;
}

- (void)webViewDidStartLoad:(UIWebView *)awebView {
    backButton.enabled = webView.canGoBack;
    forwardButton.enabled = webView.canGoForward;
}



- (void) goHome:(id)sender {
    [self loadDocumentDirectory:_documentDirectory];
}

- (void) goToIndex:(id)sender {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    // notice the space.  That's a special page in VP land.
    
    // VoodooPad 4.3 added this (maybe)
    NSString *indexPage = [_documentDirectory stringByAppendingPathComponent:@" index.rtfd.zip"];
    
    debug(@"indexPage: %@", indexPage);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:indexPage]) {
        indexPage = [_documentDirectory stringByAppendingPathComponent:@" index.html"];
    }
    
    debug(@"indexPage: %@", indexPage);
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:indexPage]];
    [webView loadRequest:req];
    
}

- (void) goToDocList:(id)sender {
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    [[self navigationController] popViewControllerAnimated:NO];
}

@end
