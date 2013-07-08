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

#pragma mark - Angles

#define DEGREES_TO_RADIANS(angle)          (((angle) / 180.0) * M_PI)
#define RADIANS_TO_DEGREES(radian)         (((radian) / M_PI) * 180.0)


#pragma mark - Time

#define MINS_2_SECS(x)                     ((x) * 60)

#define HOURS_2_MINS(x)                    ((x) * 60)
#define HOURS_2_SECS(x)                    (MINS_2_SECS(HOURS_2_MINS(x)))

#define DAYS_2_HOURS(x)                    ((x) * 24)
#define DAYS_2_MINS(x)                     (HOURS_2_MINS(DAYS_2_HOURS(x)))
#define DAYS_2_SECS(x)                     (MINS_2_SECS(DAYS_2_MINS(x)))


#pragma mark - Sizes

#define kMAGNITUDE_BYTES                    (1024)
#define kMAGNITUDE_HERTZ                    (1000)

/**
    Convert the provided quantity in bytes into a human readable string.
    @param bytes number of bytes to convert.
    @return human readable string for size.  Example: \c @"128.24 GBs"
 */
NSString* SizeInBytesToString(unsigned long long bytes);
/**
     Convert the provided quantity in hertz into a human readable string.
     @param hertz number of bytes to convert.
     @return human readable string for speed.  Example: \c @"128.24 MHz"
 */
NSString* SpeedInHzToString(uint64_t hz);

/**
    Generic function for converting a size quantity to a refined size quantity based on orders of magnitude
    @param sourceSize the size of the source quantity
    @param magnitudeSize the magnitude of the size; that is, the size before the quantity rolls over to the next order of magnitude
    @param maximumOrdersOfMagnitude as we compute the orders of, the limit that can be reached
    @param pDestination the output pointer for the resulting equivalent size at the determined order of magnitude returned in \a pOrdersOfMagnitude
    @param pOrdersOfMagnitude the number of orders of magnitude that the source size contained as we broke down the size to the new output size returned in \a pOrdersOfMagnitude
    @note this is the generic function used by \c SizeInBytesToString and \c SpeedInHzToString
    @see SizeInBytesToString implementation
    @see SpeedInHzToString implementation
 */
void ConvertSize(unsigned long long sourceSize,
                 unsigned int magnitudeSize,
                 unsigned int maximumOrdersOfMagnitude,
                 double* pDestination,
                 unsigned int* pOrdersOfMagnitude);
