//
//  main.m
//  HLSMakerCLI
//
//  Created by Nolan O'Brien on 8/3/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import "HLSMaker.h"

int main(int argc, const char * argv[])
{

    int retVal = 0;
    @autoreleasepool {
        retVal = [HLSMaker execute:argv count:argc];
    }
    return retVal;
}

