//
//  NSTask+EasyExecute.h
//  HLSMakerCLI
//
//  Created by Nolan O'Brien on 8/3/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTask (EasyExecute)
+ (NSString*) executeAndReturnStdOut:(NSString*)taskPath arguments:(NSArray*)args;
+ (NSString*) executeAndReturnStdOut:(NSString*)taskPath arguments:(NSArray*)args withMaxStringLength:(NSUInteger)strLen; // not guaranteed
@end
