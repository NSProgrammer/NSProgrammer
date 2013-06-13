//
//  NSData+Serialize.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Serialize)

/**
    Same as hexStringValueWithDelimeter:everyNBytes: with \a delim as nil and \a nBytes as 0.
    @return a string representing the \c NSData target with hexadecimal characters.  Ex// \c \@"ABCDEF0123456789"
    @see hexStringValueWithDelimeter:everyNBytes:
 */
- (NSString*) hexStringValue;
/**
    Serialize the data into a hex string with a configurable delimiting.
    @param delim the string to delimit chunks of bytes by.  Provide \c nil or an empty string to have no delimiter.
    @param nBytes how many bytes between each delimiter.  Provide \c 0 to have no delimiter.
    @return a string representing the \c NSData target with hexadecimal characters with an optional delimiting string. Ex// \c \@"ABCD EF01 2345 6789" for \c \@" " \a delim and \a nBytes as \c 2
 */
- (NSString*) hexStringValueWithDelimeter:(NSString*)delim everyNBytes:(NSUInteger)nBytes;

@end

@interface NSData (Deserialize)

/**
    Deserialize a hex string into an \c NSData object.
    @param a hex string representation of data.
    @return the data representation of the provided \a hexString
    @note all characters that are not hex characters are ignored - \c "0123456789ABCDEF"
 */
+ (NSData*) dataWithHexString:(NSString*)hexString;
/**
    Initialize an \c NSData object with a hex string.
    @see dataWithHexString:
 */
- (id) initWithHexString:(NSString*)hexString;

@end
