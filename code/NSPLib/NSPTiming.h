//
//  NSPTiming.h
//  NSPLib
//
//  Created by Nolan O'Brien on 7/5/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NSTimeIntervalUnknown NSTimeIntervalSince1970

BOOL StartTiming(NSString* timingId); // returns false if already started
NSTimeInterval CheckTimeElapsed(NSString* timingId);
NSTimeInterval StopTiming(NSString* timingId);
NSTimeInterval ExecuteTimedBlock(GenericBlock block);

#define LogStart(logLevel, timingId)      do { BOOL start__ = StartTiming(timingId); LOG(logLevel, @"%@ %@", (start__ ? @"STARTED" : @"DUPE START"), timingId); } while (0)
#define LogFinish(logLevel, timingId)     do { NSTimeInterval ti__ = StopTiming(timingId); LOG(logLevel, @"FINISHED %@: %.4f seconds", timingId, ti__); } while (0)
#define LogBlock(logLevel, name, block)   do { NSTimeInterval ti__ = ExecuteTimedBlock(block); LOG(logLevel, @"FINISHED %@: %.4f seconds", name, ti__); } while (0)

#ifndef RELEASE
#define LogStartDebug(timingId)           LogStart(NSPLogLevel_LowLevel, timingId)
#define LogFinishDebug(timingId)          LogFinish(NSPLogLevel_LowLevel, timingId)
#define LogBlockDebug(name, block)        LogBlock(NSPLogLevel_LowLevel, name, block)
#else
#define LogStartDebug(timingId)           ((void)0)
#define LogFinishDebug(timingId)          ((void)0)
#define LogBlockDebug(name, block)        ((void)0)
#endif

#define LogMethodStartDebug()             LogStartDebug(NSStringFromSelector(_cmd))
#define LogMethodFinsihDebug()            LogFinishDebug(NSStringFromSelector(_cmd))

@interface NSPTimingObject : NSObject
@property (nonatomic, readonly) NSString* timingId;
- (id) initWithTimingId:(NSString*)timingId;
- (NSTimeInterval) timeElapsed;
@end