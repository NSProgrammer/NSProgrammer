//
//  NOBDNetworkOperationQueue.h
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/10/13.
//  Copyright (c) 2013 NOBrogrammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface NOBDNetworkOperationQueue : NSOperationQueue
+ (instancetype) sharedQueue;
@end

@interface AFURLConnectionOperation (Begin)
- (void) begin;
@end
