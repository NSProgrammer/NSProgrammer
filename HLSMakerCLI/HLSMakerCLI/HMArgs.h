//
//  HMArgs.h
//  HLSMakerCLI
//
//  Created by Nolan O'Brien on 8/3/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMArgs : NSObject

@property (nonatomic, copy) NSString* executablePath;
@property (nonatomic, copy) NSString* sourceFile;       // -i
@property (nonatomic, copy) NSString* outputDirectory;  // -o default is current execution directory
@property (nonatomic, copy) NSString* baseName;         // -b default is outputDirectory.lastPathComponent
@property (nonatomic, copy) NSArray* hlsTypes;          // -t NSArray<NSNumber<HLSType>> ; default is ALL HLSTypes
@property (nonatomic, copy) NSString* handbrakePath;    // -h default tries current execution directory, then /usr/bin
@property (nonatomic, copy) NSString* mediafilesegmenterPath; // -m default tries current execution directory, then /usr/bin
@property (nonatomic, copy) NSNumber* widescreen; // -r @"widescreen" or @"standard" ; maintained as NSNumber<BOOL>; default is auto-detect

- (NSArray*) validate; // returns an array of errors

@end
