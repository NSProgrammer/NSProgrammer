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

#import "HLSMaker.h"
#import "HLSSettings.h"
#import "NSTask+EasyExecute.h"

@interface HLSMaker ()
@property (nonatomic, retain) HMArgs* args;
@property (nonatomic, assign) CGSize  originalSize;
@property (nonatomic, assign) double  aspectRatio;

- (int) createMasterManifest:(NSArray*)settingsList;
- (int) createHLSFiles:(HLSSettings*)settings;
- (int) convertVideo:(HLSSettings*)settings;
- (int) execute;

+ (HMArgs*) argsWithCommandLineArgs:(const char**)argv count:(int)argc errors:(NSArray**)errors;
- (void) printUsage;
@end

@implementation HLSMaker

+ (HMArgs*) argsWithCommandLineArgs:(const char**)argv count:(int)argc errors:(NSArray**)errors
{
    HMArgs* args = [[HMArgs alloc] init];
    NSMutableArray* errs = [[NSMutableArray alloc] init];
    
    if (argc > 0)
        args.executablePath = [NSString stringWithCString:argv[0] encoding:NSASCIIStringEncoding];
    
    if (argc == 2)
        args.sourceFile = [NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding];
    else
    {
        for (int i = 1; i < argc-1; i++)
        {
            UniChar flag = 0;
            NSString* value = nil;
            
            NSString* arg = [NSString stringWithCString:argv[i] encoding:NSASCIIStringEncoding];
            if ([arg hasPrefix:@"-"])
            {
                if (arg.length == 2)
                {
                    flag = [arg characterAtIndex:1];
                    i++;
                    value = [NSString stringWithCString:argv[i] encoding:NSASCIIStringEncoding];
                }
            }
            
            if (flag)
            {
                BOOL dupe = NO;
#define ASSIGN(name, flag) \
case flag: \
{ \
if (!args.name) \
args.name = value; \
else \
dupe = YES; \
break; \
}
                
                switch (flag)
                {
                        ASSIGN(sourceFile, 'i')
                        ASSIGN(outputDirectory, 'o')
                        ASSIGN(baseName, 'b')
                        ASSIGN(handbrakePath, 'h')
                        ASSIGN(mediafilesegmenterPath, 'm')
                    case 't':
                    {
                        if (args.hlsTypes)
                        {
                            dupe = YES;
                            break;
                        }
                        NSArray* types = [value componentsSeparatedByString:@","];
                        NSMutableArray* vals = [[NSMutableArray alloc] init];
                        for (NSString* type in types)
                        {
                            HLSType hslType = KBPS2HLSType(type.integerValue);
                            if (hslType >= HLSTypeCount)
                            {
                                flag = 0;
                                break;
                            }
                            [vals addObject:@(hslType)];
                        }
                        
                        if (flag)
                        {
                            args.hlsTypes = vals;
                        }
                        break;
                    }
                    default:
                    {
                        flag = 0;
                        break;
                    }
                }
#undef ASSIGN
                
                if (dupe)
                {
                    [errs addObject:[NSError errorWithDomain:NSArgumentDomain code:EEXIST userInfo:@{ @"argument" : arg, @"value" : value }]];
                }
            }
            
            if (!flag)
            {
                [errs addObject:[NSError errorWithDomain:NSArgumentDomain code:EINVAL userInfo:(value ? @{ @"argument" : arg, @"value" : value } : @{ @"argument" : arg })]];
            }
        }
    }
    
    if (errs.count == 0)
        [errs addObjectsFromArray:[args validate]];
    
    if (errs.count > 0)
    {
        if (errors)
            *errors = [errs copy];
    }
    
    return args;
}

- (void) printUsage
{
    printf("\n%s -i INPUT_FILE [-o OUTPUT_DIRECTORY] [-b OUTPUT_BASE_NAME] [-t HLS_TYPES] [-h HANDBRAKE_CLI_PATH] [-m MEDIAFILESEGMENTER_PATH]\n\n"\
           "\t-i\tThe input video file, preferrably 720p or better\n\n"\
           "\t-o\tThe output directory where the output files will live\n\n"\
           "\t-b\tThe base name for files created in the output directory, default is the output directory's name\n\n"\
           "\t-t\tA comma separated string of the desired HTTP Live Streams based on their speed in kilobits per second\n\t\t(possible values: 64,150,320,640,1280,1920,2560  - default is ALL)\n\n"\
           "\t-h\tThe location on disk of the HandBrakeCLI executable - default will check the current directory then the /usr/bin directory.  See http://handbrake.fr\n\n"\
           "\t-m\tThe location on disk of the mediafilesegmenter executable - default will check the current directory then the /usr/bin directory.  See https://developer.apple.com/downloads/index.action?=http%%20live%%20streaming%%20tools\n\n", self.args.executablePath.lastPathComponent.UTF8String);
}

+ (int) execute:(const char**)argv count:(int)argc
{
    return [[[HLSMaker alloc] init] execute:argv count:argc];
}

- (int) execute:(const char**)argv count:(int)argc
{
    int retVal = 0;
    BOOL printUsage = NO;
    NSArray* errors = nil;
    self.args = [HLSMaker argsWithCommandLineArgs:argv count:argc errors:&errors];
    
    if (!self.args || errors)
    {
        for (NSError* error in errors)
        {
            printf("%s\n", error.description.UTF8String);
        }
        
        printUsage = YES;
    }
    
    if (!printUsage)
    {
        retVal = [self execute];
        if (0 == retVal)
        {
            printf("\nHLS Creation was SUCCESSFUL!\n");
        }
    }
    
    if (printUsage)
    {
        [self printUsage];
    }

    return retVal;
}

