//
//  NSPLogger.m
//  NSPLib
//
//  Created by Nolan O'Brien on 6/9/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSPLogger.h"
#import "NSString+Extensions.h"
#import "NSFileManager+Extensions.h"

NSUInteger const kNSPLoggerDefaultRolloverSize   =  500;
NSUInteger const kNSPLoggerDefaultMaxFiles       =  10;
NSUInteger const kNSPLoggerDefaultWritesPerFlush = 10;
NSString*  const kNSPLoggerDefaultFilePrefix     = @"log.";

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

@interface NSPLogger (Private)

- (void) performMaintenance:(BOOL)didAddLine;
- (BOOL) rolloverIfNeeded;
- (BOOL) purgeOldLogsIfNeeded;

- (void) write:(NSString*)message
         level:(NSPLogLevel)level
 withTimestamp:(NSDate*)timestamp; // must ONLY be executed on s_logQ!
- (void) writeBOM;
- (void) writeByte:(const char)byte;
- (void) writeBytes:(const char*)bytes length:(size_t)length;
- (void) writeData:(NSData*)data;
- (void) writeString:(NSString*)string;

@end

@implementation NSPLogger
{
@private
    NSUInteger  _writesPerFlush;
    NSUInteger  _logWritesMade;
    NSUInteger  _newlinesWritten;
    NSUInteger  _writesBeforeRollover;
    NSUInteger  _maxFileCount;
    NSPLogLevel _level;
    FILE*       _logFile;
    __strong NSString* _logFilePath;
    __strong NSString* _logFileNamePrefix;
}

static __strong NSPLogger* s_log = nil;
static dispatch_queue_t s_logSharingQ = 0;
static dispatch_queue_t s_logQ = 0;

+ (void) initialize
{
    s_logSharingQ = dispatch_queue_create("NSPLoggerSharingQ", DISPATCH_QUEUE_CONCURRENT);
    s_logQ = dispatch_queue_create("NSPLoggerQ", DISPATCH_QUEUE_SERIAL);
}

+ (NSPLogger*) sharedLog
{
    __block NSPLogger* logger;
    dispatch_sync(s_logSharingQ, ^() {
        logger = s_log;
    });
    return logger;
}

+ (void) setSharedLog:(NSPLogger*)log
{
    dispatch_barrier_async(s_logSharingQ, ^() {
        s_log = log;
    });
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    fclose(_logFile);
}

- (id) initWithDirectory:(NSString*)logsDirectory
                logLevel:(NSPLogLevel)level
{
    return [self initWithDirectory:logsDirectory
                        filePrefix:nil
                          logLevel:level
              writesBeforeRollover:0 /*default*/
                      maxFileCount:0 /*default*/];
}

