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