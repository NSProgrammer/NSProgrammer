//
//  NSPLibraryLoader.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

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
