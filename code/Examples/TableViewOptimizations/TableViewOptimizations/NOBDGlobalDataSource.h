//
//  NOBDGlobalDataSource.h
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/10/13.
//  Copyright (c) 2013 NOBrogrammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNOBDGlobalDataSourceNotification_DidLoad @"NOBDGlobalDataSourceDidLoad"

@interface NOBDGlobalDataSource : NSObject

@property (nonatomic, readonly) NSArray* results;

+ (instancetype) globalDataSource; // loads with sychronous network operation

@end
