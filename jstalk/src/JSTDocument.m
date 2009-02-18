//
//  JSTDocument.m
//  JSTalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright Flying Meat Inc 2009 . All rights reserved.
//

#import "JSTDocument.h"
#import "JSTListener.h"
#import "JSTalk.h"
#import "JSCocoaController.h"
#import "JSTPreprocessor.h"


@implementation JSTDocument
@synthesize tokenizer=_tokenizer;
@synthesize keywords=_keywords;

- (id)init {
    self = [super init];
    if (self) {
        self.tokenizer = [[[TDTokenizer alloc] init] autorelease];
        
        self.keywords = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSColor blueColor], @"for",
                         [NSColor blueColor], @"print",
                         [NSColor blueColor], @"var",
                         [NSColor blueColor], @"function",
                         [NSColor blueColor], @"return",
                         [NSColor blueColor], @"if",
                         [NSColor blueColor], @"null",
                         [NSColor blueColor], @"nil",
                         [NSColor blueColor], @"class",
                         [NSColor blueColor], @"true",
                         [NSColor blueColor], @"false",
                         [NSColor blueColor], @"short",
                         [NSColor blueColor], @"static",
                         [NSColor blueColor], @"super",
                         [NSColor blueColor], @"new",
                         nil];
    }
    
    NSString *someContent = @"Hello World!";
    NSString *path = @"/tmp/foo.txt";
    [[someContent dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
    
    
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_tokenizer release];
    _tokenizer = 0x00;
    
    [_keywords release];
    _keywords = 0x00;
    
    [super dealloc];
}


- (NSString *)windowNibName {
    return @"JSTDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
    
    if ([self fileURL]) {
        
        NSError *err = 0x00;
        NSString *src = [NSString stringWithContentsOfURL:[self fileURL] encoding:NSUTF8StringEncoding error:&err];
        
        if (err) {
            NSBeep();
            NSLog(@"err: %@", err);
        }
        
        if (src) {
            [[[jsTextView textStorage] mutableString] setString:src];
        }
        
        [[aController window] setFrameAutosaveName:[self fileName]];
        [splitView setAutosaveName:[self fileName]];
    }
    
    lineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:[jsTextView enclosingScrollView]];
    [[jsTextView enclosingScrollView] setVerticalRulerView:lineNumberView];
    [[jsTextView enclosingScrollView] setHasHorizontalRuler:NO];
    [[jsTextView enclosingScrollView] setHasVerticalRuler:YES];
    [[jsTextView enclosingScrollView] setRulersVisible:YES];
    
    [outputTextView setTypingAttributes:[jsTextView typingAttributes]];
    
    [[jsTextView textStorage] setDelegate:self];
    [self parseCode:nil];
    
    NSToolbar *toolbar  = [[[NSToolbar alloc] initWithIdentifier:@"JSTalkDocument"] autorelease];
    _toolbarItems       = [[NSMutableDictionary dictionary] retain];
    
    JSTAddToolbarItem(_toolbarItems, @"Run", @"Run", @"Run", @"Run the script", nil, @selector(setImage:), [NSImage imageNamed:@"Play.tiff"], @selector(executeScript:), nil);
    JSTAddToolbarItem(_toolbarItems, @"Clear", @"Clear", @"Clear", @"Clear the console", nil, @selector(setImage:), [NSImage imageNamed:@"Clear.tiff"], @selector(clearConsole:), nil);
    
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    
    [[splitView window] setToolbar:toolbar];
    
    [[splitView window] setContentBorderThickness:NSMinY([splitView frame]) forEdge:NSMinYEdge];
    
    [errorLabel setStringValue:@""];
    
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    
    NSData *d = [[[jsTextView textStorage] string] dataUsingEncoding:NSUTF8StringEncoding];
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    
	return d;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    
    return YES;
}

- (void) print:(NSString*)s {
    [[[outputTextView textStorage] mutableString] appendFormat:@"%@\n", s];
}

- (void) jscontroller:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber {
    
    lineNumber -= 1;
    
    if (!error) {
        return;
    }
    
    if (lineNumber < 0) {
        [errorLabel setStringValue:error];
    }
    else {
        [errorLabel setStringValue:[NSString stringWithFormat:@"Line %d, %@", lineNumber, error]];
        
        NSUInteger lineIdx = 0;
        NSRange lineRange  = NSMakeRange(0, 0);
        
        while (lineIdx < lineNumber) {
            
            lineRange = [[[jsTextView textStorage] string] lineRangeForRange:NSMakeRange(NSMaxRange(lineRange), 0)];
            lineIdx++;
        }
        
        if (lineRange.length) {
            [jsTextView showFindIndicatorForRange:lineRange];
        }
    }
}

