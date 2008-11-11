#import "JSCocoaLoaderPlugIn.h"
#import "CodaPlugInsController.h"
#import "JSCocoaController.h"

/// ooooh, a hack!
static CodaPlugInsController *JSCocoaLoaderPlugInCodaPlugInsController;

@implementation JSCocoaLoaderPlugIn

- (id)initWithPlugInController:(CodaPlugInsController*)inController bundle:(NSBundle*)aBundle
{
	if ( (self = [super init]) != nil ) {
		controller = inController;
        JSCocoaLoaderPlugInCodaPlugInsController = controller;
        [self findJSCocoaScripts];
	}
    
	return self;
}

+ (CodaPlugInsController *) codaPluginsController {
    return JSCocoaLoaderPlugInCodaPlugInsController;
}

- (NSString*)name {
	return @"JSCocoa";
}

- (void) execute:(id)sender {
    
    NSString *path = [sender representedObject];
    
    NSError *err            = 0x00;
    NSString *pathContents  = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
	id c = [JSCocoaController sharedController];
    
	[c evalJSString:pathContents];
    
}

- (void) findJSCocoaScripts {
    
    NSString *pluginDir = [@"~/Library/Application Support/Coda/JSPlug-ins/" stringByExpandingTildeInPath];
    NSFileManager *fm   = [NSFileManager defaultManager];
    BOOL isDir          = NO;
    
    if (!([fm fileExistsAtPath:pluginDir isDirectory:&isDir] && isDir)) {
        return;
    }
    
    for (NSString *fileName in [fm contentsOfDirectoryAtPath:pluginDir error:nil]) {
        
        if (![fileName hasSuffix:@".js"]) {
            continue;
        }
        
        [controller registerActionWithTitle:[fileName stringByDeletingPathExtension]
                      underSubmenuWithTitle:nil
                                     target:self
                                   selector:@selector(execute:)
                          representedObject:[pluginDir stringByAppendingPathComponent:fileName]
                              keyEquivalent:@""
                                 pluginName:[fileName stringByDeletingPathExtension]];
    }
}

@end
