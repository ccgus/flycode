//  Created by August Mueller on 10/25/04.
//  Copyright 2004 Flying Meat Inc. All rights reserved.
//

#import "HTMLToolsPlugin.h"

#define NO_FORMATTING_SELECTION 0
#define NEWLINE_BR 1
#define TEXTILE  2
#define MARKDOWN 3
#define WIKKA 4

@implementation HTMLToolsPlugin



- (void) didRegister {
    id <VPPluginManager> pluginManager = [self pluginManager];
    
    [pluginManager addPluginsMenuTitle:@"Preview As HTML"
                    withSuperMenuTitle:@"HTML"
                                target:self
                                action:@selector(doHTMLPreview:)
                         keyEquivalent:@"p"
             keyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask];
    
    
    [pluginManager addPluginsMenuTitle:@"Convert Textile"
                    withSuperMenuTitle:@"HTML"
                                target:self
                                action:@selector(doConvertTextile:)
                         keyEquivalent:@""
             keyEquivalentModifierMask:0];
    
    
    [pluginManager addPluginsMenuTitle:@"Convert Markdown"
                    withSuperMenuTitle:@"HTML"
                                target:self
                                action:@selector(doConvertMarkdown:)
                         keyEquivalent:@""
             keyEquivalentModifierMask:0];
             
    [pluginManager addPluginsMenuTitle:@"Copy as HTML"
                    withSuperMenuTitle:@"HTML"
                                target:self
                                action:@selector(doCopyAsHTML:)
                         keyEquivalent:@""
             keyEquivalentModifierMask:0];
             
    [pluginManager addPluginsMenuTitle:@"Copy as Simple HTML"
                    withSuperMenuTitle:@"HTML"
                                target:self
                                action:@selector(doSimpleCopyAsHTML:)
                         keyEquivalent:@""
             keyEquivalentModifierMask:0];
    
    //[pluginManager registerURLHandler:self];
    
    
    [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(updateHTMLPreview:)
                   name:@"documentSave"
                 object:nil];
    
    [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(documentClose:)
                   name:@"documentClose"
                 object:nil];
    
}


- (void) documentClose:(NSNotification *) note {
    
    if ([note object] == previewDoc) {
        previewDoc = nil;
        [previewWindow orderOut:self];
    }
}


- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
    [previewKey autorelease];
    
    previewKey = nil;
    
	[super dealloc];
}


- (NSString *)previewKey {
    return previewKey; 
}

- (void)setPreviewKey:(NSString *)newPreviewKey {
    [newPreviewKey retain];
    [previewKey release];
    previewKey = newPreviewKey;
}

- (id<VPPluginDocument>)previewDoc {
    return previewDoc; 
}

- (void)setPreviewDoc:(id<VPPluginDocument>)newPreviewDoc {
    previewDoc = newPreviewDoc;
}


- (void) doHTMLPreview:(id<VPPluginWindowController>)windowController; {
    
    int flag = [[NSApp currentEvent] modifierFlags];
    if (flag & NSAlternateKeyMask) {
        NSRunAlertPanel(@"Version 1.1", @"", nil, nil, nil);
        return;
    }
    
    if (!previewWindow) {
        [NSBundle loadNibNamed:@"HTMLPreview" owner:self];
    }
    
    [self setPreviewKey:[windowController key]];
    
    [previewWindow setTitle:[NSString stringWithFormat:@"HTML Preview of '%@'", previewKey]];
    
    [self setPreviewDoc:[(NSWindowController*)windowController document]];
    
    [previewWindow makeKeyAndOrderFront:self];
    
    [self updateHTMLPreview:self];
    
}


- (NSString*) textileScriptLocation {
    NSBundle *b = [NSBundle bundleForClass:[self class]];
    return [b pathForResource:@"Textile" ofType:@"pl"];
}

- (NSString*) markdownScriptLocation {
    NSBundle *b = [NSBundle bundleForClass:[self class]];
    return [b pathForResource:@"Markdown" ofType:@"pl"];
}

- (NSString*) wikkaScriptLocation {
    NSBundle *b = [NSBundle bundleForClass:[self class]];
    return [b pathForResource:@"wakkarun" ofType:@"php"];
}

