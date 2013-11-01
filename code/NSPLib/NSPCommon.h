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
#import "NSPRuntime.h"

/**
    @def NSPAssert(cond)
    
    @par On \c DEBUG builds, asserts using \c NSAssert function with the condition being used as the logged message.
    @par No-op \c non-DEBUG builds
    @see NSPCAssert(cond)
 */
/**
    @def NSPCAssert(cond)

    @par On \c DEBUG builds, asserts using \c NSCAssert function with the condition being used as the logged message.
    @par No-op \c non-DEBUG builds
    @see NSPAssert(cond)
 */

#ifdef DEBUG
#define NSPAssert(cond)  NSAssert1((cond), @"%@", @""#cond)
#define NSPCAssert(cond) NSCAssert1((cond), @"%@", @""#cond)
#else
#define NSPAssert(cond)  ((void)0)
#define NSPCAssert(cond) ((void)0)
#endif

