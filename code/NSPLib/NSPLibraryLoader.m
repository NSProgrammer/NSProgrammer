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
