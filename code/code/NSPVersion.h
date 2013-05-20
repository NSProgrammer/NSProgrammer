//
//  NSPVersion.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSPVersion : NSObject <NSCoding>

- (id) init;
- (id) initWithString:(NSString*)versionStr;
- (id) initWithComponents:(NSArray*)components; // components can be either NSNumbers or NSStrings that are integers (mixing is ok)
- (id) initWithMajorVersion:(NSUInteger)major
               minorVersion:(NSUInteger)minor
            revisionVersion:(NSUInteger)revision
              bugFixVersion:(NSUInteger)bugFix;

+ (NSPVersion*) versionWithString:(NSString*)versionStr;
+ (NSPVersion*) versionWithComponents:(NSArray*)components;  // components can be either NSNumbers or NSStrings that are integers (mixing is ok)
+ (NSPVersion*) versionWithMajorVersion:(NSUInteger)major
                           minorVersion:(NSUInteger)minor
                        revisionVersion:(NSUInteger)revision
                          bugFixVersion:(NSUInteger)bugFix;

+ (NSPVersion*) appVersion;

@property (nonatomic, strong, readonly) NSArray* versionComponents;

- (NSUInteger) versionComponentCount;
- (NSUInteger) versionComponentAtIndex:(NSUInteger)index;
- (NSUInteger) majorVersion;
- (NSUInteger) minorVersion;
- (NSUInteger) revisionVersion;
- (NSUInteger) bugFixVersion;

- (NSString*) stringValue;
- (NSString*) description;

- (NSComparisonResult) compare:(NSPVersion*)otherVersion;
- (BOOL) isEqual:(id)object;
- (BOOL) isLessThan:(NSPVersion*)otherVersion;
- (BOOL) isGreaterThan:(NSPVersion*)otherVersion;
- (BOOL) isLessThanOrEqual:(NSPVersion*)otherVersion;
- (BOOL) isGreaterThanOrEqual:(NSPVersion*)otherVersion;

@end

@interface NSPVersion (OSVersion)
+ (NSPVersion*) osVersion;
@end

