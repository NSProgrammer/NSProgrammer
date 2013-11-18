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

#import "NOBLogger.h"
#import "NOBConversion.h"
#import "NSFileManager+Extensions.h"
#import "NSString+Extensions.h"

NSUInteger const kNOBLoggerDefaultRolloverSize   = 500;
NSUInteger const kNOBLoggerDefaultMaxFiles       = 10;
NSUInteger const kNOBLoggerDefaultWritesPerFlush = 10;
NSString* const  kNOBLoggerDefaultFilePrefix     = @"log.";

NS_INLINE UInt64 GenerateLogFileId(void);
NS_INLINE UInt64 GenerateLogFileId(void)
{
    NSTimeInterval ti = [[NSDate date] timeIntervalSinceReferenceDate];

    return (UInt64)ti;
}

NS_INLINE NSString* GenerateLogFileName(NSString* prefix, UInt64 fileId);
NS_INLINE NSString* GenerateLogFileName(NSString* prefix, UInt64 fileId)
{
    return [NSString stringWithFormat:@"%@%qu.log", prefix, fileId];
}

@interface NOBLogger (Private)

- (void) performMaintenance:(BOOL)didAddLine;
- (BOOL) rolloverIfNeeded;
- (BOOL) purgeOldLogsIfNeeded;

- (void)    write:(NSString*)message
            level:(NOBLogLevel)level
    withTimestamp:(NSDate*)timestamp; // must ONLY be executed on s_logQ!
- (void) writeBOM;
- (void) writeByte:(const char)byte;
- (void) writeBytes:(const char*)bytes length:(size_t)length;
- (void) writeData:(NSData*)data;
- (void) writeString:(NSString*)string;

@end

@interface NOBConsoleLogger : NOBLogger
@end

@implementation NOBLogger
{
    @protected
    NSUInteger         _writesPerFlush;
    NSUInteger         _logWritesMade;
    NSUInteger         _newlinesWritten;
    NSUInteger         _writesBeforeRollover;
    NSUInteger         _maxFileCount;
    NOBLogLevel        _level;
    FILE*              _logFile;
    __strong NSString* _logFilePath;
    __strong NSString* _logFileNamePrefix;
}

static __strong NOBConsoleLogger* s_cLog = nil;
static __strong NOBLogger* s_log         = nil;
static dispatch_queue_t    s_logSharingQ = 0;
static dispatch_queue_t    s_logQ        = 0;

+ (void) initialize
{
    s_logSharingQ = dispatch_queue_create("NOBLoggerSharingQ", DISPATCH_QUEUE_CONCURRENT);
    s_logQ        = dispatch_queue_create("NOBLoggerQ", DISPATCH_QUEUE_SERIAL);
}

+ (NOBLogger*) sharedLog
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_cLog = [[NOBConsoleLogger alloc] init];
    });

    __block NOBLogger* logger;
    dispatch_sync(s_logSharingQ, ^() {
            logger = (s_log ? s_log : s_cLog);
                  });
    return logger;
}

+ (void) setSharedLog:(NOBLogger*)log
{
    dispatch_barrier_async(s_logSharingQ, ^() {
                               [s_log flush];
                               s_log = log;
                           });
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_logFile)
	{
        [self flush];
        fclose(_logFile);
	}
}

+ (instancetype) logWithDefaultConfig
{
    return [[self alloc] initWithDirectory:[[NSFileManager cachesDirectoryPath] stringByAppendingPathComponent:@"logs"]
                                        filePrefix:nil
#ifdef DEBUG
                                          logLevel:NOBLogLevel_Low
#else
                                          logLevel:NOBLogLevel_High
#endif
                              writesBeforeRollover:0 /*default*/
                                      maxFileCount:0 /*default*/];
}

- (instancetype) initWithDirectory:(NSString*)logsDirectory
                logLevel:(NOBLogLevel)level
{
    return [self initWithDirectory:logsDirectory
                        filePrefix:nil
                          logLevel:level
              writesBeforeRollover:0 /*default*/
                      maxFileCount:0 /*default*/];
}

