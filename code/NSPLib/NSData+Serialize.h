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

#import <Foundation/Foundation.h>

@interface NSData (Serialize)

/**
    Same as hexStringValueWithDelimeter:everyNBytes: with \a delim as nil and \a nBytes as 0.
    @return a string representing the \c NSData target with hexadecimal characters.  Ex// \c \@"ABCDEF0123456789"
    @see hexStringValueWithDelimeter:everyNBytes:
 */
- (NSString*) hexStringValue;
/**
    Serialize the data into a hex string with a configurable delimiting.
    @param delim the string to delimit chunks of bytes by.  Provide \c nil or an empty string to have no delimiter.
    @param nBytes how many bytes between each delimiter.  Provide \c 0 to have no delimiter.
    @return a string representing the \c NSData target with hexadecimal characters with an optional delimiting string. Ex// \c \@"ABCD EF01 2345 6789" for \c \@" " \a delim and \a nBytes as \c 2
 */
- (NSString*) hexStringValueWithDelimeter:(NSString*)delim everyNBytes:(NSUInteger)nBytes;

@end

@interface NSData (Deserialize)

/**
    Deserialize a hex string into an \c NSData object.
    @param a hex string representation of data.
    @return the data representation of the provided \a hexString
    @note all characters that are not hex characters are ignored - \c "0123456789ABCDEF"
 */
+ (NSData*) dataWithHexString:(NSString*)hexString;
/**
    Initialize an \c NSData object with a hex string.
    @see dataWithHexString:
 */
- (id) initWithHexString:(NSString*)hexString;

@end
