//
//  HMHLSSettings.h
//  HLSMakerCLI
//
//  Created by Nolan O'Brien on 8/3/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HLSType) {
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
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, assign) NSUInteger kbps;
@property (nonatomic, assign) NSUInteger videoKbps;

+ (NSArray*) allDefaultHLSSettings:(NSString*)sourceFile outputDirectory:(NSString*)outputDir widescreen:(BOOL)widescreen;
+ (HLSSettings*) settingsForHLSType:(HLSType)type sourceFile:(NSString*)sourceFile outputDirectory:(NSString*)outputDir widescreen:(BOOL)widescreen;

@end