- (void) runScript:(NSString*)s {
    
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    JSCocoaController *jsController = [jstalk jsController];
    
    #warning fixme
    jsController.exceptionHandler = self;
    
    [jstalk pushObject:self withName:@"_jstDocument" inController:jsController];
    
    jstalk.printController = self;
    
    [errorLabel setStringValue:@""];
    
    [jstalk executeString:s];
}

- (void) executeScript:(id)sender { 
    [self runScript:[[jsTextView textStorage] string]];
}

- (void) clearConsole:(id)sender { 
    [[[outputTextView textStorage] mutableString] setString:@""];
}

- (void) executeSelectedScript:(id)sender {
    
    NSRange r = [jsTextView selectedRange];
    
    if (r.length == 0) {
        r = NSMakeRange(0, [[jsTextView textStorage] length]);
    }
    
    NSString *s = [[[jsTextView textStorage] string] substringWithRange:r];
    
    [self runScript:s];
    
}

- (void) textStorageDidProcessEditing:(NSNotification *)note {
    [self parseCode:nil];
}

- (void) preprocessCodeAction:(id)sender {
    
    NSString *code = [JSTPreprocessor preprocessCode:[[jsTextView textStorage] string]];
    
    debug(@"code: %@", code);
}

- (void) parseCode:(id)sender {
    
    // we should really do substrings...
    
    NSString *sourceString = [[jsTextView textStorage] string];
    TDTokenizer *tokenizer = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.commentState.reportsCommentTokens = YES;
    tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    
    TDToken *eof = [TDToken EOFToken];
    TDToken *tok = nil;
    
    [[jsTextView textStorage] beginEditing];
    
    NSUInteger sourceLoc = 0;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        NSColor *fontColor = [NSColor blackColor];
    
        if (tok.quotedString) {
            fontColor = [NSColor darkGrayColor];
        }
        else if (tok.isNumber) {
            fontColor = [NSColor blueColor];
        }
        else if (tok.isComment) {
            fontColor = [NSColor redColor];
        }
        else if (tok.isWord) {
            NSColor *c = [_keywords objectForKey:[tok stringValue]];
            fontColor = c ? c : fontColor;
        }
            
        NSUInteger strLen = [[tok stringValue] length];
        
        if (fontColor) {
            [[jsTextView textStorage] addAttribute:NSForegroundColorAttributeName value:fontColor range:NSMakeRange(sourceLoc, strLen)];
        }
        
        sourceLoc += strLen;
    }
    
    
    [[jsTextView textStorage] endEditing];
    
}




- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier 
 willBeInsertedIntoToolbar:(BOOL)flag {
    
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem  = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    NSToolbarItem *item     = [_toolbarItems objectForKey:itemIdentifier];
    
    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=NULL) {
        [newItem setView:[item view]];
    }
    else {
        [newItem setImage:[item image]];
    }
    
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=NULL){
    	[newItem setMinSize:[[item view] bounds].size];
        [newItem setMaxSize:[[item view] bounds].size];
    }
    
    return newItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects: @"Run", @"Clear", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects: @"Run", @"Clear", NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier, NSToolbarPrintItemIdentifier, nil];

}


@end



NSToolbarItem *JSTAddToolbarItem(NSMutableDictionary *theDict,
                              NSString *identifier,
                              NSString *label,
                              NSString *paletteLabel,
                              NSString *toolTip,
                              id target,
                              SEL settingSelector,
                              id itemContent,
                              SEL action, 
                              NSMenu * menu)
{
    NSMenuItem *mItem;
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
    // we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
    // so we create a dummy NSMenuItem that has our real menu as a submenu.
    if (menu!=NULL) {
        // we actually need an NSMenuItem here, so we construct one
        mItem=[[[NSMenuItem alloc] init] autorelease];
        [mItem setSubmenu: menu];
        [mItem setTitle:[menu title]];
        [item setMenuFormRepresentation:mItem];
    }
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
    
    return item;
}





