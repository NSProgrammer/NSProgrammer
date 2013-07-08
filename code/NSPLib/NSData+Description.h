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

/**
    Enum of the possible description options that can be set.  Multiple options can be ORed together.
 */
typedef NS_OPTIONS(NSUInteger, NSDataDescriptionOptions)
{
    NSDataDescriptionOption_Default    = 0,         /**< When 0 is used, description behaves as OS Default */
    NSDataDescriptionOption_ObjectInfo = (1 << 0),    /**< Put object informatino into the description (class name and object pointer) */
    NSDataDescriptionOption_Length     = (1 << 1),    /**< Put \c length of NSData into description */
    NSDataDescriptionOption_Data       = (1 << 2),    /**< Put \c data as a hex string into the description @warning can be very expensive (just like OS Default) */

    NSDataDescriptionOptions_ObjectInfoAndLength = NSDataDescriptionOption_ObjectInfo | NSDataDescriptionOption_Length,
    NSDataDescriptionOptions_ObjectInfoAndData   = NSDataDescriptionOption_ObjectInfo | NSDataDescriptionOption_Data,
    NSDataDescriptionOptions_LengthAndData       = NSDataDescriptionOption_Length | NSDataDescriptionOption_Data,
    NSDataDescriptionOptions_AllOptions          = NSDataDescriptionOption_ObjectInfo | NSDataDescriptionOption_Length | NSDataDescriptionOption_Data,
};

@interface NSData (Description)

/**
    Thread safe retrieval of the current \c NSDataDescriptionOptions.
    @see setDescriptionOptions:
    @see NSDataDescriptionOptions
 */
+ (NSDataDescriptionOptions) descriptionOptions;
/**
    Thread safe setting of the current \c NSDataDescriptionOptions.
    @param options the description options to set.  \c NSDataDescriptionOption_Default reverts to the OS version, anything else changes out the \c description method to return a configured description string.
    @return the \c NSDataDescriptionOptions that existed before being replaced by this method call.
    @see descriptionOptions
    @see NSDataDescriptionOptions
 */
+ (NSDataDescriptionOptions) setDescriptionOptions:(NSDataDescriptionOptions)options; // returns the previous options

@end
