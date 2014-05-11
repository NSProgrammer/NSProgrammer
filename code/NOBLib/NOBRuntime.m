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

#import "NOBRuntime.h"
#include <objc/runtime.h>

BOOL NOBSwizzleInstanceMethods(Class class, SEL dstSel, SEL srcSel)
{
    if (!class || !dstSel || !srcSel)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"%@ cannot be NULL!", (!class ? @"class" : (!dstSel ? @"dstSel" : @"srcSel"))]
                                     userInfo:nil];
    }
    
    Method dstMethod = class_getInstanceMethod(class, dstSel);
    Method srcMethod = class_getInstanceMethod(class, srcSel);

    if (!srcMethod)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Missing source method implementation for swizzling!  Class %@, Source: %@, Destination: %@", NSStringFromClass(class), NSStringFromSelector(srcSel), NSStringFromSelector(dstSel)]
                                     userInfo:nil];
    }

    IMP srcIMP = method_getImplementation(srcMethod);
    if (class_addMethod(class, dstSel, srcIMP, method_getTypeEncoding(srcMethod)))
    {
        class_replaceMethod(class, dstSel, method_getImplementation(dstMethod), method_getTypeEncoding(dstMethod));
    }
    else
    {
        method_exchangeImplementations(dstMethod, srcMethod);
    }
    return (srcIMP == method_getImplementation(class_getInstanceMethod(class, dstSel)));
}

BOOL NOBSwizzleStaticMethods(Class class, SEL dstSel, SEL srcSel)
{
    Class metaClass = object_getClass(class);
    
    if (!metaClass || metaClass == class) // the metaClass being the same as class shows that class was already a MetaClass
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"%@ does not have a meta class to swizzle methods on!", NSStringFromClass(class)]
                                     userInfo:nil];
    }
    
    return NOBSwizzleInstanceMethods(metaClass, dstSel, srcSel);
}

@implementation NSObject (Swizzle)

+ (BOOL) swizzleInstanceMethod:(SEL)srcSelector toMethod:(SEL)dstSelector
{
    return NOBSwizzleInstanceMethods([self class], dstSelector, srcSelector);
}

+ (BOOL) swizzleStaticMethod:(SEL)srcSelector toMethod:(SEL)dstSelector
{
    return NOBSwizzleStaticMethods([self class], dstSelector, srcSelector);
}

@end

@implementation NSObject (StaticMethodCheck)

+ (BOOL) respondsToStaticMethodSelector:(SEL)sel
{
    return !!class_getClassMethod(self, sel);
}

@end

@implementation NSObject (Properties)

+ (NSArray*) instanceDeclaredPropertyNames
{
    unsigned int propC = 0;
    objc_property_t* propList = class_copyPropertyList(self, &propC);
    NSMutableArray* propArray = [NSMutableArray arrayWithCapacity:propC];

    for (unsigned int i = 0; i < propC; i++)
    {
        [propArray addObject:[NSString stringWithUTF8String:property_getName(propList[i])]];
    }

    free(propList);
    return [propArray copy];
}

+ (NSArray*) instanceInheritedPropertyNames
{
    Class c = self;
    Class s = class_getSuperclass(c);
    NSMutableArray* array = [NSMutableArray array];
    while (c != s &&
           s != NULL)
    {
        [array addObjectsFromArray:[s instanceDeclaredPropertyNames]];
        c = s;
        s = class_getSuperclass(s);
    }
    return [array copy];
}

+ (NSArray*) instanceAllPropertyNames
{
    return [[self instanceInheritedPropertyNames] arrayByAddingObjectsFromArray:[self instanceDeclaredPropertyNames]];
}

+ (BOOL) instanceHasPropertyNamed:(NSString*)property
{
    Class c = self;
    Class s = class_getSuperclass(c);
    const char* name = property.UTF8String;
    while (c != s &&
           c != NULL)
    {
        if (class_getProperty(c, name))
        {
            return YES;
        }

        c = s;
        s = class_getSuperclass(s);
    }
    return NO;
}

- (BOOL) hasPropertyNamed:(NSString*)property
{
    return [[self class] instanceHasPropertyNamed:property];
}

@end
