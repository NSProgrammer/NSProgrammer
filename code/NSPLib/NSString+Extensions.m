//
//  NSString+Extensions.m
//  NSPLib
//
//  Created by Nolan O'Brien on 6/11/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSString+Extensions.h"
#import "NSPStringUtils.h"

@implementation NSString (Extensions)

- (unsigned long long) unsignedLongLongValue
{
    if (self.length == 0)
    {
        return 0;
    }

    unsigned long long result = 0;
    const char*        cStr   = self.UTF8String;
    const char*        cCur   = cStr;
    unsigned long long newResult;

    while (isWhitespaceCharacter(*cCur))
        cCur++;

    // go through all decimal digit characters and terminates at first non digit
    // can be the NULL char string terminator
    while (isDecimalCharacter(*cCur))
    {
        newResult = result * 10;
        if (newResult < result)
        {
            return ULLONG_MAX; // overflow
        }
        newResult += (*cCur - '0');
        result     = newResult;
        ++cCur;
    }

    return result;
}

@end
