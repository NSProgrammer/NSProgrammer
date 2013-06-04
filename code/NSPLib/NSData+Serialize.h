//
//  NSData+Serialize.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Serialize)

- (NSString*) hexStringValue;
- (NSString*) hexStringValueWithDelimeter:(NSString*)delim everyNBytes:(NSUInteger)nBytes;

@end
