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

#import "NSFileManager+Extensions.h"

@implementation NSFileManager (Extensions)

- (unsigned long long) fileSystemSize
{
    NSDictionary* attributes = [self attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    
    return [[attributes objectForKey:NSFileSystemSize] unsignedLongLongValue];
}

- (unsigned long long) fileSize:(NSString*)filePath
{
    NSDictionary* attributes = [self attributesOfItemAtPath:filePath error:nil];
    
    return [[attributes objectForKey:NSFileSize] unsignedLongLongValue];
}

- (unsigned long long) directorySize:(NSString*)directoryPath recursive:(BOOL)recursive
{
    unsigned long long size = 0;
    BOOL isDir = NO;

    if ([self fileExistsAtPath:directoryPath isDirectory:&isDir] && isDir)
    {
        NSArray* contents = [self contentsOfDirectoryAtPath:directoryPath error:nil];
        for (NSString* item in contents)
        {
            NSString* fullItem = [directoryPath stringByAppendingPathComponent:item];
            if ([self fileExistsAtPath:fullItem isDirectory:&isDir])
            {
                if (isDir && recursive)
                {
                    size += [self directorySize:fullItem recursive:YES];
                }
                else
                {
                    size += [self fileSize:fullItem];
                }
            }
        }
    }
    return size;
}

@end
