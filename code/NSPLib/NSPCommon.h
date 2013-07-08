//
//  NSPCommon.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

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

