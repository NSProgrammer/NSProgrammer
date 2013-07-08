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

/**
    @class NSPLibraryLoader
    Object used for object oriented access to a dynamically loaded library or framework
 */
@interface NSPLibraryLoader : NSObject

/**
    The handle to the framework/dylib
    @par this pointer is provided as a convenience, do NOT close the handle, it will close on NSPLibraryLoader dealloc
 */
@property (nonatomic, assign, readonly) void* handle;

/**
    Load a Framework by name.
    @param frameworkName the name of the Framework to load, example: \@"UIKit"
 */
- (id) initWithFramework:(NSString*)frameworkName;
/**
    @see initWithFramework:
 */
+ (id) loaderWithFramework:(NSString*)frameworkName;

/**
    Load a dynamic library by name.
    @param dylibName the name of the library to load.  Example: to load libxml2, the string could be any of \@"libxml2.dylib", \@"libxml2" or \@"xml2"
 */
- (id) initWithDynamicLibrary:(NSString*)dylibName;
/**
    @see initWithDynamicLibrary:
 */
+ (id) loaderWithDynamicLibrary:(NSString*)dylibName;

/**
    Get a symbol via its name.
    @par Example: to get a const NSString* like \c UITextAttributeColor you would:
    @code
    NSString** pUITextAttributeColor = [uikitLoaderObject getSymbol:@"UITextAttributeColor"];
    @endcode
    @param symbol the name of the symbol
    @return the address of the symbol or \c NULL if not found
 */
- (void*) getSymbol:(NSString*)symbol;

@end
