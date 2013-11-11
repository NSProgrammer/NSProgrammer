//
//  NSPDNetworkOperationQueue.m
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/10/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import "NSPDNetworkOperationQueue.h"


@implementation NSPDNetworkOperationQueue

+ (instancetype) sharedQueue
{
    static __strong NSPDNetworkOperationQueue* s_q = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_q = [[NSPDNetworkOperationQueue alloc] init];
    });
    return s_q;
}

- (instancetype) init
{
    if (self = [super init])
    {
        self.maxConcurrentOperationCount = 1;
    }
    return self;
}

@end

@implementation AFURLConnectionOperation (Begin)

- (void) begin
{
    [[NSPDNetworkOperationQueue sharedQueue] addOperation:self];
}

@end
