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

/**
    A 32-bit representation of an ARGB color.  The hex representation of color is \c 0xAARRGGBB where A is alpha, R is red, G is green and B is blue.
 */
typedef uint32_t UIColorARGB;

/**
    A 32-bit type that uses it's last 24 bits to represent RGB color.  The first byte is ignored and the remaining bytes represent color in the form \c 0xRRGGBB where R is red, G is green and B is blue.
 */
typedef uint32_t UIColorRGB;

@interface UIColor (Extensions)

/** 
    Create a color with a string representing the color as a HEX string.
    @param hexString a string of HEX characters.  \c @"AARRGGBB" will provide create the color with an alpha.  \c @"RRGGBB" will make the color completely opaque.  A prefix of \c @"0x" or \c @"#" are also acceptable.  If the color cannot be parsed, nil will be returned.
 */
+ (UIColor*) colorWithRGBString:(NSString*)hexString;

/**
    Create a color with a 32-bit value.
    @param color32Bits a 32-bit value for creating the color with.  The first 8 bits will be for alpha (use \c 0xFF for fully opaque), the next 3 bytes are red, green and blue respectively.  Example: \c 0xFF123456 is Alpha at full opacity, Red at 0x12, Green at 0x34 and Blue at 0x56.
 */
+ (UIColor*) colorWithARGB:(UIColorARGB)color32Bits;

/**
    Create a color with the last 24 bits of a 32-bit value.
    @param color32Bits a 32-bit value for creating the color with.  The first 8 bits are ignored and the next 3 bytes are red, green and blue respectively.
 */
+ (UIColor*) colorWithRGB:(UIColorRGB)color32Bit;

/**
     Get the UIColorARGB value of the target color.
     @return The UIColorARGB representation of the color.
 */
- (UIColorARGB) argbValue;

/**
    Get the UIColorRGB value of the target color.
    @return The UIColorRGB representation of the color with the first byte set to 0xff and the following 3 bytes representing red, green and blue.
 */
- (UIColorRGB) rgbValue;

@end
