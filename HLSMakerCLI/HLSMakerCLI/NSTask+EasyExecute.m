//
//  NSTask+EasyExecute.m
//  HLSMakerCLI
//
//  Created by Nolan O'Brien on 8/3/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import "NSTask+EasyExecute.h"

@implementation NSTask (EasyExecute)

+ (NSString*) executeAndReturnStdOut:(NSString *)taskPath arguments:(NSArray *)args
{
    return [self executeAndReturnStdOut:taskPath arguments:args withMaxStringLength:-1];
}

+ (NSString*) executeAndReturnStdOut:(NSString *)taskPath arguments:(NSArray *)args withMaxStringLength:(NSUInteger)strLen
{
    @autoreleasepool {
        NSTask* otool = [[NSTask alloc] init];
        otool.launchPath = taskPath;
        otool.arguments = args;
        otool.standardOutput = [NSPipe pipe];
        
        [otool launch];
        
        NSData* dataOut = nil;
        if (-1 == strLen)
        {
            while (otool.isRunning)
            {
                NSMutableData* old = [dataOut isKindOfClass:[NSMutableData class]] ? (NSData*)dataOut : dataOut.mutableCopy;
                dataOut = [[otool.standardOutput fileHandleForReading] readDataToEndOfFile];
                if (old)
                {
                    [old appendData:dataOut];
                    dataOut = old;
                }
            }
        }
        else
        {
            NSMutableData* data = [NSMutableData data];
            
            while (data.length < strLen && otool.isRunning)
            {
                [data appendData:[[otool.standardOutput fileHandleForReading] readDataOfLength:strLen - data.length]];
            }
            
            if (otool.isRunning)
            {
                [otool terminate];
            }
            
            char z = '\0';
            [data appendBytes:&z length:1];
            dataOut = data;
        }
        NSString* output = [[NSString alloc] initWithBytes:dataOut.bytes
                                                    length:dataOut.length
                                                  encoding:NSUTF8StringEncoding];
        output = [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return output;
    }
}

@end
