#import <Cocoa/Cocoa.h>

#define debug NSLog

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    
    NSData *rtfdData = [pboard dataForType:NSRTFDPboardType];
    if (!rtfdData) {
        NSLog(@"No rtfd data on the clipboard");
        return 1;
    }
    
    NSAttributedString *contents    = [[[NSAttributedString alloc] initWithRTFD:rtfdData documentAttributes:nil] autorelease];
    
    if (!contents) {
        NSLog(@"Could not make rtfd");
        return 2;
    }
    
    NSInteger length                = [contents length];
    NSRange r;
    NSDictionary *attributes        = [contents attributesAtIndex:0 effectiveRange:&r];
    
    while (r.location + r.length <= length) {
        
        NSTextAttachment *att = [attributes objectForKey:NSAttachmentAttributeName];
        
        if (att) {
            
            NSFileWrapper *wrap = [att fileWrapper];
            
            if ([wrap isRegularFile] && ([[wrap preferredFilename] hasSuffix:@".png"] || [[wrap preferredFilename] hasSuffix:@".tiff"])) {
                
                NSImage *img = [[[NSImage alloc] initWithData:[wrap regularFileContents]] autorelease];
                
                NSData *data = [[[img representations] objectAtIndex:0] representationUsingType:NSJPEGFileType
                                                                       properties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:.7f], NSImageCompressionFactor, nil]];
                
                
                NSFileWrapper *newfw = [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
                
                NSString *newName = [[wrap preferredFilename] stringByDeletingPathExtension];
                
                newName = [NSString stringWithFormat:@"%@.jpg", newName];
                
                [newfw setPreferredFilename:newName];
                
                [att setFileWrapper:newfw];
            }
        }
        
        if (r.location+r.length >= length) {
            break;
        }
        
        attributes = [contents attributesAtIndex:r.location+r.length effectiveRange:&r];
    }
    
    NSData *d = [contents RTFDFromRange:NSMakeRange(0, [contents length]) documentAttributes:nil];
    
    [pboard declareTypes:[NSArray arrayWithObjects:NSRTFDPboardType, nil] owner:nil];
    [pboard setData:d forType:NSRTFDPboardType];
    
    [pool drain];
    
    return 0;
}
