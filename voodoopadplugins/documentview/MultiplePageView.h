#import <Cocoa/Cocoa.h>

@interface MultiplePageView : NSView {
    NSPrintInfo *printInfo;
    NSColor *lineColor;
    NSColor *marginColor;
    int numPages;
}

- (void)setPrintInfo:(NSPrintInfo *)anObject;
- (NSPrintInfo *)printInfo;
- (float)pageSeparatorHeight;
- (NSSize)documentSizeInPage;	/* Returns the area where the document can draw */
- (NSRect)documentRectForPageNumber:(int)pageNumber;	/* First page is page 0 */
- (NSRect)pageRectForPageNumber:(int)pageNumber;	/* First page is page 0 */
- (void)setNumberOfPages:(int)num;
- (int)numberOfPages;
- (void)setLineColor:(NSColor *)color;
- (NSColor *)lineColor;
- (void)setMarginColor:(NSColor *)color;
- (NSColor *)marginColor;

@end
