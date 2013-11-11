//
//  NSPDNetworkOperationQueue.h
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/10/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface NSPDNetworkOperationQueue : NSOperationQueue
+ (instancetype) sharedQueue;
@end

@interface AFURLConnectionOperation (Begin)
- (void) begin;
@end
