//
//  NSPLibraryLoader.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSPLibraryLoader : NSObject

// The handle to the framework/dylib
// this pointer is provided as a convenience, do NOT close the handle, it will close on NSPLibraryLoader dealloc
@property (nonatomic, assign, readonly) void* handle;

// loading from a framework name.
// Example: to load UIKit, the string would be @"UIKit"
+ (id) loaderWithFramework:(NSString*)frameworkName;
- (id) initWithFramework:(NSString*)frameworkName;

// loading from a dylib name
// Example: to load libxml2, the string would be one of @"libxml2", @"xml2", or @"libxml2.dylib"
+ (id) loaderWithDynamicLibrary:(NSString*)dylibName;
- (id) initWithDynamicLibrary:(NSString*)dylibName;

// Get a symbol via its name
//
// Example: to get a const NSString* like UITextAttributeColor:
//      NSString** pUITextAttributeColor = [zlibLoaderObject getSymbol:@"UITextAttributeColor"];
//
// Returns: the address of the symbol or NULL if not found.
- (void*) getSymbol:(NSString*)symbol;

@end