- (instancetype) initWithDirectory:(NSString*)root
                        filePrefix:(NSString*)prefix
                          logLevel:(NOBLogLevel)level
              writesBeforeRollover:(NSUInteger)writesBeforeRollover
                      maxFileCount:(NSUInteger)fileCount
{
    if (self = [super init])
    {
        NSFileManager* fm = [NSFileManager defaultManager];
        if (root)
        {
            [fm    createDirectoryAtPath:root
             withIntermediateDirectories:YES
                              attributes:nil
                                   error:NULL];
        }
        BOOL isDir = NO;
        if (![fm fileExistsAtPath:root isDirectory:&isDir] ||
            !isDir)
        {
            @throw [NSException exceptionWithName:NSDestinationInvalidException
                                           reason:@"InvalidPath: the root path provided does not exist!"
                                         userInfo:(root ? @{ @"rootPath" : root } : nil)];
        }

        if (!prefix)
        {
            prefix = kNOBLoggerDefaultFilePrefix;
        }

        self.logLevel             = level;
        self.writesPerFlush       = 0; // default;
        self.writesBeforeRollover = writesBeforeRollover;
        self.maxFileCount         = fileCount;
        _logFileNamePrefix        = [prefix copy];

        UInt64    fileId      = GenerateLogFileId();
        NSString* logFilePath = [root stringByAppendingPathComponent:GenerateLogFileName(_logFileNamePrefix, fileId)];
        // handle edge case of duplicate file
        while ([fm fileExistsAtPath:logFilePath])
        {
            fileId++;
            logFilePath = [root stringByAppendingPathComponent:GenerateLogFileName(_logFileNamePrefix, fileId)];
        }

        FILE* file = fopen(logFilePath.UTF8String, "w");
        if (!file)
        {
            @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                           reason:@"Could not create file for logging to!"
                                         userInfo:(logFilePath ? @{ @"filePath" : logFilePath } : nil)];
        }

        _logFile         = file;
        _logFilePath     = [logFilePath copy];
        _newlinesWritten = 0;
        _logWritesMade   = 0;

#ifdef START_LOG_WITH_BOM
        [self writeBOM];
#endif
        [self purgeOldLogsIfNeeded];
        [self writeString:@"New logging session started: "];
        [self writeString:_logFileNamePrefix];
        [self writeByte:'\n'];
        _logWritesMade = _newlinesWritten; // will equal number of writeByte: with '\n' calls
        [self performMaintenance:NO];
    }
    return self;
}

- (NOBLogLevel) logLevel
{
    return _level;
}

- (void) setLogLevel:(NOBLogLevel)level
{
    _level = level;
}

- (void) setWritesBeforeRollover:(NSUInteger)writesBeforeRollover
{
    if (writesBeforeRollover < 1)
    {
        writesBeforeRollover = kNOBLoggerDefaultRolloverSize;
    }

    if (_writesBeforeRollover != writesBeforeRollover)
    {
        KVO_BEGIN(writesBeforeRollover);
        _writesBeforeRollover = writesBeforeRollover;
        KVO_END(writesBeforeRollover);
    }
}

- (NSUInteger) writesBeforeRollover
{
    return _writesBeforeRollover;
}

- (void) setMaxFileCount:(NSUInteger)fileCount
{
    if (fileCount < 1)
    {
        fileCount = kNOBLoggerDefaultMaxFiles;
    }

    if (_maxFileCount != fileCount)
    {
        KVO_BEGIN(maxFileCount);
        _maxFileCount = fileCount;
        KVO_END(maxFileCount);
    }
}

- (NSUInteger) maxFileCount
{
    return _maxFileCount;
}

- (void) setWritesPerFlush:(NSUInteger)writesPerFlush
{
    if (writesPerFlush < 1)
    {
        writesPerFlush = kNOBLoggerDefaultWritesPerFlush;
    }

    if (!_writesPerFlush != writesPerFlush)
    {
        KVO_BEGIN(writesPerFlush);
        _writesPerFlush = writesPerFlush;
        KVO_END(writesPerFlush);
    }
}

