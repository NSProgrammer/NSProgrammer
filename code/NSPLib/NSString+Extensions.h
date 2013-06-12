//
//  NSString+Extensions.h
//  NSPLib
//
//  Created by Nolan O'Brien on 6/11/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)
/**
    @return the unsigned long long representation of the string.
    @note skips all leading whitespace and terminates on first non-decimal character (including the NULL terminator).
    @note only parses European decimal digit characters: "0123456789"
 */
- (unsigned long long) unsignedLongLongValue;
@end
