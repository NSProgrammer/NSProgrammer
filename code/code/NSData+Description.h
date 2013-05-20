//
//  NSData+Description.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    NSDataDescriptionOption_None       = 0,     // behaves as OS default
    NSDataDescriptionOption_ObjectInfo = 1 << 0,
    NSDataDescriptionOption_Length     = 1 << 1,
    NSDataDescriptionOption_Data       = 1 << 2,

    NSDataDescriptionOption_ObjectInfoAndLength = NSDataDescriptionOption_ObjectInfo | NSDataDescriptionOption_Length,
    NSDataDescriptionOption_ObjectInfoAndData   = NSDataDescriptionOption_ObjectInfo | NSDataDescriptionOption_Data,
    NSDataDescriptionOption_LengthAndData       = NSDataDescriptionOption_Length | NSDataDescriptionOption_Data,
    NSDataDescriptionOption_AllOptions          = NSDataDescriptionOption_ObjectInfo | NSDataDescriptionOption_Length | NSDataDescriptionOption_Data,
} NSDataDescriptionOptions;


@interface NSData (Description)

+ (NSDataDescriptionOptions) descriptionOptions;
+ (NSDataDescriptionOptions) setDescriptionOptions:(NSDataDescriptionOptions)options; // returns the previous options

@end
