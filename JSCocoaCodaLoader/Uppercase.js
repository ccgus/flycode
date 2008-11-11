codaPluginsController = JSCocoaLoaderPlugIn.codaPluginsController();
var tv = codaPluginsController.focusedTextView(null);
var selectedText = tv.selectedText();

if (selectedText != null) {
    tv.insertText_(selectedText.uppercaseString())
}

// test here.