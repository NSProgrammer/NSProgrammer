//
//  NSPConversion.m
//  NSPLib
//
//  Created by Nolan O'Brien on 6/9/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

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


