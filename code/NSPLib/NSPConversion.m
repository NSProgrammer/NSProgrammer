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

#import "NSPConversion.h"

NSString* SizeInBytesToString(unsigned long long bytes)
{
    static __strong NSArray* tokens = nil;
    static dispatch_once_t   onceToken;
    dispatch_once(&onceToken, ^{
        tokens = @[@"bytes", @"KBs", @"MBs", @"GBs", @"TBs"];
    });

    unsigned int om = 0;
    double newSize  = 0;
    ConvertSize(bytes, kMAGNITUDE_BYTES, tokens.count, &newSize, &om);
    return [NSString stringWithFormat:@"%.2f %@", newSize, [tokens objectAtIndex:om]];
}

NSString* SpeedInHzToString(uint64_t hz)
{
    static __strong NSArray* tokens = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tokens = @[@"Hz", @"KHz", @"MHz", @"GHz", @"THz"];
    });

    unsigned int om = 0;
    double newSize  = 0;
    ConvertSize(hz, kMAGNITUDE_HERTZ, tokens.count, &newSize, &om);
    return [NSString stringWithFormat:@"%.2f %@", newSize, [tokens objectAtIndex:om]];
}

void ConvertSize(unsigned long long sourceSize,
                 unsigned int magnitudeSize,
                 unsigned int maximumOrdersOfMagnitude,
                 double* pDestination,
                 unsigned int* pOrdersOfMagnitude)
{
    NSPCAssert(pDestination);
    NSPCAssert(pOrdersOfMagnitude);
    unsigned long long afterDecimal = 0;
    unsigned int ordersOfMagnitude = 0;
    
    while (sourceSize > magnitudeSize &&
           ordersOfMagnitude < maximumOrdersOfMagnitude)
    {
        unsigned long long converted = sourceSize / magnitudeSize;
        afterDecimal = (sourceSize - (converted * magnitudeSize)) * 100 / magnitudeSize;
        sourceSize = converted;
        ordersOfMagnitude++;
    }
    NSPCAssert(afterDecimal < 100);
    *pDestination = (double)sourceSize + ((double)afterDecimal / 100.0f);
    *pOrdersOfMagnitude = ordersOfMagnitude;
}


