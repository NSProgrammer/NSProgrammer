//
//  NSPCommon.h
//  Library
//
//  Created by Nolan O'Brien on 5/20/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <UIKit/UIKit.h>

BOOL NSPSwizzleInstanceMethods(Class class, SEL dstSel, SEL srcSel);
BOOL NSPSwizzleClassMethods(Class class, SEL dstSel, SEL srcSel);

@interface NSObject (Swizzle)

+ (BOOL) swizzleInstanceMethod:(SEL)srcSelector toMethod:(SEL)dstSelector;
+ (BOOL) swizzleClassMethod:(SEL)srcSelector toMethod:(SEL)dstSelector;

@end
