

data            = objc.class("NSData"):dataWithContentsOfFile(LCLuaRunFileDirectory .. "/stevie.png")
imageSourceRef  = CGImageSourceCreateWithData(data, nil)
imageRef        = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, nil)

context = CGBitmapContextCreate(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef))

CGContextSaveGState(context);

-- flip the context
CGContextTranslateCTM( context, 0, CGImageGetHeight(imageRef))
CGContextScaleCTM(context, 1.0, -1.0 )

CGContextDrawImage(context, {0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)}, imageRef)

CGContextRestoreGState(context);

CGImageRelease(imageRef);
CFRelease(imageSourceRef);

newImage = CGBitmapContextCreateImage(context)

mutableData = objc.class("NSMutableData"):data()

imageDestination = CGImageDestinationCreateWithData(mutableData, "public.tiff", 1, nil);

CGImageDestinationAddImage(imageDestination, newImage, nil);
CGImageDestinationFinalize(imageDestination);

CGImageRelease(newImage)
CFRelease(imageDestination)

CGBitmapContextRelease(context)

mutableData:writeToFile_atomically_("/tmp/bob.tiff", true)

-- os.execute("/usr/bin/open /tmp/bob.tiff")
