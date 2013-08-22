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

#import "UIColor+Extensions.h"

@implementation UIColor (Extensions)

+ (UIColor*) colorWithRGBString:(NSString*)hex
{
    UIColorRGB rgb = 0x000000;

    @autoreleasepool
    {
        NSUInteger length = hex.length;
        if (0 == length)
            return nil;
        
        unichar theChar = [hex characterAtIndex:0];
        if ('#' == theChar)
        {
            hex = [hex substringFromIndex:1];
            length--;
        }
        else if ('0' == theChar && length > 1)
        {
            theChar = [hex characterAtIndex:1];
            if ('x' == theChar || 'X' == theChar)
            {
                hex = [hex substringFromIndex:2];
                length -= 2;
            }
        }
        
        if (length != 8 && length != 6)
            return nil;

        NSScanner* scanner = [NSScanner scannerWithString:hex];
        NSString*  rgbHex  = nil;
        [scanner scanCharactersFromSet:[NSCharacterSet hexadecimalDigitCharacterSet] intoString:&rgbHex];
        
        if (![rgbHex isEqualToString:hex])
            return nil;

        [scanner setScanLocation:0]; // reset the scanner to the beginning
        [scanner scanHexInt:&rgb];
        
        if (length == 6)
            rgb |= 0xff000000; // no alpha provide, force opaque
    }

    return [self colorWithRGB:rgb];
}

+ (UIColor*) colorWithRGB:(UIColorRGB)hex
{
    unsigned char* hexChars = (unsigned char*)&hex;    
    return [UIColor colorWithRed:(((float)(hexChars[2])) / 255.0f)
                           green:(((float)(hexChars[1])) / 255.0f)
                            blue:(((float)(hexChars[0])) / 255.0f)
                           alpha:(((float)(hexChars[3])) / 255.0f)];
}

@end