- (NSUInteger) writesPerFlush
{
    return _writesPerFlush;
}

- (void) flush
{
    if (_logFile)
        fflush(_logFile);
    _logWritesMade = 0;
}

- (void) writeSync:(NSString*)message level:(NOBLogLevel)level
{
    NSDate* date = [NSDate date];

    dispatch_sync(s_logQ, ^() {
                      [self write:message level:level withTimestamp:date];
                  });
}

- (void) writeASync:(NSString*)message level:(NOBLogLevel)level
{
    NSDate* date = [NSDate date];

    dispatch_async(s_logQ, ^() {
                       dispatch_async(s_logQ, ^() {
                                          [self write:message level:level withTimestamp:date];
                                      });
                   });
}

- (NSArray*) logFiles
{
    NSError*        err  = nil;
    NSMutableArray* logs = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.logDirectoryPath
                                                                                error:&err] mutableCopy];

    if (err)
    {
        [self writeString:err.description];
        [self writeByte:'\n'];
        return nil;
    }

    for (NSInteger i = 0; i < logs.count; i++)
    {
        NSString* logName = [logs objectAtIndex:i];
        if (![logName hasPrefix:_logFileNamePrefix])
        {
            [logs removeObjectAtIndex:i];
            i--;
        }
    }

    @autoreleasepool {
        NSUInteger prefixLength = _logFileNamePrefix.length;
        [logs sortUsingComparator:^NSComparisonResult (id obj1, id obj2) {
             NSString* logFile1 = [obj1 stringByDeletingPathExtension];
             NSString* logFile2 = [obj2 stringByDeletingPathExtension];

             if (logFile1.length <= prefixLength ||
                 logFile2.length <= prefixLength)
             {
                 return [logFile1 compare:logFile2];
             }

             logFile1 = [logFile1 substringFromIndex:prefixLength];
             logFile2 = [logFile2 substringFromIndex:prefixLength];

             unsigned long long stamp1 = logFile1.unsignedLongLongValue;
             unsigned long long stamp2 = logFile2.unsignedLongLongValue;

             if (stamp1 < stamp2)
             {
                 return NSOrderedAscending;
             }
             else if (stamp1 > stamp2)
             {
                 return NSOrderedDescending;
             }

             return NSOrderedSame;
         }];
    }

    return [logs copy];
}

- (NSString*) logDirectoryPath
{
    return _logFilePath.stringByDeletingLastPathComponent;
}

- (NSData*) mostRecentLogs:(NSUInteger)maxSize
{
    if (maxSize < kMAGNITUDE_BYTES)
        maxSize = kMAGNITUDE_BYTES;

    [self flush];
    NSArray*       logs             = self.logFiles;
    NSString*      logDirectoryPath = self.logDirectoryPath;
    NSMutableData* data             = nil;

    if (logs.count > 0)
    {
        char n = '\n';
        for (NSUInteger i = 0; i < logs.count && data.length < maxSize; i++)
        {
            @autoreleasepool {
                // keep this loop tight with an autorelease pool
                NSString* logPath = [logs objectAtIndex:logs.count - 1 - i];
                logPath = [logDirectoryPath stringByAppendingPathComponent:logPath];
                NSMutableData* fileData = [NSMutableData dataWithContentsOfFile:logPath];
                if (data)
                {
                    [fileData appendBytes:&n length:1];
                    [fileData appendData:data];
                }
                data = fileData;
            }
        }

        if (data.length > 5)
        {
            if (data.length > maxSize)
            {
                [data replaceBytesInRange:NSMakeRange(0, data.length - maxSize)
                                withBytes:NULL
                                   length:0];
            }
        }
    }

    return [data copy];
}

- (unsigned long long) totalLogSize
{
    unsigned long long size = 0;
    NSFileManager*     fm   = [NSFileManager defaultManager];

    for (NSString* item in self.logFiles)
    {
        size += [fm fileSize:item];
    }
    return size;
}

