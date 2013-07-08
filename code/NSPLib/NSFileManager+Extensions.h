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
