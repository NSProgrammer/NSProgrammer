//
//  NSCharacterSet+Extensions.m
//  NSPLib
//
//  Created by Nolan O'Brien on 8/22/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSCharacterSet+Extensions.h"

@implementation NSCharacterSet (Extensions)

+ (NSCharacterSet*) hexadecimalDigitCharacterSet
{
    return [NSCharacterSet characterSetWithCharactersInString:@"abcdef0123456789ABCDEF"];
}

@end
