//
//  NSFileManager+Extensions.h
//  NSPLib
//
//  Created by Nolan O'Brien on 6/11/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Extensions)
- (unsigned long long) fileSystemSize;
- (unsigned long long) fileSize:(NSString*)filePath;
- (unsigned long long) directorySize:(NSString*)directoryPath;
@end
