//
//  NSData+Description.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
    Enum of the possible description options that can be set.  Multiple options can be ORed together.
 */
typedef enum
{
    NSDataDescriptionOption_Default    = 0,         /**< When 0 is used, description behaves as OS Default */
    NSDataDescriptionOption_ObjectInfo = 1 << 0,    /**< Put object informatino into the description (class name and object pointer) */
    NSDataDescriptionOption_Length     = 1 << 1,    /**< Put \c length of NSData into description */
    NSDataDescriptionOption_Data       = 1 << 2,    /**< Put \c data as a hex string into the description @warning can be very expensive (just like OS Default) */

    NSDataDescriptionOption_ObjectInfoAndLength = NSDataDescriptionOption_ObjectInfo | NSDataDescriptionOption_Length,
    NSDataDescriptionOption_ObjectInfoAndData   = NSDataDescriptionOption_ObjectInfo | NSDataDescriptionOption_Data,
    NSDataDescriptionOption_LengthAndData       = NSDataDescriptionOption_Length | NSDataDescriptionOption_Data,
    NSDataDescriptionOption_AllOptions          = NSDataDescriptionOption_ObjectInfo | NSDataDescriptionOption_Length | NSDataDescriptionOption_Data,
} NSDataDescriptionOptions;


@interface NSData (Description)

/**
    Thread safe retrieval of the current \c NSDataDescriptionOptions.
    @see setDescriptionOptions:
    @see NSDataDescriptionOptions
 */
+ (NSDataDescriptionOptions) descriptionOptions;
/**
    Thread safe setting of the current \c NSDataDescriptionOptions.
    @param options the description options to set.  \c NSDataDescriptionOption_Default reverts to the OS version, anything else changes out the \fn description method to return a configured description string.
    @return the \c NSDataDescriptionOptions that existed before being replaced by this method call.
    @see descriptionOptions
    @see NSDataDescriptionOptions
 */
+ (NSDataDescriptionOptions) setDescriptionOptions:(NSDataDescriptionOptions)options; // returns the previous options

@end
