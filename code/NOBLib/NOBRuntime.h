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
#import <libkern/OSAtomic.h>

#pragma mark - Blocks

/**
    Easy to use typedef for \c void \c void blocks
 */
typedef void(^GenericBlock)(void);

#pragma mark - syncronization

/**
    Run a block synchronously on the main queue.
 */
void dispatch_sync_on_main_queue(void (^block)(void));

/**
    The type for the token used in the \c dispatch_once_transient function
 */
typedef volatile int32_t dispatch_once_transient_t;

#define SHRT_DPTCH_PRFX DISPATCH_INLINE DISPATCH_ALWAYS_INLINE DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
/**
    the OS provided \c dispatch_once requires it's predicate token to be static or global.  \c dispatch_once_transient offers a way to use a token in transient memory for dispatch once within the context of that transient memory's scope.  This is highly effective for dispatching once per object instance vs once globally.
    @code
    - (void) viewWillAppear:(BOOL)animated
    {
        [super viewWillAppear:animated];
        dispatch_once_transient(&_memberTransDispatchOnceToken, ^() {
            // ... dispatch once on first appearance code ...
        });
    }
    @endcode
    @param pPredicate a reference to the predicate token for single use dispatch.  Initialize this value to 0 before using \c dispatch_once_transient.
    @param block the block to execute only once for the instance of \a pPredicate
 */
SHRT_DPTCH_PRFX void dispatch_once_transient(dispatch_once_transient_t* pPredicate, GenericBlock block)
{
    if (OSAtomicCompareAndSwap32(0, 1, pPredicate)) {
        block();
    }
}

#pragma mark - Runtime Manipulation

#pragma mark Swizzling

/**
    Swizzle an instance method on a target class
    @param class the class to swizzle
    @param dstSel the destination selector to swizzle "out".  Must not be \c NULL.  If \a dstSel is not a valid selector on \a class, \a srcSel will be duplicated onto the class as \a dstSel causing there to be two methods for \a srcSel located at both \a srcSel and \a dstSel.
    @param srcSel the source selector to swizzle "in".  Must not be \c NULL.  Does not need to actually exist for the class.
    @return \c YES on success, \c NO on failure
    @warning throws \c NSInvalidArgumentException if \a class, \a dstSel, or \a srcSel are \c NULL.
    @warning throws \c NSInvalidArgumentException if \a srcSel is not implemented on \a class.
    @see NOBSwizzleStaticMethods
 */
BOOL NOBSwizzleInstanceMethods(Class class, SEL dstSel, SEL srcSel);
/**
    Swizzle an instance method on a target class
    @param class the class to swizzle
    @param dstSel - same as in \c NOBSwizzleInstanceMethods, but for a static method
    @param srcSel - same as in \c NOBSwizzleInstanceMethods, but for a static method
    @return \c YES on success, \c NO on failure
    @warning throws \c NSInvalidArgumentException if \a class, \a dstSel, or \a srcSel are \c NULL.
    @warning throws \c NSInvalidArgumentException if \a srcSel is not implemented on \a class.
    @warning throws \c NSInvalidArgumentException if \a class class is a \a meta \a class (Ex: [[NSString class] class]).
    @see NOBSwizzleInstanceMethods
 */
BOOL NOBSwizzleStaticMethods(Class class, SEL dstSel, SEL srcSel);

@interface NSObject (Swizzle)

/**
    Object oriented exposure of \c NOBSwizzleInstanceMethods.
    @see NOBSwizzleInstanceMethods
 */
+ (BOOL) swizzleInstanceMethod:(SEL)srcSelector toMethod:(SEL)dstSelector;
/**
    Object oriented exposure of \c NOBSwizzleStaticMethods.
    @see NOBSwizzleStaticMethods
 */
+ (BOOL) swizzleStaticMethod:(SEL)srcSelector toMethod:(SEL)dstSelector;

@end

#pragma mark Methods

@interface NSObject (StaticMethodCheck)

/**
    Determine if a class has a static method
    @param sel the selector to check is implemented as a static method on the target \c class
    @return \c YES if \a sel exists, \c NO if not
 */
+ (BOOL) respondsToStaticMethodSelector:(SEL)sel;

@end

/**
    @def EXTRACT_FUNCTION_POINTER(object, selector, outputPrefix, retType, ...)
    A helper macro for when you need access to a method at a primitive level that does NOT return an object  ( i.e. \c id )
    @par Input:
    @code
    object - the target object
    selector - the selector to extract as a function pointer
    outputPrefix - the unique prefix for pulling out the necessary variables
    retType - the return type of the desired function pointer
    ... - the argument types of the desired function pointer (excluding the self and selector arguments)
    @endcode
    @par Output:
    @code
    SEL <outputPrefix>SEL;
    Method <outputPrefix>Method;
    IMP <outputPrefix>IMP;
    function pointer <outputPrefix>FP;
    @endcode
    @par Example:
    @code
    #include <objc/message.h>
    \@implementation NSString (Example)
    - (NSUInteger) badExampleOfFindIndexOfCharacter:(unichar)c
    {
        EXTRACT_FUNCTION_POINTER(self, @selector(characterAtIndex:), characterAtIndex_, unichar, NSUInteger)
 
        for (NSUInteger i = 0; i < self.length; i++)
        {
            if (c == characterAtIndex_FP(self, characterAtIndex_SEL, i)
                return i;
        }
        return NSNotFound;
    }
    @endcode
    @note If the method returns an object, just use [<object> methodForSelector:@selector(<selName>)](<object>, @selector(<selName>), ...)
 */
