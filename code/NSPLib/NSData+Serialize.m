//
//  NSData+Serialize.m
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSData+Serialize.h"
#import "NSPObjCUtils.h"
#import "NSPStringUtils.h"
#include <objc/message.h>

// can change the base char to be 'a' for lowercase hex strings
#define HEX_ALPHA_BASE_CHAR 'A'

NS_INLINE void byteToHexComponents(unsigned char byte, unichar* pBig, unichar* pLil);
NS_INLINE void byteToHexComponents(unsigned char byte, unichar* pBig, unichar* pLil)
{
    assert(pBig && pLil);
    unsigned char c = byte / 16;
    if (c < 10)
        c += '0';
    else
        c += HEX_ALPHA_BASE_CHAR - 10;

    *pBig = c;
    c     = byte % 16;
    if (c < 10)
        c += '0';
    else
        c += HEX_ALPHA_BASE_CHAR - 10;

    *pLil = c;
}

@implementation NSData (Serialize)

- (NSString*) hexStringValue
{
    return [self hexStringValueWithDelimeter:nil everyNBytes:0]; // no delimeter
}

- (NSString*) hexStringValueWithDelimeter:(NSString*)delim everyNBytes:(NSUInteger)nBytes
{
    NSUInteger     len       = self.length;
    NSUInteger     newLength = 0;
    BOOL           doDelim   = nBytes > 0 && delim.length > 0;
    if (doDelim)
    {
        newLength = (len / nBytes) * delim.length;
        if ((len % nBytes) == 0 && newLength > 0)
            newLength -= delim.length;
    }

    newLength += len*2; // each byte turns into 2 HEX chars

    unichar*       hexChars    = (unichar*)malloc(sizeof(unichar) * newLength);
    unichar*       hexCharsPtr = hexChars;
    unsigned char* bytes       = (unsigned char*)self.bytes;

    // By pulling out the implementation of getCharacters:range: for reuse, we optimize out the ObjC class hierarchy traversal for the implementation while in our loop
    SEL            getCharsSel = @selector(getCharacters:range:);
    IMP            getCharsImp = [delim methodForSelector:getCharsSel];
    NSRange        getCharsRng = NSMakeRange(0, delim.length);
    for (NSUInteger i = 0; i < len; i++)
    {
        if (doDelim && (i > 0) && (i % nBytes == 0))
        {
            getCharsImp(delim, getCharsSel, hexCharsPtr, getCharsRng);
            hexCharsPtr += getCharsRng.length;
        }

        byteToHexComponents(bytes[i], hexCharsPtr, hexCharsPtr+1);
        hexCharsPtr += 2;
    }

    assert(hexCharsPtr - newLength == hexChars);
    return [[NSString alloc] initWithCharactersNoCopy:hexChars
                                               length:newLength
                                         freeWhenDone:YES];
}

@end

@implementation NSData (Deserialize)

+ (NSData*) dataWithHexString:(NSString*)hexString
{
    return [[NSData alloc] initWithHexString:hexString];
}

- (id) initWithHexString:(NSString*)hexString
{
    size_t dataBytesLength = hexString.length;
    dataBytesLength = (dataBytesLength / 2) + (dataBytesLength % 2); // max possible bytes
    char* dataBytes = (char*)malloc(dataBytesLength);
    NSInteger length = hexString.length;
    unichar   c;
    char      byte;
    BOOL      hasSmallHalf = NO;
    char*     pByte = dataBytes;
    pByte += dataBytesLength;

    EXTRACT_FUNCTION_POINTER(hexString, @selector(characterAtIndex:), cai, unichar, NSUInteger)

    for (NSInteger i = length-1; i >= 0 ; i--)
    {
        c = caiFP(hexString, caiSEL, i);
        if (isHexCharacter(c))
        {
            if (!hasSmallHalf)
            {
                byte = decimalDigitValueForCharacter(c);
            }
            else
            {
                byte |= decimalDigitValueForCharacter(c) << 4;
                pByte--;
                NSPAssert(pByte >= dataBytes);
                *pByte = byte;
            }
            hasSmallHalf = !hasSmallHalf;
        }
    }

    if (hasSmallHalf)
    {
        pByte--;
        NSPAssert(pByte >= dataBytes);
        *pByte = byte;
    }

    size_t diff = pByte - dataBytes;
    if (!diff)
    {
        // for optimal strings that are just HEX characters
        return [self initWithBytesNoCopy:dataBytes length:dataBytesLength freeWhenDone:YES];
    }

    self = [self initWithBytes:pByte length:dataBytesLength - diff];
    free(dataBytes);
    return self;
}

@end