- (NSString*) convertString:(NSString*)markMeUp viaFormatter:(NSString*)scriptLocation {
    
    if (!scriptLocation) {
        return nil;
    }
    
    NSString *tempFile      = @"/tmp/vp_html_tools_temp";
    NSString *htmlFile      = @"/tmp/vp_html_tools_temp.html";
    NSString *html          = nil;
    
    [[markMeUp dataUsingEncoding:NSUTF8StringEncoding] writeToFile:tempFile atomically:NO];
    
    NSTask *t = [NSTask launchedTaskWithLaunchPath:scriptLocation
                                         arguments:[NSArray arrayWithObject:tempFile]];
    
    [t waitUntilExit];
    int status = [t terminationStatus];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (status == 0 && [fileManager fileExistsAtPath:htmlFile]) {
        
        html = [[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:htmlFile] encoding:NSUTF8StringEncoding] autorelease];
    }
    
    return html;
    
}




- (void) updateHTMLPreview:(id)sender {
    
    
    
    if (!previewWindow || (![previewWindow isVisible]) || !previewDoc) {
        // we were never loaded up.. nothing to do.
        return;
    }
    
    if (previewDoc) {
        
        NSMutableString *template       = [NSMutableString string];
        id <VPData>  vpd                = [previewDoc vpDataForKey:previewKey];
        id <VPData>  vphtmltemplate     = [previewDoc vpDataForKey:@"webexportpagetemplate"];
        BOOL gotWebExportPageTemplate   = (vphtmltemplate != nil);
        
        if (!gotWebExportPageTemplate) {
            vphtmltemplate              = [previewDoc vpDataForKey:@"vphtmltemplate"];
        }
        
        if (vphtmltemplate) {
            [template appendString:[[vphtmltemplate dataAsAttributedString] string]];
        }
        else {
            [template appendString:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd\">\n\
    <html>\n\
    <head>\n\
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n\
    </head>\n\
    <body>\n\
    $page$\n\
    </body>\n</html>"];
        }
        
        // FIXME - use some general macro thing here.
        [template replaceOccurrencesOfString:@"$vptitle"  withString:[vpd title] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [template length])];
        
        NSMutableString *vpString = [NSMutableString stringWithString:[[vpd dataAsAttributedString] string]];
        
        if ([formattingSelection indexOfSelectedItem] == NEWLINE_BR) {
            // normalize this string a little bit.
            [vpString replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0, [vpString length])];
            [vpString replaceOccurrencesOfString:@"\r"   withString:@"\n" options:0 range:NSMakeRange(0, [vpString length])];
            
            [vpString insertString:@"<p>" atIndex:0];
            [vpString replaceOccurrencesOfString:@"\n\n"   withString:@"</p><p>" options:0 range:NSMakeRange(0, [vpString length])];
            
            [vpString replaceOccurrencesOfString:@"\n"   withString:@"<br/>" options:0 range:NSMakeRange(0, [vpString length])];
            
            [vpString appendString:@"</p>"];
        }
        else if ([formattingSelection indexOfSelectedItem] == TEXTILE) {
            vpString = [NSMutableString stringWithString:[self convertString:vpString viaFormatter:[self textileScriptLocation]]];
        }
        else if ([formattingSelection indexOfSelectedItem] == MARKDOWN) {
            vpString = [NSMutableString stringWithString:[self convertString:vpString viaFormatter:[self markdownScriptLocation]]];
        }
        else if ([formattingSelection indexOfSelectedItem] == WIKKA) {
            vpString = [NSMutableString stringWithString:[self convertString:vpString viaFormatter:[self wikkaScriptLocation]]];
        }
        
        NSString *docName   = [[previewDoc fileName] lastPathComponent];
        NSString *docTitle  = [docName stringByDeletingPathExtension];
        
        [template replaceOccurrencesOfString:@"$vppage"         withString:vpString options:0 range:NSMakeRange(0, [template length])];
        [template replaceOccurrencesOfString:@"$page$"          withString:vpString options:0 range:NSMakeRange(0, [template length])];
        [template replaceOccurrencesOfString:@"$displayName$"   withString:[vpd displayName] options:0 range:NSMakeRange(0, [template length])];
        [template replaceOccurrencesOfString:@"$documentName$"  withString:docName options:0 range:NSMakeRange(0, [template length])];
        [template replaceOccurrencesOfString:@"$documentTitle$" withString:docTitle options:0 range:NSMakeRange(0, [template length])];
        
        NSString *finalHTML = [template stringByParsingTagsWithStartDelimeter:@"<!--#include page=\"" endDelimeter:@"\" -->" usingObject:previewDoc];
        
        [[webView mainFrame] loadHTMLString:finalHTML baseURL:nil];
    }
}