@end

@implementation NOBLogger (Private)

- (void) write:(NSString*)message level:(NOBLogLevel)level withTimestamp:(NSDate*)timestamp
{
    if (!timestamp)
        timestamp = [NSDate date];

    // Keep this in sync with log levels
    static const char* s_logLevelNames[] =
    {
        "[OFF]  : ",
        "[HIGH] : ",
        "[MID]  : ",
        "[LOW]  : "
    };

    // Creating NSDateFormatters is slow, create a dedicated one for our NOBLogger(s)
    static __strong NSDateFormatter* s_formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
                      s_formatter = [[NSDateFormatter alloc] init];
                      s_formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                      s_formatter.dateFormat = @"MM'/'dd'/'yy hh':'mm':'ss a z";
                      s_formatter.timeZone = [NSTimeZone localTimeZone];
                  });

    const char* levelName = s_logLevelNames[level];
    NSString*   timeStamp = [s_formatter stringFromDate:timestamp];

    if (level &&
        level <= _level)
    {
        @synchronized(self)
        {
            [self writeByte:'['];
            [self writeString:timeStamp];
            [self writeByte:']'];
            [self writeBytes:levelName length:strlen(levelName)];
            [self writeString:message];
            [self writeByte:'\n'];
            [self performMaintenance:YES];

#ifdef DEBUG
            NSLog(@"%s%@", levelName, message);
#endif
        }
    }
}

- (void) performMaintenance:(BOOL)didAddLine
{
    BOOL didAddLog = NO;
    BOOL doFlush   = NO;

    // Increment the write count
    if (didAddLine)
    {
        _logWritesMade++;
    }

    // Rollover log file
    didAddLog = [self rolloverIfNeeded];

    if (!didAddLog &&
        _logWritesMade > _writesPerFlush)
    {
        doFlush = YES;
    }

    // Delete all old log files
    if ((didAddLog || 0 == _newlinesWritten) &&
        _maxFileCount < UINT32_MAX)
    {
        [self purgeOldLogsIfNeeded];
    }

    // Lastly, flush if necessary
    if (doFlush)
    {
        [self flush];
    }
}

- (void) writeBOM
{
    static const char s_BOM[] = { 0xEF, 0xBB, 0xBF };

    [self writeBytes:s_BOM length:3];
}

- (void) writeByte:(const char)byte
{
    fwrite(&byte, 1, 1, _logFile);
    if (byte == '\n')
    {
        _newlinesWritten++;
    }
}

- (void) writeBytes:(const char*)bytes length:(size_t)length
{
    fwrite(bytes, 1, length, _logFile);
}

- (void) writeData:(NSData*)data
{
    [self writeBytes:data.bytes length:data.length];
}

