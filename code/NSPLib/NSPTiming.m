//
//  NSPTiming.m
//  NSPLib
//
//  Created by Nolan O'Brien on 7/5/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSPTiming.h"

static NSMutableDictionary* s_times = nil;
static dispatch_queue_t s_timesQueue = 0;
static const char s_timesName[] = "NSPTimingQueue";

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

@implementation NSPTimingObject

- (id) initWithTimingId:(NSString *)timingId
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
