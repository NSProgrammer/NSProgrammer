//
//  NSCharacterSet+Extensions.h
//  NSPLib
//
//  Created by Nolan O'Brien on 8/22/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCharacterSet (Extensions)

/**
    Convenience construction of character set with \c @"abcdef0123456789ABCDEF"
 */
+ (NSCharacterSet*) hexadecimalDigitCharacterSet;

@end