- (void) writeString:(NSString*)string
{
    [self writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL) rolloverIfNeeded
{
    BOOL didAddLog = NO;

    if (_writesBeforeRollover < UINT32_MAX &&
        _writesBeforeRollover < _newlinesWritten)
    {
        NOBAssert(_writesBeforeRollover > 0);
        [self writeByte:'\n'];
        [self writeString:@"Single log limit reached..."];

        NSString*      oldFilePath = _logFilePath;
        NSString*      oldFileDir  = oldFilePath.stringByDeletingLastPathComponent;
        UInt64         fileId      = GenerateLogFileId();
        NSString*      newFilePath = [oldFileDir stringByAppendingPathComponent:GenerateLogFileName(_logFileNamePrefix, fileId)];
        NSFileManager* fm = [NSFileManager defaultManager];

        // fileId is based on the current second, here's code to handle super edge case of resusing the same file id.
        while ([fm fileExistsAtPath:newFilePath])
        {
            fileId++;
            newFilePath = [oldFileDir stringByAppendingPathComponent:GenerateLogFileName(_logFileNamePrefix, fileId)];
        }

        FILE* newLogFile = fopen(newFilePath.UTF8String, "w");

        NOBAssert(![newFilePath isEqualToString:oldFilePath]);

        _newlinesWritten = _logWritesMade = 0;

        if (!newLogFile)
        {
            [self writeByte:'\n'];
            [self writeString:@"!!!!  Log could not be rolled over  !!!!"];
            [self writeByte:'\n'];
        }
        else
        {
            [self writeString:@"moving to "];
            [self writeString:newFilePath];
            [self writeByte:'\n'];
            [self flush];

            _logFilePath = [newFilePath copy];
            fclose(_logFile);
            _logFile         = newLogFile;
            _newlinesWritten = 0;

#ifdef START_LOG_WITH_BOM
            [self writeBOM];
#endif
            [self writeString:@"... continuing log from "];
            [self writeString:oldFilePath];
            [self writeByte:'\n'];
            [self writeByte:'\n'];

            didAddLog = YES;
        }

        _logWritesMade = _newlinesWritten;
    }

    return didAddLog;
}

- (BOOL) purgeOldLogsIfNeeded
{
    NSArray* logs      = self.logFiles;
    BOOL     purgeMade = NO;

    if (logs.count > _maxFileCount &&
        _maxFileCount < UINT32_MAX)
    {
        NOBAssert(_maxFileCount > 0);

        [self writeByte:'\n'];
        [self writeString:[NSString stringWithFormat:@"Reached log file limit of %d.  Need to purge old log files...\n", _maxFileCount]];

        NSFileManager* fm   = [NSFileManager defaultManager];
        NSString*      root = self.logDirectoryPath;
        NSUInteger     filesToDelete = logs.count - _maxFileCount;
        for (NSUInteger i = 0; i < logs.count && 0 != filesToDelete; i++)
        {
            NSString* nextLog = [root stringByAppendingPathComponent:[logs objectAtIndex:i]];
            if ([nextLog isEqualToString:_logFilePath])
            {
                [self writeString:@"Ran out of logs to purge.\n"];
                break;
            }

            NSString* msg = nil;
            NSError*  err = nil;
            if ([fm removeItemAtPath:nextLog error:&err])
            {
                msg = [NSString stringWithFormat:@"Purged old log file: %@", nextLog];
                filesToDelete--;
                purgeMade = YES;
            }
            else
            {
                msg = [NSString stringWithFormat:@"Failed to purge old log file: %@\n%@", nextLog, err];
            }
            [self writeString:msg];
            [self writeByte:'\n'];
        }

        if (filesToDelete > 0)
        {
            [self writeString:@"Could not purge enough log files to reach log file limit.\n"];
        }

        [self writeByte:'\n'];
    }

    return purgeMade;
}

@end

@implementation NOBConsoleLogger

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    fclose(_logFile);
}

- (instancetype) initWithDirectory:(NSString*)logsDirectory
                          logLevel:(NOBLogLevel)level
{
    return [self initWithDirectory:logsDirectory
                        filePrefix:nil
                          logLevel:level
              writesBeforeRollover:0 /*default*/
                      maxFileCount:0 /*default*/];
}

- (instancetype) init
{
    if (self = [super init])
    {
#ifndef RELEASE
        self.logLevel = NOBLogLevel_Low;
#else
        self.logLevel = NOBLogLevel_High;
#endif

        _logFile         = 0;
    }
    return self;
}

- (NSArray*) logFiles
{
    return nil;
}

- (NSString*) logDirectoryPath
{
    return nil;
}

- (NSData*) mostRecentLogs:(NSUInteger)maxSize
{
    return nil;
}

- (unsigned long long) totalLogSize
{
    return 0;
}

- (void) performMaintenance:(BOOL)didAddLine
{
    // No-op
}

- (void) writeByte:(const char)byte
{
    // No-op
}

- (void) writeBytes:(const char*)bytes length:(size_t)length
{
    // No-op
}

- (BOOL) rolloverIfNeeded
{
    return NO;
}

- (BOOL) purgeOldLogsIfNeeded
{
    return NO;
}

@end
