//
//  NSData+Description.m
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSData+Description.h"
#import "NSData+Serialize.h"
#import "NSPCommon.h"

static NSDataDescriptionOptions s_options = NSDataDescriptionOption_None; // OS default

@implementation NSData (Description)

+ (NSDataDescriptionOptions) descriptionOptions
{
    @synchronized (self) {
        return s_options;
    }
}

+ (NSDataDescriptionOptions) setDescriptionOptions:(NSDataDescriptionOptions)options
{
    @synchronized(self) {
        if (s_options != options)
        {
            if (NSDataDescriptionOption_None == s_options ||
                NSDataDescriptionOption_None == options)
            {
                // Swizzle - either to the custom description or back to the native description
                NSPSwizzleInstanceMethods([NSData class], @selector(description), @selector(_configuredDescription));
            }
            
            NSDataDescriptionOptions tmp = s_options;
            s_options = options;
            options = tmp;
        }

        return options;
    }
}

#pragma mark - Internal

- (NSString*) _configuredDescription
{
    NSDataDescriptionOptions options = s_options;
    NSMutableString* dsc = [NSMutableString string];
    [dsc appendString:@"<"];
    
    if (NSDataDescriptionOption_ObjectInfo & options)
    {
        [dsc appendFormat:@"%@:%p", NSStringFromClass([self class]), self];
    }
    
    if (NSDataDescriptionOption_Length & options)
    {
        if (dsc.length > 1)
            [dsc appendString:@" "];
        [dsc appendFormat:@"length=%d", self.length];
    }
    
    if (NSDataDescriptionOption_Data & options)
    {
        if (dsc.length > 1)
            [dsc appendString:@" "];
        [dsc appendString:[self hexStringValueWithDelimeter:@" " everyNBytes:4]]; // hexStringValue will be shown at the end of this post as a "bonus"
    }

    [dsc appendString:@">"];

    return dsc;  // you could return a copy of the mutable description, but it's not a big issue if someone mutates the return string and copying a potentially large string (like when the Data option is set) is memory consuming
}

@end
