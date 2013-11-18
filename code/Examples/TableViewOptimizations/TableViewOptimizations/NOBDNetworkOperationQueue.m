//
//  NOBDNetworkOperationQueue.m
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/10/13.
//  Copyright (c) 2013 NOBrogrammer. All rights reserved.
//

#import "NOBDNetworkOperationQueue.h"


@implementation NOBDNetworkOperationQueue

+ (instancetype) sharedQueue
{
    static __strong NOBDNetworkOperationQueue* s_q = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_q = [[NOBDNetworkOperationQueue alloc] init];
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
    [[NOBDNetworkOperationQueue sharedQueue] addOperation:self];
}

@end
