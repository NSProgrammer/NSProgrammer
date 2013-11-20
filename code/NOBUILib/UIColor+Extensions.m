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

#ifndef SLOW_BUT_EASY
#include <objc/message.h>
#endif

@implementation UIColor (Extensions)

+ (UIColor*) colorWithRGBString:(NSString*)hex
{
    UIColorRGB rgb = 0x00000000;
    NSUInteger length = hex.length;
    if (0 == length)
        return nil;

    NSUInteger index = 0;
    unichar theChar = [hex characterAtIndex:index];
    if ('#' == theChar)
    {
        ++index;
        length--;
    }
    else if ('0' == theChar && length > 1)
    {
        theChar = [hex characterAtIndex:++index];
        if ('x' == theChar || 'X' == theChar)
        {
            ++index;
            length -= 2;
        }
    }

    if (length != 8 && length != 6)
        return nil;

#ifdef SLOW_BUT_EASY
    @autoreleasepool
    {
        hex = [hex substringFromIndex:index];
        NSScanner* scanner = [NSScanner scannerWithString:hex];
        NSString*  rgbHex  = nil;
        [scanner scanCharactersFromSet:[NSCharacterSet hexadecimalDigitCharacterSet]
                            intoString:&rgbHex];

        if (![rgbHex isEqualToString:hex])
            return nil;

        [scanner setScanLocation:0]; // reset the scanner to the beginning
        [scanner scanHexInt:&rgb];
    }

    if (length == 6)
    {
        rgb |= 0xff000000; // no alpha provide, force opaque
    }

#else // OPTIMIZED
    unichar buffer[8]; // we need either 6 or 8 characters so use the upper bound for our buffer
    [hex getCharacters:buffer range:NSMakeRange(index, length)];
    if (6 == length)
    {
        rgb = 0xff; // no alpha, force opaque (will be bitshifted over to be 0xffXXXXXX)
    }
    index = 0;
    for (; index < length;)
    {
        rgb <<= 4;
        unichar c = buffer[index++];
        if (!isHexCharacter(c))
            return nil;
        rgb += decimalDigitValueForCharacter(c);
    }
#endif

    return [self colorWithRGB:rgb];
}

#if (BYTE_ORDER == LITTLE_ENDIAN)

#define ACCESS_BYTE(byteArray, index) (byteArray[3-index])

#elif (BYTE_ORDER == BIG_ENDIAN)

#define ACCESS_BYTE(byteArray, index) (byteArray[index])

#else

#error "BYTE_ORDER not supported!"

#endif


+ (UIColor*) colorWithRGB:(UIColorRGB)hex
{
    unsigned char* hexChars = (unsigned char*)&hex;
    return [UIColor colorWithRed:(((float)(ACCESS_BYTE(hexChars, 1))) / 255.0f)
                           green:(((float)(ACCESS_BYTE(hexChars, 2))) / 255.0f)
                            blue:(((float)(ACCESS_BYTE(hexChars, 3))) / 255.0f)
                           alpha:(((float)(ACCESS_BYTE(hexChars, 0))) / 255.0f)];
}

- (UIColorRGB) rgbValue
{
    CGFloat r, g, b, a;
    UIColorRGB rgb;
    unsigned char* rgbChars = (unsigned char*)&rgb;

    [self getRed:&r green:&g blue:&b alpha:&a];

    ACCESS_BYTE(rgbChars, 1) = (unsigned char)MAX(MIN(r * 255.0f, 255.0f), 0);
    ACCESS_BYTE(rgbChars, 2) = (unsigned char)MAX(MIN(g * 255.0f, 255.0f), 0);
    ACCESS_BYTE(rgbChars, 3) = (unsigned char)MAX(MIN(b * 255.0f, 255.0f), 0);
    ACCESS_BYTE(rgbChars, 0) = (unsigned char)MAX(MIN(a * 255.0f, 255.0f), 0);

    return rgb;
}

#undef EXTRACT_BYTE

@end
