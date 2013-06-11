//
//  NSPObjCUtils.m
//  NSPLib
//
//  Created by Nolan O'Brien on 6/9/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSPObjCUtils.h"
#include <objc/runtime.h>

void dispatch_sync_on_main_queue(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

BOOL NSPSwizzleInstanceMethods(Class class, SEL dstSel, SEL srcSel)
{
    Method dstMethod = class_getInstanceMethod(class, dstSel);
    Method srcMethod = class_getInstanceMethod(class, srcSel);
    
    if (!srcMethod)
    {
        @throw [NSException exceptionWithName:@"InvalidParameter"
                                       reason:[NSString stringWithFormat:@"Missing source method implementation for swizzling!  Class %@, Source: %@, Destination: %@", NSStringFromClass(class), NSStringFromSelector(srcSel), NSStringFromSelector(dstSel)]
                                     userInfo:nil];
    }
    
    if (class_addMethod(class, dstSel, method_getImplementation(srcMethod), method_getTypeEncoding(srcMethod)))
    {
        class_replaceMethod(class, dstSel, method_getImplementation(dstMethod), method_getTypeEncoding(dstMethod));
    }
    else
    {
        method_exchangeImplementations(dstMethod, srcMethod);
    }
    return (srcMethod == class_getInstanceMethod(class, dstSel));
}

BOOL NSPSwizzleClassMethods(Class class, SEL dstSel, SEL srcSel)
{
    Class metaClass = object_getClass(class);
    
    if (!metaClass || metaClass == class) // the metaClass being the same as class shows that class was already a MetaClass
    {
        @throw [NSException exceptionWithName:@"InvalidParameter"
                                       reason:[NSString stringWithFormat:@"%@ does not have a meta class to swizzle methods on!", NSStringFromClass(class)]
                                     userInfo:nil];
    }
    
    return NSPSwizzleInstanceMethods(metaClass, dstSel, srcSel);
}

@implementation NSObject (Swizzle)

+ (BOOL) swizzleInstanceMethod:(SEL)srcSelector toMethod:(SEL)dstSelector
{
    return NSPSwizzleInstanceMethods([self class], dstSelector, srcSelector);
}

+ (BOOL) swizzleClassMethod:(SEL)srcSelector toMethod:(SEL)dstSelector
{
    return NSPSwizzleClassMethods([self class], dstSelector, srcSelector);
}

@end

@implementation NSObject (StaticMethodCheck)

+ (BOOL) respondsToStaticMethodSelector:(SEL)sel
{
    return !!class_getClassMethod(self, sel);
}

@end
