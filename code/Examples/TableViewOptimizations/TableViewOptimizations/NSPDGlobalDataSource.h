//
//  NSPDGlobalDataSource.h
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/10/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNSPDGlobalDataSourceNotification_DidLoad @"NSPDGlobalDataSourceDidLoad"

@interface NSPDGlobalDataSource : NSObject

@property (nonatomic, readonly) NSArray* results;

+ (instancetype) globalDataSource; // loads with sychronous network operation

@end
