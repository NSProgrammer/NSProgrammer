//
//  NOBUILibTests.m
//  NOBUILibTests
//
//  Created by Nolan O'Brien on 11/19/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NOBUILib.h"

@interface NOBUILibCategoryTests : XCTestCase

@end

@implementation NOBUILibCategoryTests

- (void) testUIColor
{
    UIColor* color1 = [UIColor colorWithRGB:0xABCD0123];
    UIColor* color2 = [UIColor colorWithRGBString:@"ABCD0123"];
    XCTAssertEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"abcd0123"];
    XCTAssertEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"0xabcd0123"];
    XCTAssertEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"#abcd0123"];
    XCTAssertEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"xabcd0123"];
    XCTAssertNotEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"abcd 0123"];
    XCTAssertNotEqualObjects(color1, color2, @"");
    
    XCTAssertEqual(color1.rgbValue, 0xABCD0123, @"");
    
    color1 = [UIColor colorWithRGB:0xffCD0123];
    color2 = [UIColor colorWithRGBString:@"ffcd0123"];
    XCTAssertEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"cd0123"];
    XCTAssertEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"fFCd0123"];
    XCTAssertEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"0xcd0123"];
    XCTAssertEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"#cd0123"];
    XCTAssertEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"xcd0123"];
    XCTAssertNotEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"cd 0123"];
    XCTAssertNotEqualObjects(color1, color2, @"");
    color2 = [UIColor colorWithRGBString:@"abcd0123"];
    XCTAssertNotEqualObjects(color1, color2, @"");

    XCTAssertEqual(color1.rgbValue, 0xffCD0123, @"");
}

@end
