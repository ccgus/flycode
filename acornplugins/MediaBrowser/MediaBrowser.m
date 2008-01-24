//
//  MediaBrowser.m
//  MediaBrowser
//
//  Created by August Mueller on 1/22/08.
//  Copyright Flying Meat Inc 2008 . All rights reserved.
//

#import "MediaBrowser.h"
#import <iMediaBrowser/iMediaBrowser.h>
#import <CoreServices/CoreServices.h>

#define MAGIC_WINDOW_TAG 29302

@implementation MediaBrowser

+ (id) plugin {
    return [[self alloc] init];
}

- (void) willRegister:(id<ACPluginManager>)pluginManager {
    
}

- (void) didRegister {
    
    NSMenuItem *windowMenu = nil;
    for (windowMenu in [[NSApp mainMenu] itemArray]) {
        
        if ([windowMenu tag] == MAGIC_WINDOW_TAG) {
            break;
        }
    }
    
    if (!windowMenu) {
        NSLog(@"Could not find window menu");
        return;
    }
    
    int idx = 0;
    NSMenuItem *fontMenu = nil;
    for (fontMenu in [[windowMenu submenu] itemArray]) {
        
        idx++;
        if ([fontMenu action] == @selector(orderFrontFontPanel:)) {
            break;
        }
    }
    
    if (!fontMenu) {
        NSLog(@"Could not find fontMenu menu");
        return;
    }
    
    
    NSString *name = NSLocalizedString(@"Media Browser",  @"Media Browser");
    
    NSMenuItem *myMenu = [[windowMenu submenu] insertItemWithTitle:name
                                                            action:@selector(bringUpMediaBrowser:)
                                                     keyEquivalent:@""
                                                           atIndex:idx];
    [myMenu setTarget:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaSelectionDidChange:)
                                                 name:iMediaBrowserSelectionDidChangeNotification
                                               object:nil];
}

- (NSString*) resolveFinderAlias:(NSString*)path {
    CFURLRef	tempURL = NULL;
    FSRef		ref;
    Boolean     targetIsFolder;
    Boolean     wasAliased;
    
    tempURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, false);
    CFURLGetFSRef(tempURL, &ref);
    CFRelease(tempURL);
    
    FSResolveAliasFile(&ref, YES, &targetIsFolder, &wasAliased);
    
    tempURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &ref);
    
    path = [(id)CFURLCopyFileSystemPath(tempURL, kCFURLPOSIXPathStyle) autorelease];
    
    CFRelease(tempURL);
    
    return path;
}

- (void) bringUpMediaBrowser:(id)sender {
    [[iMediaBrowser sharedBrowserWithDelegate:self] showWindow:self];
}

- (BOOL)iMediaBrowser:(iMediaBrowser *)browser willLoadBrowser:(NSString *)browserClassname {
    return [browserClassname isEqualToString:@"iMBPhotosController"];
}

- (void) mediaSelectionDidChange:(NSNotification*)note {
    
    if ([[NSApp currentEvent] clickCount] < 2) {
        return;
    }
    
    NSDictionary *info = [note userInfo];
    NSArray *selectedObjects = [info objectForKey:@"Selection"];
    
    NSEnumerator *e  = [selectedObjects objectEnumerator];
    NSDictionary *d ;
    while ((d = [e nextObject])) {
        
        NSString *path = [d objectForKey:@"ImagePath"];
                
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[self resolveFinderAlias:path] display:YES];
    }
    
}


- (NSNumber*) worksOnShapeLayers:(id)userObject {
    return [NSNumber numberWithBool:YES];
}

@end