- (int) createMasterManifest:(NSArray*)settingsList
{
    @autoreleasepool {
        NSMutableString* str = [[NSMutableString alloc] init];
        [str appendString:@"#EXTM3U\n"];
        for (HLSSettings* settings in settingsList)
        {
            [str appendFormat:@"#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=%li\n", settings.kbps * 1000];
            [str appendFormat:@"%li/prog_index.m3u8\n", settings.kbps];
        }
        NSString* m3u8 = [self.args.outputDirectory stringByAppendingPathComponent:self.args.baseName];
        m3u8 = [m3u8 stringByAppendingPathExtension:@"m3u8"];
        [[NSFileManager defaultManager] removeItemAtPath:m3u8 error:NULL];
        if ([str writeToFile:m3u8 atomically:YES encoding:NSUTF8StringEncoding error:NULL])
        {
            printf("Finished creating HLS master manifest %s\n", m3u8.UTF8String);
            return 0;
        }
        
        printf("Failed to create the HLS master manifest\n");
        return -1;
    }
}

- (int) createHLSFiles:(HLSSettings*)settings
{
    @autoreleasepool {
        [[NSFileManager defaultManager] removeItemAtPath:settings.outputDirectory error:NULL];
        [[NSFileManager defaultManager] createDirectoryAtPath:settings.outputDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        
        [NSTask executeAndReturnStdOut:self.args.mediafilesegmenterPath arguments:@[settings.outputFile, @"-f", settings.outputDirectory]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[settings.outputDirectory stringByAppendingPathComponent:@"prog_index.m3u8"]])
        {
            printf("Finished creating %li Kbps stream at %s\n", settings.kbps, settings.outputDirectory.UTF8String);
            return 0;
        }

        printf("Failed to create %li Kbps stream\n", settings.kbps);
        return -1;
    }
}

- (int) convertVideo:(HLSSettings*)settings
{
    @autoreleasepool {
        NSMutableArray* args = [@[
                                 @"-O", @"-e", @"x264", @"-2", @"-R", @"22.05", @"--custom-anamorphic", @"--keep-display-aspect", @"--modulus", @"2",
                                 @"--display-width", [NSString stringWithFormat:@"%f.2", (settings.height * self.aspectRatio)],
                                 @"--width", [NSString stringWithFormat:@"%li", (NSUInteger)(settings.height * self.aspectRatio)],
                                 @"--height", [NSString stringWithFormat:@"%li", settings.height],
                                 @"-b", [NSString stringWithFormat:@"%li", settings.videoKbps],
                                 @"-i", settings.sourceFile,
                                 @"-o", settings.outputFile
                                ] mutableCopy];
        if (settings.kbps - settings.videoKbps < 60)
        {
            [args addObject:@"-a"];
            [args addObject:@"none"];
        }
        else
        {
            [args addObject:@"-6"];
            [args addObject:(settings.stereo ? @"stereo" : @"mono")];
            [args addObject:@"-B"];
            [args addObject:(settings.stereo ? @"40" : @"32")];
        }
        [[NSFileManager defaultManager] removeItemAtPath:settings.outputFile error:NULL];
        [NSTask executeAndReturnStdOut:self.args.handbrakePath
                             arguments:args];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:settings.outputFile])
        {
            printf("Finished Converting %s to %s\n", settings.sourceFile.UTF8String, settings.outputFile.UTF8String);
            return 0;
        }

        printf("Failed to convert source video to %li kbps video\n", settings.kbps);
        return -1;
    }
}

- (int) execute
{
    int retVal = 0;

    printf("Detecting Aspect Ratio of %s...\n", self.args.sourceFile.UTF8String);

    CGSize originalSize = { 960, 720 };
    MDItemRef vidItem = MDItemCreate(NULL, (__bridge CFStringRef)self.args.sourceFile);
    if (vidItem)
    {
        CFArrayRef names = MDItemCopyAttributeNames(vidItem);
        CFDictionaryRef attrs = MDItemCopyAttributes(vidItem, names);
        NSDictionary* attrsD = (__bridge NSDictionary*)attrs;
        originalSize.height = [[attrsD objectForKey:(__bridge NSString*)kMDItemPixelHeight] unsignedIntegerValue];
        originalSize.width = [[attrsD objectForKey:(__bridge NSString*)kMDItemPixelWidth] unsignedIntegerValue];
        CFRelease(attrs);
        CFRelease(names);
        CFRelease(vidItem);
    }
    printf("Failed to detect video dimensions, using fallback");

    self.originalSize = originalSize;
    self.aspectRatio  = originalSize.width / originalSize.height;

    printf("%lix%li == %f:1\n", (NSUInteger)originalSize.width, (NSUInteger)originalSize.height, self.aspectRatio);

    NSMutableArray* settingsList = [[NSMutableArray alloc] init];
    for (NSNumber* typeNum in self.args.hlsTypes)
    {
        HLSType type = typeNum.unsignedIntegerValue;
        HLSSettings* settings = [HLSSettings settingsForHLSType:type
                                                     sourceFile:self.args.sourceFile
                                                outputDirectory:self.args.outputDirectory];
        if (0 == (retVal = [self convertVideo:settings]))
        {
            retVal = [self createHLSFiles:settings];
        }
        
        if (0 != retVal)
            break;
        
        [settingsList addObject:settings];
    }
    
    if (0 == retVal)
    {
        retVal = [self createMasterManifest:settingsList];
    }
    
    return retVal;
}

@end
