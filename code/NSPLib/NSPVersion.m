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

#import "NSPVersion.h"
#import "NSPLibraryLoader.h"
#import <objc/message.h>

@interface NSPVersion (Hidden)
// components MUST be NSNumbers
- (instancetype) initWithComponentsPure:(NSArray *)components;
+ (instancetype) versionWithComponentsPure:(NSArray*)components;
@end

@implementation NSPVersion

- (instancetype) init
{
    if (self = [super init])
    {
        _versionComponents = [[NSArray alloc] init];
    }
    return self;
}

- (instancetype) initWithComponents:(NSArray*)components
{
    if (!components)
        return [self init];

    NSMutableArray* mutComponents = [[NSMutableArray alloc] init];
    for (id val in components)
    {
        if ([val isKindOfClass:[NSNumber class]])
        {
            [mutComponents addObject:val];
        }
        else if ([val respondsToSelector:@selector(integerValue)])
        {
            [mutComponents addObject:@([val integerValue])];
        }
        else if ([val respondsToSelector:@selector(intValue)])
        {
            [mutComponents addObject:@([val intValue])];
        }
        else
        {
            [mutComponents addObject:@0];
        }
    }

    return [self initWithComponentsPure:mutComponents];
}

- (instancetype) initWithString:(NSString*)versionStr
{
    return [self initWithComponents:[versionStr componentsSeparatedByString:@"."]];
}

- (instancetype) initWithMajorVersion:(NSUInteger)major minorVersion:(NSUInteger)minor revisionVersion:(NSUInteger)revision buildVersion:(NSUInteger)build
{
    return [self initWithComponentsPure:@[@(major), @(minor), @(revision), @(build)]];
}

- (instancetype) initWithComponentsPure:(NSArray*)components
{
    if (self = [super init])
    {
        _versionComponents = (components ? [components copy] : [[NSArray alloc] init]);
    }
    return self;
}

+ (instancetype) versionWithComponentsPure:(NSArray*)components
{
    return [[self alloc] initWithComponentsPure:components];
}

+ (instancetype) versionWithString:(NSString*)versionStr
{
    return [[self alloc] initWithString:versionStr];
}

+ (instancetype) versionWithComponents:(NSArray*)components
{
    return [[self alloc] initWithComponents:components];
}

+ (instancetype) versionWithMajorVersion:(NSUInteger)major minorVersion:(NSUInteger)minor revisionVersion:(NSUInteger)revision buildVersion:(NSUInteger)build
{
    return [[self alloc] initWithMajorVersion:major minorVersion:minor revisionVersion:revision buildVersion:build];
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

- (NSUInteger) buildVersion
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
