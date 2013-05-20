//
//  NSPVersion.m
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSPVersion.h"
#import "NSPLibraryLoader.h"
#import <objc/message.h>

@interface NSPVersion (Hidden)
// components MUST be NSNumbers
- (id) initWithComponentsPure:(NSArray *)components;
+ (NSPVersion*) versionWithComponentsPure:(NSArray*)components;
@end

@implementation NSPVersion

- (id) init
{
    if (self = [super init])
    {
        _versionComponents = [[NSArray alloc] init];
    }
    return self;
}

- (id) initWithComponents:(NSArray*)components
{
    BOOL success = YES;
    if ((success = !!components))
    {
        NSMutableArray* mutComponents = [NSMutableArray array];
        for (id val in components)
        {
            if ([val isKindOfClass:[NSNumber class]])
            {
                [mutComponents addObject:val];
            }
            else if ([val isKindOfClass:[NSString class]])
            {
                [mutComponents addObject:@([val integerValue])];
            }
            else
            {
                success = NO;
                break;
            }
        }
        
        if (success && mutComponents.count == 0)
        {
            success = NO;
        }
        else
        {
            components = mutComponents;
        }
    }

    if (success)
    {
        return [self initWithComponentsPure:components];
    }

    self = nil;
    return self;
}

- (id) initWithString:(NSString*)versionStr
{
    return [self initWithComponents:[versionStr componentsSeparatedByString:@"."]];
}

- (id) initWithMajorVersion:(NSUInteger)major minorVersion:(NSUInteger)minor revisionVersion:(NSUInteger)revision bugFixVersion:(NSUInteger)bugFix
{
    return [self initWithComponentsPure:@[@(major), @(minor), @(revision), @(bugFix)]];
}

- (id) initWithComponentsPure:(NSArray *)components
{
    if (self = [super init])
    {
        _versionComponents = (components ? [components copy] : [[NSArray alloc] init]);
    }
    return self;
}

+ (NSPVersion*) versionWithComponentsPure:(NSArray*)components
{
    return [[NSPVersion alloc] initWithComponentsPure:components];
}

+ (NSPVersion*) versionWithString:(NSString*)versionStr
{
    return [[NSPVersion alloc] initWithString:versionStr];
}

+ (NSPVersion*) versionWithComponents:(NSArray*)components
{
    return [[NSPVersion alloc] initWithComponents:components];
}

+ (NSPVersion*) versionWithMajorVersion:(NSUInteger)major minorVersion:(NSUInteger)minor revisionVersion:(NSUInteger)revision bugFixVersion:(NSUInteger)bugFix
{
    return [[NSPVersion alloc] initWithMajorVersion:major minorVersion:minor revisionVersion:revision bugFixVersion:bugFix];
}

+ (NSPVersion*) appVersion
{
    static __strong NSPVersion* s_appVersion = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        s_appVersion = [[NSPVersion alloc] initWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    });
    return s_appVersion;
}

- (NSUInteger) versionComponentCount
{
    return _versionComponents.count;
}

- (NSUInteger) versionComponentAtIndex:(NSUInteger)index
{
    if (index >= _versionComponents.count)
    {
        return 0;
    }
    return [[_versionComponents objectAtIndex:index] integerValue];
}

- (NSUInteger) majorVersion
{
    return [self versionComponentAtIndex:0];
}

- (NSUInteger) minorVersion
{
    return [self versionComponentAtIndex:1];
}

- (NSUInteger) revisionVersion
{
    return [self versionComponentAtIndex:2];
}

- (NSUInteger) bugFixVersion
{
    return [self versionComponentAtIndex:3];
}

- (NSString*) stringValue
{
    NSMutableString* str = [NSMutableString string];
    BOOL first = YES;

    for (NSNumber* n in _versionComponents)
    {
        if (first)
        {
            first = NO;
        }
        else
        {
            [str appendString:@"."];
        }
        
        [str appendString:[n stringValue]];
    }

    return str; //[str copy];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: %p, v%@>", NSStringFromClass([self class]), self, self.stringValue];
}

- (NSComparisonResult) compare:(NSPVersion*)otherVersion
{
    NSUInteger count = MAX(self.versionComponentCount, otherVersion.versionComponentCount);
    
    for (NSUInteger i = 0; i < count; i++)
    {
        NSUInteger l = [self versionComponentAtIndex:i];
        NSUInteger r = [otherVersion versionComponentAtIndex:i];
        if (l < r)
        {
            return NSOrderedAscending;
        }
        else if (r < l)
        {
            return NSOrderedDescending;
        }
    }
    
    return NSOrderedSame;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass:[NSPVersion class]])
    {
        return (NSOrderedSame == [self compare:object]);
    }
    return [super isEqual:object];
}

- (BOOL) isLessThan:(NSPVersion*)otherVersion
{
    return (NSOrderedAscending == [self compare:otherVersion]);
}

- (BOOL) isGreaterThan:(NSPVersion*)otherVersion
{
    return (NSOrderedDescending == [self compare:otherVersion]);
}

- (BOOL) isLessThanOrEqual:(NSPVersion*)otherVersion
{
    return ![self isGreaterThan:otherVersion];
}

- (BOOL) isGreaterThanOrEqual:(NSPVersion*)otherVersion
{
    return ![self isLessThan:otherVersion];
}

#pragma mark NSCoding
- (void) encodeWithCoder:(NSCoder*)aCoder
{
    [aCoder encodeObject:_versionComponents forKey:@"component"];
}

- (id) initWithCoder:(NSCoder*)aDecoder
{
    if (self = [super init])
    {
        _versionComponents = [aDecoder decodeObjectForKey:@"component"];
    }
    return self;
}

@end

@implementation NSPVersion (OSVersion)

+ (NSPVersion*) osVersion
{
    static __strong NSPVersion* s_osVersion = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        // Dynamically load UIKit for better segregation of code (segregate Foundation vs UI code)
        NSPVersion* version = nil;
        NSPLibraryLoader* uikit = [[NSPLibraryLoader alloc] initWithFramework:@"UIKit"];
        (void)uikit;
        Class uiDevice = NSClassFromString(@"UIDevice");
        if (uiDevice)
        {
            id device = objc_msgSend(uiDevice, @selector(currentDevice));
            version = [[NSPVersion alloc] initWithString:objc_msgSend(device, @selector(systemVersion))];
        }
        s_osVersion = version;
    });
    return s_osVersion;
}

@end
