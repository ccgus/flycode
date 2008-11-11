#import <Cocoa/Cocoa.h>

// 
// This object is passed during initialization. You must register your
// available functionality with one of the methods implemented by the 
// plug-in controller
//

@class CodaTextView;

@interface CodaPlugInsController : NSObject 
{
	NSMutableArray*			plugins;
	NSMutableDictionary*	loadedMenuItemsDict;
}

// The following methods are available to plugin developers
// in Coda 1.0.4 and later:

- (NSString*)codaVersion:(id)sender;

// codaVersion returns the version of Coda that is hosting the plugin,
// such as "1.0.4"

- (void)registerActionWithTitle:(NSString*)title target:(id)target selector:(SEL)selector;

// registerActionWithTitle:target:selector: exposes to the user a plugin action (a menu item)
// with the given title, that will perform the given selector on the target

- (CodaTextView*)focusedTextView:(id)sender;

// focusedTextView returns to the plugin an abstract object representing the text view
// in Coda that currently has focus

// ###
// The following methods are available to plugin developers
// in Coda 1.5.2 and later:

- (int)apiVersion;

// apiVersion returns 2 as of Coda 1.5.2.  It does not exist in previous versions.

- (void)displayHTMLString:(NSString*)html;

- (void)registerActionWithTitle:(NSString*)title
		  underSubmenuWithTitle:(NSString*)submenuTitle
						 target:(id)target
					   selector:(SEL)selector
			  representedObject:(id)repOb
				  keyEquivalent:(NSString*)keyEquivalent
					 pluginName:(NSString*)aName;

- (void)saveAll;

@end


// 
// This is your hook to a text view in Coda. You can use this to provide 
// manipulation of files.
//

@class StudioPlainTextEditor;

@interface CodaTextView : NSObject
{
	StudioPlainTextEditor* editor;
}

// The following methods are available to plugin developers
// in Coda 1.0.4 and later:

- (void)insertText:(NSString*)inText;

// insertText: inserts the given string at the insertion point

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;

// replaces characters in the given range with the given string

- (NSRange)selectedRange;

// selectedRange returns the range of currently selected characters

- (NSString*)selectedText;

// selectedText returns the currently selected text, or nil if none

- (void)setSelectedRange:(NSRange)range;

// setSelectedRange: selects the given character range

// The following methods are available to plugin developers
// in Coda 1.5.2 and later:

- (NSString*)currentLine;

// currentLine returns a string containing the entire content of the
// line that the insertion point is on

- (unsigned int)currentLineNumber;

// currentLineNumber returns the line number corresponding to the 
// location of the insertion point

- (void)deleteSelection;

// deleteSelection deletes the selected text range

- (NSString*)lineEnding;

// lineEnding returns the current line ending of the file

- (NSRange)rangeOfCurrentLine;

// Returns the character range of the entire line the insertion point
// is on

- (unsigned int)startOfLine;

// startOfLine returns the character index (relative to the beginning of the document)
// of the start of the line the insertion point is on

- (NSString*)string;

// string returns the entire document as a plain string

- (NSString*)stringWithRange:(NSRange)range;

// stringWithRange: returns the specified ranged substring of the entire document

- (int)tabWidth;

//tabWidth: returns the width of tabs as spaces

- (NSRange)previousWordRange;

// previousWordRange: returns the range of the word previous to the insertion point

- (BOOL)usesTabs;

// usesTabs returns if the editor is currently uses tabs instead of spaces for indentation

- (void)save;

// saves the document you are working on

- (void)beginUndoGrouping;
- (void)endUndoGrouping;

// allows for multiple text manipulations to be considered one "undo/redo"
// operation

- (NSWindow*)window;

// returns the window the editor is located in (useful for showing sheets)

// - (NSString*)path; - Coming in the next beta

// returns the path to the text view's file (may be nil for unsaved documents)

@end


// 
// Your plug-in must conform to this protocol
//

@protocol CodaPlugIn

- (id)initWithPlugInController:(CodaPlugInsController*)aController bundle:(NSBundle*)yourBundle;
- (NSString*)name;

@end




