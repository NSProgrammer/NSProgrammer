//
//  NSFileManager+Extensions.h
//  NSPLib
//
//  Created by Nolan O'Brien on 6/11/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Extensions)
/**
    @return the size in bytes of the device's file system.
 */
- (unsigned long long) fileSystemSize;
/**
    @param filePath the path to a file on disk (not a directory)
    @return the size in bytes of the provided \a filePath
    @see directorySize:
 */
- (unsigned long long) fileSize:(NSString*)filePath;
/**
    @param directoryPath the path to the directory on disk (not a file)
    @param recursive whether to recursively consider all subdirectories and files in computing the directory size
    @return the size in bytes of the contents in \a directoryPath
    @see fileSize:
    @warning this method can be EXTREMELY slow when run recursively if there a great deal of depth within the directory.  If you pass \@"/" you'll be waiting forever.
 */
- (unsigned long long) directorySize:(NSString*)directoryPath recursive:(BOOL)recursive;
@end
