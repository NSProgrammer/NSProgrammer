/*
 
 Copyright (C) 2013 Nolan O'Brien
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <UIKit/UIKit.h>

typedef void(^UIImageASyncRenderingCompletionBlock)(UIImage*);

typedef NS_ENUM(NSInteger, NSPUIImageType)
{
    NSPUIImageType_JPEG,
    NSPUIImageType_PNG
};

@interface UIImage (ASyncRendering)

/**
    Renders the provided image data asynchronously so as to not block the main thread.  Very useful when desiring to 
    keep the UI responsive while still generating UI from downloaded and compressed images.
    @param imageData the data to render as a UIImage.
    @param imageType the image type decode the \a imageData as.  Can be \c NSPUIImageType_JPEG or \c NSPUIImageType_PNG.
    @param block the completion block to be called once the \a imageData is rendered as a \c UIImage.
 */
+ (void) imageByRenderingData:(NSData*)imageData
                  ofImageType:(NSPUIImageType)imageType
                   completion:(UIImageASyncRenderingCompletionBlock)block;

@end
