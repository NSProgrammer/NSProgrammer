//
//  NSPConversion.m
//  NSPLib
//
//  Created by Nolan O'Brien on 6/9/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSPConversion.h"

#pragma mark - Angles

#define DEGREES_TO_RADIANS(angle)          (((angle) / 180.0) * M_PI)
#define RADIANS_TO_DEGREES(radian)         (((radian) / M_PI) * 180.0)


#pragma mark - Time

#define MINS_2_SECS(x)                     ((x) * 60)

#define HOURS_2_MINS(x)                    ((x) * 60)
#define HOURS_2_SECS(x)                    (MINS_2_SECS(HOURS_2_MINS(x)))

#define DAYS_2_HOURS(x)                    ((x) * 24)
#define DAYS_2_MINS(x)                     (HOURS_2_MINS(DAYS_2_HOURS(x)))
#define DAYS_2_SECS(x)                     (MINS_2_SECS(DAYS_2_MINS(x)))