- (id) initWithDirectory:(NSString*)root
               filePrefix:(NSString*)prefix
                 logLevel:(NSPLogLevel)level
     writesBeforeRollover:(NSUInteger)writesBeforeRollover
             maxFileCount:(NSUInteger)fileCount
{
    if (self = [super init])
    {
        NSFileManager* fm = [NSFileManager defaultManager];
        if (root)
        {
            [fm createDirectoryAtPath:root
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
            prefix = kNSPLoggerDefaultFilePrefix;
        }

        self.logLevel       = level;
        self.writesPerFlush = 0; // default;
        self.writesBeforeRollover = writesBeforeRollover;
        self.maxFileCount = fileCount;
        _logFileNamePrefix = [prefix copy];

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

- (NSPLogLevel) logLevel
{
    return _level;
}

- (void) setLogLevel:(NSPLogLevel)level
{
    _level = level;
}

- (void) setWritesBeforeRollover:(NSUInteger)writesBeforeRollover
{
    if (writesBeforeRollover < 1)
    {
        writesBeforeRollover = kNSPLoggerDefaultRolloverSize;
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
        fileCount = kNSPLoggerDefaultMaxFiles;
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
        writesPerFlush = kNSPLoggerDefaultWritesPerFlush;
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
    fflush(_logFile);
    _logWritesMade = 0;
}

- (void) writeSync:(NSString *)message level:(NSPLogLevel)level
{
    NSDate* date = [NSDate date];

    dispatch_sync(s_logQ, ^() {
        [self write:message level:level withTimestamp:date];
    });
}

- (void) writeASync:(NSString *)message level:(NSPLogLevel)level
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
    NSError* err = nil;
    NSMutableArray* logs = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.logRootPath
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
        [logs sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString*  logFile1     = [obj1 stringByDeletingPathExtension];
            NSString*  logFile2     = [obj2 stringByDeletingPathExtension];
            
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

- (NSString*) logRootPath
{
    return _logFilePath.stringByDeletingLastPathComponent;
}

- (NSData*) mostRecentLogs:(NSUInteger)maxSize
{
    if (maxSize < 1)
        maxSize = 1024;
    else if (maxSize > UINT32_MAX / 1024)
        maxSize = UINT32_MAX;
    else
        maxSize *= 1024;
    
    [self flush];
    NSArray*       logs = self.logFiles;
    NSString*      logRootPath = self.logRootPath;
    NSMutableData* data = nil;

    if (logs.count > 0)
    {
        char n = '\n';
        for (NSUInteger i = 0; i < logs.count && data.length < maxSize; i++)
        {
            @autoreleasepool {
                // keep this loop tight with an autorelease pool
                NSString* logPath = [logs objectAtIndex:logs.count - 1 - i];
                logPath = [logRootPath stringByAppendingPathComponent:logPath];
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
    NSFileManager* fm = [NSFileManager defaultManager];
    for (NSString* item in self.logFiles)
    {
        size += [fm fileSize:item];
    }
    return size;
}

@end

@implementation NSPLogger (Private)

- (void) write:(NSString*)message level:(NSPLogLevel)level withTimestamp:(NSDate*)timestamp
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

    static __strong NSDateFormatter* s_formatter = nil;
    static dispatch_once_t  onceToken;
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
        NSPAssert(_writesBeforeRollover > 0);
        [self writeByte:'\n'];
        [self writeString:@"Single log limit reached..."];

        NSString* oldFilePath = _logFilePath;
        NSString* oldFileDir  = oldFilePath.stringByDeletingLastPathComponent;
        UInt64    fileId      = GenerateLogFileId();
        NSString* newFilePath = [oldFileDir stringByAppendingPathComponent:GenerateLogFileName(_logFileNamePrefix, fileId)];
        NSFileManager* fm     = [NSFileManager defaultManager];
        
        // fileId is based on the current second, here's code to handle super edge case of resusing the same file id.
        while ([fm fileExistsAtPath:newFilePath])
        {
            fileId++;
            newFilePath = [oldFileDir stringByAppendingPathComponent:GenerateLogFileName(_logFileNamePrefix, fileId)];
        }
        
        FILE* newLogFile = fopen(newFilePath.UTF8String, "w");
        
        NSPAssert(![newFilePath isEqualToString:oldFilePath]);
        
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
        NSPAssert(_maxFileCount > 0);
        
        [self writeByte:'\n'];
        [self writeString:@"Total logging file limit reached, need to purge old log files..."];
        [self writeByte:'\n'];
        
        NSString*  root = self.logRootPath;
        NSUInteger filesToDelete = logs.count - _maxFileCount;
        for (NSUInteger i = 0; i < logs.count && 0 != filesToDelete; i++)
        {
            NSString* nextLog = [root stringByAppendingPathComponent:[logs objectAtIndex:i]];
            if ([nextLog isEqualToString:_logFilePath])
            {
                [self writeString:@"Cannot purge our current log file."];
                [self writeByte:'\n'];
                break;
            }
            
            NSString* msg = nil;
            NSError*  err = nil;
            if ([[NSFileManager defaultManager] removeItemAtPath:nextLog error:&err])
            {
                msg = [NSString stringWithFormat:@"Purged an old log file: %@", nextLog];
                filesToDelete--;
                purgeMade = YES;
            }
            else
            {
                msg = [NSString stringWithFormat:@"Failed to delete an old log file: %@\n%@", nextLog, err];
            }
            [self writeString:msg];
            [self writeByte:'\n'];
        }
        
        if (filesToDelete > 0)
        {
            [self writeString:@"Could not purge enough logs to return to below total logging limit size."];
            [self writeByte:'\n'];
        }
        
        [self writeByte:'\n'];
    }
    
    return purgeMade;
}

@end
