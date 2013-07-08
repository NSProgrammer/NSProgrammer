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

#import "NSData+Description.h"
#import "NSData+Serialize.h"

static NSDataDescriptionOptions s_options = NSDataDescriptionOption_Default;

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
            if (NSDataDescriptionOption_Default == s_options ||
                NSDataDescriptionOption_Default == options)
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
