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
