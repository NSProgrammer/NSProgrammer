//
//  NSPCommon.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSPObjCUtils.h"

#ifdef DEBUG
#define NSPAssert(x)  NSAssert1((x), @"%@", @""#x)
#define NSPCAssert(x) NSCAssert1((x), @"%@", @""#x)
#else
#define NSPAssert(x)  ((void)0)
#define NSPCAssert(x) ((void)0)
#endif

