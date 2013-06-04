//
//  NSPLibraryLoader.m
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSPLibraryLoader.h"
#include <dlfcn.h>

@implementation NSPLibraryLoader

static __strong NSArray* s_frameworksPaths = nil;

@synthesize handle = _handle;

+ (void) initialize
{
    s_frameworksPaths = @[@"/System/Library/Frameworks",
                          @"/System/Library/PrivateFrameworks",
                          [[NSBundle mainBundle] sharedFrameworksPath],
                          [[NSBundle mainBundle] privateFrameworksPath]];
}

- (id) init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
        _handle = NULL;
    }
    
    return self;
}

- (void) dealloc
{
    if (_handle)
    {
        dlclose(_handle);
    }
}

+ (id) loaderWithFramework:(NSString*)frameworkName
{
    return [[NSPLibraryLoader alloc] initWithFramework:frameworkName];
}

- (id) initWithFramework:(NSString*)frameworkName
{
    if (self = [self init])
    {
        if (frameworkName)
        {
            for (NSString* pathPrefix in s_frameworksPaths)
            {
                NSString* path = [NSString stringWithFormat:@"%@/%@.framework/%@", pathPrefix, frameworkName, frameworkName];
                _handle = dlopen([path UTF8String], 0);
                if (_handle)
                {
                    break;
                }
            }
        }

        if (!_handle)
        {
            self = nil;
        }
    }
    return self;
}

+ (id) loaderWithDynamicLibrary:(NSString*)dylibName
{
    return [[NSPLibraryLoader alloc] initWithDynamicLibrary:(NSString*)dylibName];
}

- (id) initWithDynamicLibrary:(NSString*)dylibName
{
    if (self = [self init])
    {
        if (dylibName)
        {
            if (![dylibName hasPrefix:@"lib"])
            {
                dylibName = [@"lib" stringByAppendingString:dylibName];
            }
            if (![dylibName hasSuffix:@".dylib"])
            {
                dylibName = [dylibName stringByAppendingString:@".dylib"];
            }
            dylibName = [@"/usr/lib/" stringByAppendingString:dylibName];
            _handle   = dlopen([dylibName UTF8String], 0);
        }
        
        if (!_handle)
        {
            self = nil;
        }
    }
    return self;
}

- (void*) getSymbol:(NSString*)symbol
{
    return dlsym(_handle, [symbol UTF8String]);
}

- (void*) handle
{
    return _handle;
}

@end