#define EXTRACT_FUNCTION_POINTER(object, selector, outputPrefix, retType, ...) \
SEL outputPrefix##SEL = selector; \
Method outputPrefix##Method = class_getInstanceMethod([object class], outputPrefix##SEL); \
IMP outputPrefix##IMP = method_getImplementation(outputPrefix##Method); \
TYPEDEF_FUNCTION_PTR(outputPrefix##FunctionPointer, retType, id, SEL, ##__VA_ARGS__); \
outputPrefix##FunctionPointer outputPrefix##FP = (outputPrefix##FunctionPointer)outputPrefix##IMP;

#pragma mark - Properties

@interface NSObject (Properties)

/**
    @returns all property names declared by the receiving class.
 */
+ (NSArray*) instanceDeclaredPropertyNames;
/**
    @returns all property names inherited by the receiving class.
 */
+ (NSArray*) instanceInheritedPropertyNames;
/**
    @returns all property names declared AND inherited by the receiving class.
 */
+ (NSArray*) instanceAllPropertyNames;

/**
    @returns \c YES iff the the receiving class' instances have the provided \a property.
 */
+ (BOOL) instanceHasPropertyNamed:(NSString*)property;
/**
    @returns \c YES iff the the receiving object has the provided \a property.
 */
- (BOOL) hasPropertyNamed:(NSString*)property; // returns YES if the instance has a declared or inherited property name

@end

#pragma mark - Compilation Validation and Object Structure

#if __has_feature(objc_arc)
#define ARC_ENABLED 1
#endif

/**
    @def NS_UNRECOGNIZED_SELECTOR
    An easy to use macro to replace boylerplate code for implementing a method that wants to be overridden so it throws an \c NSInvalidArgumentException.
    @par Example:
    @code
    - (void) methodToOverride NS_UNRECOGNIZED_SELECTOR; // ';' is optional but can help with auto code alignement
    @endcode
 */
#define NS_UNRECOGNIZED_SELECTOR { ThrowUnrecognizedSelector(self, _cmd); }
NS_INLINE void ThrowUnrecognizedSelector(NSObject* obj, SEL cmd) __attribute__((noreturn));
NS_INLINE void ThrowUnrecognizedSelector(NSObject* obj, SEL cmd)
{
    [obj doesNotRecognizeSelector:cmd];
    abort(); // will never be reached, but prevents compiler warning
}

// Defines a yet undocumented method to add a warning if super isn't called.
// Only use this during static analyzer though since compilater can lead to false warnings at the moment.
#if !defined(NS_REQUIRES_SUPER)
#if __has_attribute(objc_requires_super) && defined(__clang_analyzer__)
#define NS_REQUIRES_SUPER __attribute((objc_requires_super))
#else
#define NS_REQUIRES_SUPER
#endif
#endif


#pragma mark - KVO

/**
    @def KVO_BEGIN(key)
    easy to use beginning of KVO
    @param key the name of the key to begin the KVO flow: i.e. \c willChangeValueForKey:
 */
#define KVO_BEGIN(key) [self willChangeValueForKey:@"" #key]
/**
    @def KVO_END(key)
    easy to use ending of KVO
    @param key the name of the key to end the KVO flow: i.e. \c didChangeValueForKey:
 */
#define KVO_END(key)   [self didChangeValueForKey:@"" #key]

#pragma mark - stack memory cleanup

#ifndef ARC_ENABLED
/**
    @def STACK_CLEANUP_NSOBJECT(type)
    Simple macro for using the stack to cleanup an Objective-C object instead of the autorelease pool.
    @par Example:
    @code
    STACK_CLEANUP_NSOBJECT(NSString*) tmp = [[NSString alloc] init];
    @endcode
 */
#define STACK_CLEANUP_NSOBJECT(type) __attribute__((cleanup(Cleanup_NSObject))) __attribute__((unused)) type
__attribute__((unused)) NS_INLINE void Cleanup_NSObject(void* o)
{
    [*(id*)o release]; // [0 release] == no-op
}
#endif

/**
     @def STACK_CLEANUP_CFTYPE(type)
     Simple macro for using the stack to cleanup a Core Foundation object
     @par Example:
     @code
     STACK_CLEANUP_CFTYPE(CFStringRef) tmp = CFStringCreateCopy(NULL, otherCFString);
     @endcode
 */
#define STACK_CLEANUP_CFTYPE(type) __attribute__((cleanup(Cleanup_CFType))) __attribute__((unused)) type
__attribute__((unused)) NS_INLINE void Cleanup_CFType(void* ptr)
{
    if (*(CFTypeRef*)ptr) { CFRelease(*(CFTypeRef*)ptr); } // CFRelease(0) == crash
}

/**
     @def STACK_CLEANUP_CMEMORY(type)
     Simple macro for using the stack to cleanup \c C allocated memory
     @par Example:
     @code
     STACK_CLEANUP_CMEMORY(char*) tmp = (char*)malloc(sizeof(char)*SIZE);
     @endcode
 */
#define STACK_CLEANUP_CMEMORY(type) __attribute__((cleanup(Cleanup_Memory))) __attribute__((unused)) type
__attribute__((unused)) NS_INLINE void Cleanup_Memory(void* ptr)
{
    free(*(void**)ptr); // free(0) == no-op
}

#pragma mark - C Level Helpers

/**
    @def TYPEDEF_FUNCTION_PTR(name, retType, ...)
    Easy to use macro for decalring a function pointer type
 */
#define TYPEDEF_FUNCTION_PTR(name, retType, ...) \
typedef retType (* name)(__VA_ARGS__)


/**
    @section Floating Point Comparison Macros
 */
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
