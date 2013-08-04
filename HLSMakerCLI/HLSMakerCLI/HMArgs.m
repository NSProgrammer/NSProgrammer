//
//  HMArgs.m
//  HLSMakerCLI
//
//  Created by Nolan O'Brien on 8/3/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import "HMArgs.h"
#import "HLSSettings.h"

@implementation HMArgs

- (NSArray*) validate
{
    NSMutableArray* errors = [[NSMutableArray alloc] init];

    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* currentPath = [fm currentDirectoryPath];
    if (!self.outputDirectory)
        self.outputDirectory = currentPath;
    if (!self.baseName)
        self.baseName = self.outputDirectory.lastPathComponent;
    if (!self.handbrakePath)
    {
        NSString* file = @"HandBrakeCLI";
        NSString* path = [currentPath stringByAppendingPathComponent:file];
        if ([fm fileExistsAtPath:path])
        {
            self.handbrakePath = path;
        }
        else
        {
            path = [@"/usr/bin" stringByAppendingPathComponent:file];
            if ([fm fileExistsAtPath:path])
            {
                self.handbrakePath = path;
            }
        }
    }
    if (!self.mediafilesegmenterPath)
    {
        NSString* file = @"mediafilesegmenter";
        NSString* path = [currentPath stringByAppendingPathComponent:file];
        if ([fm fileExistsAtPath:path])
        {
            self.mediafilesegmenterPath = path;
        }
        else
        {
            path = [@"/usr/bin" stringByAppendingPathComponent:file];
            if ([fm fileExistsAtPath:path])
            {
                self.mediafilesegmenterPath = path;
            }
        }
    }
    if (self.hlsTypes.count == 0)
    {
        self.hlsTypes = GetAllHLSTypes();
    }

    BOOL isDir;
    if (!self.sourceFile)
        [errors addObject:[NSError errorWithDomain:NSArgumentDomain code:ENOEXEC userInfo:@{@"missingArgument" : @"-i"}]];
    else
    {
        if (![self.sourceFile hasPrefix:@"/"])
            self.sourceFile = [currentPath stringByAppendingPathComponent:self.sourceFile];
        if (![fm fileExistsAtPath:self.sourceFile isDirectory:&isDir] || isDir)
            [errors addObject:[NSError errorWithDomain:NSArgumentDomain code:EINVAL userInfo:@{ @"argument" : @"-i", @"value" : self.sourceFile}]];
    }

    if (![self.outputDirectory hasPrefix:@"/"])
        self.outputDirectory = [currentPath stringByAppendingPathComponent:self.outputDirectory];
    if (![fm fileExistsAtPath:self.outputDirectory isDirectory:&isDir] || !isDir)
        [errors addObject:[NSError errorWithDomain:NSArgumentDomain code:EINVAL userInfo:@{ @"argument" : @"-o", @"value" : self.outputDirectory}]];
    
    NSMutableSet* hlsHits = [[NSMutableSet alloc] init];
    BOOL hlsFail = NO;
    for (NSNumber* hlsType in self.hlsTypes)
    {
        if (hlsType.integerValue >= HLSTypeCount)
        {
            hlsFail = YES;
            break;
        }

        if ([hlsHits containsObject:hlsType])
        {
            hlsFail = YES;
            break;
        }
    }
    if (hlsFail)
    {
        [errors addObject:[NSError errorWithDomain:NSArgumentDomain code:EINVAL userInfo:@{ @"argument" : @"-t", @"value" : self.hlsTypes}]];
    }
    if (![fm fileExistsAtPath:self.handbrakePath isDirectory:&isDir] || isDir)
        [errors addObject:[NSError errorWithDomain:NSArgumentDomain code:EINVAL userInfo:@{ @"argument" : @"-h", @"value" : self.handbrakePath}]];
    if (![fm fileExistsAtPath:self.mediafilesegmenterPath isDirectory:&isDir] || isDir)
        [errors addObject:[NSError errorWithDomain:NSArgumentDomain code:EINVAL userInfo:@{ @"argument" : @"-m", @"value" : self.mediafilesegmenterPath}]];

    return errors;
}

- (NSString*) description
{
    NSMutableDictionary* d = [[NSMutableDictionary alloc] init];

    if (self.executablePath)
        [d setObject:self.executablePath forKey:@"executablePath"];
    if (self.sourceFile)
        [d setObject:self.sourceFile forKey:@"sourceFile"];
    if (self.outputDirectory)
        [d setObject:self.outputDirectory forKey:@"outputDirectory"];
    if (self.baseName)
        [d setObject:self.baseName forKey:@"baseName"];
    if (self.hlsTypes)
        [d setObject:self.hlsTypes forKey:@"hlsTypes"];
    if (self.handbrakePath)
        [d setObject:self.handbrakePath forKey:@"handbrakePath"];
    if (self.mediafilesegmenterPath)
        [d setObject:self.mediafilesegmenterPath forKey:@"mediafilesegmenterPath"];
    if (self.widescreen)
        [d setObject:self.widescreen forKey:@"widescreen"];
    
    return d.description;
}

@end
