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

#import "UIImage+ASyncRendering.h"

NS_INLINE NSPUIImageType _DetectDataImageType(NSData* imageData);

NS_INLINE NSPUIImageType _DetectDataImageType(NSData* imageData)
{
    if (imageData.length > 4)
    {
        const char* bytes = imageData.bytes;

        if (bytes[0]==0xff && 
            bytes[1]==0xd8 && 
            bytes[2]==0xff &&
            bytes[3]==0xe0)
            return NSPUIImageType_JPEG;

        if (bytes[0]==0x89 &&
            bytes[1]==0x50 &&
            bytes[2]==0x4e &&
            bytes[3]==0x47)
            return NSPUIImageType_PNG;
    }

    return NSPUIImageType_Unknown;
}

@implementation UIImage (ASyncRendering)

+ (void) imageByRenderingData:(NSData*)imageData
                   completion:(UIImageASyncRenderingCompletionBlock)block
{
    return [self imageByRenderingData:imageData ofImageType:NSPUIImageType_Auto completion:block];
}

+ (void) imageByRenderingData:(NSData*)imageData
                  ofImageType:(NSPUIImageType)imageType
                   completion:(UIImageASyncRenderingCompletionBlock)block
{
    static dispatch_queue_t s_imageRenderQ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_imageRenderQ = dispatch_queue_create("UIImage+ASyncRendering_Queue", DISPATCH_QUEUE_SERIAL);
    });

    dispatch_async(s_imageRenderQ, ^() {
        UIImage* imageObj = nil;
        if (imageData)
        {
            STACK_CLEANUP_CGTYPE(CGDataProviderRef) dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
            if (dataProvider)
            {
                STACK_CLEANUP_CGTYPE(CGImageRef) image = NULL;
                if (NSPUIImageType_Auto == imageType)
                    imageType = _DetectDataImageType(imageData);
                
                if (NSPUIImageType_PNG == imageType)
                    image = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
                else
                    image = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
                
                if (image)
                {
                    size_t width = CGImageGetWidth(image);
                    size_t height = CGImageGetHeight(image);
                    STACK_CLEANUP_CMEMORY(unsigned char*) imageBuffer = (unsigned char*)malloc(width*height*4);
                    
                    STACK_CLEANUP_CGTYPE(CGColorSpaceRef) colorSpace = CGColorSpaceCreateDeviceRGB();
                    STACK_CLEANUP_CGTYPE(CGContextRef) imageContext = CGBitmapContextCreate(imageBuffer,
                                                                                           width,
                                                                                           height,
                                                                                           8,
                                                                                           width*4,
                                                                                           colorSpace,
                                                                                           (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little));
                    
                    if (imageContext)
                    {
                        CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), image);
                        STACK_CLEANUP_CGTYPE(CGImageRef) outputImage = CGBitmapContextCreateImage(imageContext);
                        if (outputImage)
                        {
                            imageObj = [UIImage imageWithCGImage:outputImage
                                                           scale:[UIScreen mainScreen].scale
                                                     orientation:UIImageOrientationUp];
                        }
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            block(imageObj);
        });
    });
}

@end
