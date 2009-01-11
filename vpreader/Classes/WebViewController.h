//
//  WebViewController.h
//  vpreader
//
//  Created by August Mueller on 1/9/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebViewController : UIViewController {
    IBOutlet UIWebView *webView;
    
    IBOutlet UIBarButtonItem *backButton;
    IBOutlet UIBarButtonItem *homeButton;
    IBOutlet UIBarButtonItem *forwardButton;
    
    NSString *_documentDirectory;
}
@property (retain) NSString *documentDirectory;

- (void) loadDocumentDirectory:(NSString*)path;

- (void) goHome:(id)sender;
- (void) goToIndex:(id)sender;
- (void) goToDocList:(id)sender;

@end
