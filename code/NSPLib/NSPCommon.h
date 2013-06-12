//
//  NSPCommon.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSPObjCUtils.h"

/**
    @def NSPAssert(cond)
    
    On \a DEBUG builds, asserts using NSAssert function with the condition being used as the logged message.
    No-op \a non-DEBUG builds
    @see NSPCAssert(cond)
 */
/**
    @def NSPCAssert(cond)

    On \a DEBUG builds, asserts using NSCAssert function with the condition being used as the logged message.
    No-op \a non-DEBUG builds
    @see NSPAssert(cond)
 */

#ifdef DEBUG
#define NSPAssert(cond)  NSAssert1((cond), @"%@", @""#cond)
#define NSPCAssert(cond) NSCAssert1((cond), @"%@", @""#cond)
#else
#define NSPAssert(cond)  ((void)0)
#define NSPCAssert(cond) ((void)0)
#endif

