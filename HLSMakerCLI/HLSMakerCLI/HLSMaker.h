//
//  HLSMaker.h
//  HLSMakerCLI
//
//  Created by Nolan O'Brien on 8/4/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMArgs.h"

@interface HLSMaker : NSObject

+ (int) execute:(const char**)argv count:(int)argc;
- (int) execute:(const char**)argv count:(int)argc;

@end
