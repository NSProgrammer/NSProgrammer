//
//  NSPObjCUtils.h
//  NSPLib
//
//  Created by Nolan O'Brien on 6/9/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Blocks

typedef void(^GenericBlock)(void);

#pragma mark - syncronization

void dispatch_sync_on_main_queue(void (^block)(void));

// dispatch_once requires it's predicate token to be static or global,
// this function can use transient memory, hence trans(ient)_dispatch_once
typedef volatile int32_t trans_dispatch_once_t;
DISPATCH_INLINE DISPATCH_ALWAYS_INLINE DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void trans_dispatch_once(trans_dispatch_once_t* pPredicate, GenericBlock block)
{
    if (OSAtomicCompareAndSwap32(0, 1, pPredicate)) {
        block();
    }
}

#pragma mark - Runtime Manipulation

#pragma mark Swizzling

BOOL NSPSwizzleInstanceMethods(Class class, SEL dstSel, SEL srcSel);
BOOL NSPSwizzleClassMethods(Class class, SEL dstSel, SEL srcSel);

@interface NSObject (Swizzle)

+ (BOOL) swizzleInstanceMethod:(SEL)srcSelector toMethod:(SEL)dstSelector;
+ (BOOL) swizzleClassMethod:(SEL)srcSelector toMethod:(SEL)dstSelector;

@end

#pragma mark Methods

@interface NSObject (StaticMethodCheck)

+ (BOOL) respondsToStaticMethodSelector(SEL sel);

@end

#pragma mark - Compilation Validation and Object Structure

#if __has_feature(objc_arc)
#define ARC_ENABLED 1
#endif

// if a class requires a subclass to implement a method, have the class (not the subclass) use
// UNRECOGNIZED_SELECTOR instead of an implementation.
// Example: void methodToOverride UNRECOGNIZED_SELECTOR <newline> (you can add a ';' at the end without fear too)
#define UNRECOGNIZED_SELECTOR { ThrowUnrecognizedSelector(self, _cmd); }

// Defines a yet undocumented method to add a warning if super isn't called.
// Only use this during static analyzer though since compilater can lead to false warnings at the moment.
#if !defined(NS_REQUIRES_SUPER)
#if __has_attribute(objc_requires_super) && defined(__clang_analyzer__)
#define NS_REQUIRES_SUPER __attribute((objc_requires_super))
#else
#define NS_REQUIRES_SUPER
#endif
#endif

NS_INLINE void ThrowUnrecognizedSelector(NSObject* obj, SEL cmd) __attribute__((noreturn));
NS_INLINE void ThrowUnrecognizedSelector(NSObject* obj, SEL cmd)
{
    [obj doesNotRecognizeSelector:cmd];
    abort(); // will never be reached, but prevents compiler warning
}

#pragma mark - KVO

// Easier to use KVO
#define KVO_BEGIN(key) [self willChangeValueForKey:@"" #key]
#define KVO_END(key)   [self didChangeValueForKey:@"" #key]

#pragma mark - stack memory cleanup

#ifndef ARC_ENABLED
// Instead of using autorelease, you can do a stack released object
// Just declare the variable with this macro
// Ex: STACK_CLEANUP_NSOBJECT(NSString*) tmp = [[NSString alloc] init];
#define STACK_CLEANUP_NSOBJECT(type) __attribute__((cleanup(Cleanup_NSObject))) __attribute__((unused)) type
__attribute__((unused)) NS_INLINE void Cleanup_NSObject(void* o)
{
    [*(id*)o release]; // [0 release] == no-op
}
#endif

// Instead of keeping track of a temporary CFTypeRef object
// Just declare the variable with this macro
// Ex: STACK_CLEANUP_CFOBJECT(CFStringRef) tmp = CFStringCreateCopy(NULL, otherCFString);
#define STACK_CLEANUP_CFTYPE(type) __attribute__((cleanup(Cleanup_CFType))) __attribute__((unused)) type
__attribute__((unused)) NS_INLINE void Cleanup_CFType(void* ptr)
{
    if (*(CFTypeRef*)ptr) { CFRelease(*(CFTypeRef*)ptr); } // CFRelease(0) == crash
}

// Instead of keeping track of you temporarily allocated memory
// you can do a stack freed memory pointer
// Just declare the variable with this macro
// Ex: STACK_CLEANUP_CMEMORY(char*) tmp = (char*)malloc(sizeof(char)*SIZE);
#define STACK_CLEANUP_CMEMORY(type) __attribute__((cleanup(Cleanup_Memory))) __attribute__((unused)) type
__attribute__((unused)) NS_INLINE void Cleanup_Memory(void* ptr)
{
    free(*(void**)ptr); // free(0) == no-op
}

#pragma mark - C Level Helpers

// Comparison of floats/doubles can be problematic using ==.
// These macros help by establishing a margin of error (epsilon)

#define FLOAT_EQ(floatA, floatB, epsilon)  (fabsf(floatA - floatB) < epsilon)
#define FLOAT_LT(floatA, floatB, epsilon)  (!FLOAT_EQ(floatA, floatB, epsilon) && floatA < floatB)
#define FLOAT_GT(floatA, floatB, epsilon)  (!FLOAT_EQ(floatA, floatB, epsilon) && floatA > floatB)
#define FLOAT_LTE(floatA, floatB, epsilon) (FLOAT_EQ(floatA, floatB, epsilon) || floatA < floatB)
#define FLOAT_GTE(floatA, floatB, epsilon) (FLOAT_EQ(floatA, floatB, epsilon) || floatA > floatB)

#define DOUBLE_EQ(floatA, floatB, epsilon)  (fabs(floatA - floatB) < epsilon)
#define DOUBLE_LT(floatA, floatB, epsilon)  (!FLOAT_EQ(floatA, floatB, epsilon) && floatA < floatB)
#define DOUBLE_GT(floatA, floatB, epsilon)  (!FLOAT_EQ(floatA, floatB, epsilon) && floatA > floatB)
#define DOUBLE_LTE(floatA, floatB, epsilon) (FLOAT_EQ(floatA, floatB, epsilon) || floatA < floatB)
#define DOUBLE_GTE(floatA, floatB, epsilon) (FLOAT_EQ(floatA, floatB, epsilon) || floatA > floatB)