- (void) doConvert:(id<VPPluginWindowController>)windowController withFormatter:(NSString*)formatter;  {
    
    NSTextView *textView    = [windowController textView];
    NSRange selectedRange   = [textView selectedRange];
    
    if (selectedRange.length == 0) {
        selectedRange = NSMakeRange(0, [[textView textStorage] length]);
    }
    
    NSString *newText = [self convertString:[[[textView textStorage] string] substringWithRange:selectedRange] viaFormatter:formatter];
    
    NSAttributedString *as = [[[NSAttributedString alloc] initWithHTML:[newText dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"UseWebKit"]
                                                    documentAttributes:nil] autorelease];
    
    if (as) {
        [textView fmReplaceCharactersInRange:selectedRange withAttributedString:as];
    }
    else {
        NSBeep();
    }

}
- (void) doConvertMarkdown:(id<VPPluginWindowController>)windowController;  {
    
    [self doConvert:windowController withFormatter:[self markdownScriptLocation]];
}


- (void) doConvertTextile:(id<VPPluginWindowController>)windowController;  {
    
    [self doConvert:windowController withFormatter:[self textileScriptLocation]];
    
}

- (void) doCopyAsHTML:(id<VPPluginWindowController>)windowController;  {
    
    NSTextView *textView = [windowController textView];
    NSAttributedString *stringToCopy = nil;
    
    if ([textView selectedRange].length == 0) {
        stringToCopy = [textView textStorage];
    }
    else {
        stringToCopy = [[textView textStorage] attributedSubstringFromRange:[textView selectedRange]];
    }
    
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    
    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute, nil];
    
    
    NSData *data = [stringToCopy dataFromRange:NSMakeRange(0, [stringToCopy length])
                            documentAttributes:dict
                                         error:nil];
    
    [pb setData:data forType:NSStringPboardType];
    
}

- (void) doSimpleCopyAsHTML:(id<VPPluginWindowController>)windowController;  {
    
    NSTextView *textView = [windowController textView];
    NSAttributedString *stringToCopy = nil;
    
    if ([textView selectedRange].length == 0) {
        stringToCopy = [textView textStorage];
    }
    else {
        stringToCopy = [[textView textStorage] attributedSubstringFromRange:[textView selectedRange]];
    }
    
    
    NSMutableString *htmlString = [NSMutableString string];
    
    int length = [stringToCopy length];
    
    if (length <= 0) {
        return;
    }
    
    NSRange r = NSMakeRange(0, 0);
    
    while (r.location + r.length < length) {
        
        NSDictionary *attributes = [stringToCopy attributesAtIndex:r.location+r.length effectiveRange:&r];
        
        id link = [attributes objectForKey:NSLinkAttributeName];
        
        if (link) {
            link = [link description];
            
            [htmlString appendFormat:@"<a href=\"%@\">%@</a>", link, [[stringToCopy string] substringWithRange:r]];
        }
        else {
            [htmlString appendString:[[stringToCopy string] substringWithRange:r]];
        }
    }
    
    [htmlString replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0, [htmlString length])];
    [htmlString replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0, [htmlString length])];
    [htmlString replaceOccurrencesOfString:@"\n" withString:@"<br/>\n" options:0 range:NSMakeRange(0, [htmlString length])];
    
    
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    
    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    
    [pb setString:htmlString forType:NSStringPboardType];
}

- (BOOL) canHandleURL:(NSString*)url {
    if ([[url lowercaseString] hasPrefix:@"http:"]) {
        return YES;
    }
    
    return NO;
}

- (BOOL) handleURL:(NSString*)url {
    NSString *junk = [NSString stringWithFormat:@"tell app \"Safari\" to open location \"%@\"", url];
    NSAppleScript *as = [[[NSAppleScript alloc] initWithSource:junk] autorelease];
    NSDictionary *err = 0x00;
    
    [as executeAndReturnError:&err];
    
    if (err) {
        NSLog(@"Crap: %@", err);
    }
    
    return YES;
}

- (BOOL) validateAction:(SEL)anAction forPageType:(NSString*)pageType userObject:(id)userObject {
    return YES;
}

@end
