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
    @class NOBVersion
    
    NOBVersion is a class for encapsulating version componenets 
 */
@interface NOBVersion : NSObject <NSCoding>

///** 
//    @overload init
//    init NOBVersion with an empty set of version components (versionComponentCount == 0)
// */
- (instancetype) init;
/** 
    init NOBVersion with a string decomposed by "." 
 */
- (instancetype) initWithString:(NSString*)versionStr;
/** 
    @brief init NOBVersion with an array of components.
    @par If a component is an NSNumber, it's unsignedIntegerValue will be used.
    @par If a component has an integerValue or intValue method, that will be used.
    @par Otherwise the component will be treated as zero (0).
 */
- (instancetype) initWithComponents:(NSArray*)components;
/** 
    init NOBVersion with 4 version components
    @param major The major version.  The 6 of 6.0.1.2
    @param minor The minor version.  The 0 of 6.0.1.2
    @param revision The revision version.  The 1 of 6.0.1.2
    @param build The build version. The 2 of 6.0.1.2
 */
- (instancetype) initWithMajorVersion:(NSUInteger)major
                         minorVersion:(NSUInteger)minor
                      revisionVersion:(NSUInteger)revision
                         buildVersion:(NSUInteger)build;

/** @see initWithString: */
+ (instancetype) versionWithString:(NSString*)versionStr;
/** @see initWithComponents: */
+ (instancetype) versionWithComponents:(NSArray*)components;
/** @see initWithMajorVersion:minorVersion:revisionVersion:buildVersion: */
+ (instancetype) versionWithMajorVersion:(NSUInteger)major
                            minorVersion:(NSUInteger)minor
                         revisionVersion:(NSUInteger)revision
                            buildVersion:(NSUInteger)build;

/** 
    Convenience static method for getting the application's version
    @return an NOBVersion with the application's version 
 */
+ (NOBVersion*) appVersion;

/** 
    @return An array of NSNumbers representing all of the version components 
 */
@property (nonatomic, strong, readonly) NSArray* versionComponents;

/** 
    @return the number of version components in the object 
 */
- (NSUInteger) versionComponentCount;
/** 
    @param index the index of the version component
    @return the value of the version component at the provided index.  0 if index is out of bounds. 
 */
- (NSUInteger) versionComponentAtIndex:(NSUInteger)index;
/**
    @return the 0th version component 
 */
- (NSUInteger) majorVersion;
/** 
    @return the 1st version component 
 */
- (NSUInteger) minorVersion;
/** 
    @return the 2nd version component
 */
- (NSUInteger) revisionVersion;
/** 
    @return the 3rd version component
 */
- (NSUInteger) buildVersion;

/** 
    @return the string representation of the version (ex// \@"6.0.1.2") 
 */
- (NSString*) stringValue;
- (NSString*) description;

/** 
    @param otherVersion the version to compare against
    @return an NSComparisonResult 
 */
- (NSComparisonResult) compare:(NOBVersion*)otherVersion;
- (BOOL) isEqual:(id)object;
- (BOOL) isLessThan:(NOBVersion*)otherVersion;
- (BOOL) isGreaterThan:(NOBVersion*)otherVersion;
- (BOOL) isLessThanOrEqual:(NOBVersion*)otherVersion;
- (BOOL) isGreaterThanOrEqual:(NOBVersion*)otherVersion;

@end

@interface NOBVersion (OSVersion)
/** 
    Convenience static mehtod for getting the OS' version
    @return the OS Version 
 */
+ (NOBVersion*) osVersion;
@end

