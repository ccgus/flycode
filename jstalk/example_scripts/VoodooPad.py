from Foundation import *
import AppKit

port = "com.flyingmeat.VoodooPad_Pro.JSTalk"

conn = NSConnection.connectionWithRegisteredName_host_(port, None)

vp = conn.rootProxy()

print(vp)

firstDoc = vp.orderedDocuments().objectAtIndex_(0)

for pageKey in firstDoc.keys():
    print(pageKey)
    
    page = firstDoc.pageForKey_(pageKey)
    
    if (page.uti() == "com.fm.page"):
        pageText = page.dataAsAttributedString().string()
        print(pageText)
    



