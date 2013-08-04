/*
 
 Copyright (C) 2013 Nolan O'Brien
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HLSType) {
    HLSType_CellularMini, // no audio
    HLSType_CellularSlow,
    HLSType_CellularFast,
    HLSType_WifiSlow,
    HLSType_WifiMedium,
    HLSType_WifiFast,
    HLSType_WifiVeryFast
};

static const NSUInteger HLSTypeCount = (HLSType_WifiVeryFast + 1);

HLSType KBPS2HLSType(NSInteger kbps); // returns -1 if the kbps doesn't match
NSArray* GetAllHLSTypes(void);

@interface HLSSettings : NSObject

@property (nonatomic, copy) NSString* sourceFile;
@property (nonatomic, copy) NSString* outputFile;
@property (nonatomic, copy) NSString* outputDirectory;
@property (nonatomic, assign) BOOL stereo; // NO == mono
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, assign) NSUInteger kbps;
@property (nonatomic, assign) NSUInteger videoKbps;

+ (NSArray*) allDefaultHLSSettings:(NSString*)sourceFile outputDirectory:(NSString*)outputDir;
+ (HLSSettings*) settingsForHLSType:(HLSType)type sourceFile:(NSString*)sourceFile outputDirectory:(NSString*)outputDir;

@end
