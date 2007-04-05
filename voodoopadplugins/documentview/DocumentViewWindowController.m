//
//  DocumentViewWindowController.m
//  DocumentView
//
//  Created by August Mueller on 4/5/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import "DocumentViewWindowController.h"
#import "MultiplePageView.h"


@implementation DocumentViewWindowController


- (id) initWithWindowNibName:(NSString*)windowNibName {
    if ((self = [super initWithWindowNibName:windowNibName])) {
        layoutMgr = [[NSLayoutManager allocWithZone:[self zone]] init];
        [layoutMgr setDelegate:self];
                
        textStorage = [[NSTextStorage alloc] init];
        
        [textStorage addLayoutManager:layoutMgr];
        
    }
    return self;
}

- (NSLayoutManager *)layoutManager {
    return layoutMgr;
}

- (NSTextView *)firstTextView {
    return [[self layoutManager] firstTextView];
}

- (int)numberOfPages {
    return [[scrollView documentView] numberOfPages];
}

- (void)addPage {
    NSZone *zone                = [self zone];
    int numberOfPages    = [self numberOfPages];
    MultiplePageView *pagesView = [scrollView documentView];
    
    NSSize textSize = [pagesView documentSizeInPage];
    
    NSTextContainer *textContainer = [[NSTextContainer allocWithZone:zone] initWithContainerSize:textSize];
    NSTextView *textView;
    [pagesView setNumberOfPages:numberOfPages + 1];
    textView = [[NSTextView allocWithZone:zone] initWithFrame:[pagesView documentRectForPageNumber:numberOfPages] textContainer:textContainer];
    [textView setHorizontallyResizable:NO];
    [textView setVerticallyResizable:NO];
    [pagesView addSubview:textView];
    [[self layoutManager] addTextContainer:textContainer];
    [textView release];
    [textContainer release];
}
- (void)removePage {
    int numberOfPages = [self numberOfPages];
    NSArray *textContainers = [[self layoutManager] textContainers];
    NSTextContainer *lastContainer = [textContainers objectAtIndex:[textContainers count] - 1];
    MultiplePageView *pagesView = [scrollView documentView];
    
    [pagesView setNumberOfPages:numberOfPages - 1];
    [[lastContainer textView] removeFromSuperview];
    [[lastContainer layoutManager] removeTextContainerAtIndex:[textContainers count] - 1];
}


- (void) loadAttributedString:(NSAttributedString*) ats {
    
    // force awake from nib.
    [[self window] center];
    
    MultiplePageView *pagesView = [[MultiplePageView alloc] init];
	
    [scrollView setDocumentView:pagesView];
    
    [self addPage];
    
    [[self firstTextView] setEditable:YES];
    [[self firstTextView] insertText:ats];
    [[self firstTextView] setEditable:NO];
        
    [[scrollView window] makeFirstResponder:[self firstTextView]];
    [[scrollView window] setInitialFirstResponder:[self firstTextView]];	// So focus won't be stolen (2934918)
    
    [pagesView scrollRectToVisible:NSZeroRect];
}

- (void)doForegroundLayoutToCharacterIndex:(int)loc {
    int len;
    if (loc > 0 && (len = [textStorage length]) > 0) {
        NSRange glyphRange;
        if (loc >= len) loc = len - 1;
        /* Find out which glyph index the desired character index corresponds to */
        glyphRange = [[self layoutManager] glyphRangeForCharacterRange:NSMakeRange(loc, 1) actualCharacterRange:NULL];
        if (glyphRange.location > 0) {
            /* Now cause layout by asking a question which has to determine where the glyph is */
            (void)[[self layoutManager] textContainerForGlyphAtIndex:glyphRange.location - 1 effectiveRange:NULL];
        }
    }
}

- (void) printDocument:(id)sender {
    
    NSMutableDictionary *printInfoDict = [NSMutableDictionary dictionary];
    [printInfoDict setObject:NSPrintSaveJob 
                      forKey:NSPrintJobDisposition];
    
    NSPrintInfo *printInfo = [[[NSPrintInfo alloc] initWithDictionary: printInfoDict] autorelease];
    
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:[scrollView documentView] printInfo:printInfo];
    [op setShowPanels:YES];
        
    [self doForegroundLayoutToCharacterIndex:LONG_MAX];	// Make sure the whole document is laid out before printing
    
    [op runOperation];
}

- (void)layoutManager:(NSLayoutManager *)layoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)textContainer atEnd:(BOOL)layoutFinishedFlag {

    NSArray *containers = [layoutManager textContainers];
    
    if (!layoutFinishedFlag || (textContainer == nil)) {
        // Either layout is not finished or it is but there are glyphs laid nowhere.
        NSTextContainer *lastContainer = [containers lastObject];
        
        if ((textContainer == lastContainer) || (textContainer == nil)) {
            // Add a new page if the newly full container is the last container or the nowhere container.
            // Do this only if there are glyphs laid in the last container (temporary solution for 3729692, until AppKit makes something better available.)
            if ([layoutManager glyphRangeForTextContainer:lastContainer].length > 0) [self addPage];
        }
    } else {
        // Layout is done and it all fit.  See if we can axe some pages.
        int lastUsedContainerIndex = [containers indexOfObjectIdenticalTo:textContainer];
        int numContainers = [containers count];
        while (++lastUsedContainerIndex < numContainers) {
            [self removePage];
        }
    }

}

@end
