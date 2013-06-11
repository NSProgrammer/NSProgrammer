//
//  NSPLogger.h
//  NSPLib
//
//  Created by Nolan O'Brien on 6/9/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !defined(DEBUG)
#define DLOG(format, ...)     ((void)0)
#else
#define DLOG(format, ...)     NSLog(format,##__VA_ARGS__)
#endif

#define LOG(lvl, format, ...) [NSPLOG writeASync:[NSString stringWithFormat:format, ##__VA_ARGS__] level:lvl]

#define LOG_HI(format, ...)  LOG(NSPLogLevel_HighLevel, format,##__VA_ARGS__)
#define LOG_MID(format, ...) LOG(NSPLogLevel_MidLevel, format,##__VA_ARGS__)
#define LOG_LO(format, ...)  LOG(NSPLogLevel_LowLevel, format,##__VA_ARGS__)

#ifdef DEBUG
#define LOG_DBG(format, ...) ((void)0)
#else
#define LOG_DBG(format, ...) LOG(NSPLogLevel_LowLevel, format,##__VA_ARGS__)
#endif

FOUNDATION_EXPORT NSUInteger const kNSPLoggerDefaultRolloverSize;     // 500 (writes, not bytes)
FOUNDATION_EXPORT NSUInteger const kNSPLoggerDefaultMaxFiles;         // 10
FOUNDATION_EXPORT NSUInteger const kNSPLoggerDefaultWritesPerFlush;   // 10
FOUNDATION_EXPORT NSString*  const kNSPLoggerDefaultFilePrefix;       // @"log."

typedef enum
{
    NSPLogLevel_Off = 0,
    NSPLogLevel_HighLevel, // important logs
    NSPLogLevel_MidLevel,  // not important logs
    NSPLogLevel_LowLevel   // verbose logs
} NSPLogLevel;

#define NSPLOG [NSPLogger sharedLog]

@interface NSPLogger : NSObject

+ (NSPLogger*) sharedLog;
+ (void) setSharedLog:(NSPLogger*)log;

// INIT can throw exceptions if logging object cannot be created
- (id) initWithDirectory:(NSString*)logsDirectory
                logLevel:(NSPLogLevel)level;
- (id) initWithDirectory:(NSString*)logsDirectory
              filePrefix:(NSString*)prefix
                logLevel:(NSPLogLevel)level
    writesBeforeRollover:(NSUInteger)writesBeforeRollover  // UINT32_MAX for unlimited
            maxFileCount:(NSUInteger)fileCount;

@property (nonatomic, assign) NSPLogLevel logLevel;
@property (nonatomic, assign) NSUInteger  writesPerFlush;
@property (nonatomic, assign) NSUInteger  writesBeforeRollover; // UINT32_MAX for unlimited
@property (nonatomic, assign) NSUInteger  maxFileCount;

- (void) flush;

- (void) writeASync:(NSString*)message level:(NSPLogLevel)level; // default
- (void) writeSync:(NSString*)message level:(NSPLogLevel)level;  // best for writing out logs at shutdown time

- (NSArray*)    logFiles;
- (NSString*)   logRootPath;
- (NSData*)     mostRecentLogs:(NSUInteger)maxSizeInKiloBytes; // must be greater than 1 and less than (UINT32_MAX / 1024)
- (unsigned long long) totalLogSize; // in Bytes

@end
