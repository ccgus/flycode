//  Created by August Mueller on 10/25/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <VPPlugin/VPPlugin.h>
#import <WebKit/WebKit.h>


@interface HTMLToolsPlugin : VPPlugin <VPURLHandler> {
    
    IBOutlet NSWindow *previewWindow;
    IBOutlet WebView *webView;
    IBOutlet NSPopUpButton *formattingSelection;
    
    NSString *previewKey;
    
    id<VPPluginDocument> previewDoc;
}

- (void) updateHTMLPreview:(id)sender;

- (NSString *)previewKey;
- (void)setPreviewKey:(NSString *)newPreviewKey;

- (id<VPPluginDocument>)previewDoc;
- (void)setPreviewDoc:(id<VPPluginDocument>)newPreviewDoc;

@end
