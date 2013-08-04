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
