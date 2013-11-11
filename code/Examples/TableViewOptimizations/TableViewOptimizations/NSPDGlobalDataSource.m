//
//  NSPDGlobalDataSource.m
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/10/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import "NSPDGlobalDataSource.h"
#import "AFNetworking.h"

@implementation NSPDGlobalDataSource

+ (instancetype) globalDataSource
{
    static __strong NSPDGlobalDataSource* s_gds;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_gds = [[NSPDGlobalDataSource alloc] init];
        [s_gds loadAsynchronously];
    });
    return s_gds;
}

- (void) loadAsynchronously
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://itunes.apple.com/search?media=movie&entity=movie&term=Harrison+Ford"]];
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:&response
                                                         error:&error];
        AFJSONResponseSerializer* responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:0];
        NSDictionary* responseObject = [responseSerializer responseObjectForResponse:response
                                                                                data:data
                                                                               error:&error];
        dispatch_async(dispatch_get_main_queue(), ^() {
            _results = [responseObject objectForKey:@"results"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNSPDGlobalDataSourceNotification_DidLoad object:self];
        });
    });
}

@end
