#import "gbhack.h"

@implementation gbhack

+ (void) load {
	[self performSelector:@selector(install:) withObject:nil afterDelay:0.0];
}


+ (void)install:(id)sender {
    
    NSMenu *mainMenu    = nil;
    
    NSString *bundleId  = [[NSBundle mainBundle] bundleIdentifier];
    
    if (!(mainMenu = [NSApp mainMenu])) {
		return;
    }
    
    if ([@"com.apple.garageband" isEqualToString:bundleId]) {
        NSMenuItem *editMenu = [mainMenu itemWithTitle:@"Edit"];
        NSMenuItem *sep = [NSMenuItem separatorItem];
        [[editMenu submenu] addItem: sep];
        
        NSMenuItem *gbCommand = [[editMenu submenu] addItemWithTitle:@"Open Video in Window" action:@selector(gbVideo:) keyEquivalent:@"'"];
        [gbCommand setKeyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask];
    }
}

@end

