//
//  NSPStringUtils.h
//  NSPLib
//
//  Created by Nolan O'Brien on 6/11/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_INLINE BOOL isOctalCharacter(unichar c)
{
    return '0' <= c && c <= '7';
}

NS_INLINE BOOL isDecimalCharacter(unichar c)
{
    return '0' <= c && c <= '9';
}

NS_INLINE BOOL isAlphaCharacter(unichar c)
{
    return ('a' <= c && c <= 'f') ||
           ('A' <= c && c <= 'F');
}

NS_INLINE BOOL isHexCharacter(unichar c)
{
    return isDecimalCharacter(c) ||
           isAlphaCharacter(c);
}

NS_INLINE BOOL isWhitespaceCharacter(unichar c)
{
    return (c == ' ' || c == '\n' || c == '\r' || c == '\t');
}

NS_INLINE char decimalDigitValueForCharacter(unichar c)
{
    if ('0' <= c && c <= '9')
    {
        return c - '0';
    }
    else if ('a' <= c && c <= 'z')
    {
        return c - 'a' + 10;
    }
    else if ('A' <= c && c <= 'Z')
    {
        return c - 'A' + 10;
    }

    NSPCAssert(false && "character does not equate to a digit value, must be hex");
    return 0;
}
