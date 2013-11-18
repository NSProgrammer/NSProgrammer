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

#import "NOBTiming.h"

static NSMutableDictionary* s_times = nil;
static dispatch_queue_t s_timesQueue = 0;
static const char s_timesName[] = "NOBTimingQueue";

BOOL StartTiming(NSString* timingId)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_times = [[NSMutableDictionary alloc] init];
        s_timesQueue = dispatch_queue_create(s_timesName, DISPATCH_QUEUE_CONCURRENT);
    });

    if (!timingId)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"timingId cannot be nil"
                                     userInfo:nil];
    }

    NSDate* date = [NSDate date];
    __block NSDate* otherDate;
    dispatch_barrier_sync(s_timesQueue, ^() {
        otherDate = [s_times objectForKey:timingId];
        if (!otherDate)
            [s_times setObject:date forKey:timingId];
    });
    return !otherDate;
}

NSTimeInterval CheckTimeElapsed(NSString* timingId)
{
    if (!timingId)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"timingId cannot be nil"
                                     userInfo:nil];
    }
    
    __block NSDate* date;
    dispatch_sync(s_timesQueue, ^() {
        date = [s_times objectForKey:timingId];
    });
    return (date ? [[NSDate date] timeIntervalSinceDate:date] : NSTimeIntervalUnknown);
}

NSTimeInterval StopTiming(NSString* timingId)
{
    if (!timingId)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"timingId cannot be nil"
                                     userInfo:nil];
    }

    __block NSDate* date;
    dispatch_barrier_sync(s_timesQueue, ^() {
        date = [s_times objectForKey:timingId];
        if (date)
            [s_times removeObjectForKey:timingId];
    });
    return (date ? [[NSDate date] timeIntervalSinceDate:date] : NSTimeIntervalUnknown);
}

NSTimeInterval ExecuteTimedBlock(GenericBlock block)
{
    NSDate* date = [NSDate date];
    block();
    return [[NSDate date] timeIntervalSinceDate:date];
}

@implementation NOBTimingObject

- (instancetype) initWithTimingId:(NSString *)timingId
{
    if (self = [super init])
    {
        _timingId = timingId;
        StartTiming(timingId);
    }
    return self;
}

- (NSTimeInterval) timeElapsed
{
    return CheckTimeElapsed(_timingId);
}

- (void)dealloc
{
    StopTiming(_timingId);
}

@end
