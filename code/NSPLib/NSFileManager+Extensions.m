//
//  NSFileManager+Extensions.m
//  NSPLib
//
//  Created by Nolan O'Brien on 6/11/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

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

- (unsigned long long) directorySize:(NSString*)directoryPath
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
                if (isDir)
                {
                    size += [self directorySize:fullItem];
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
