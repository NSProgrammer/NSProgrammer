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

#import "NSPDictionary.h"

static volatile int32_t s_threadSafeDictionaryCount = 0;
@implementation NSPThreadSafeMutableDictionary
{
@private
    NSMutableDictionary* _innerDictionary;
    dispatch_queue_t _queue;
    char* _queueName;
}

- (void) _prepare
{
    uint32_t count = OSAtomicIncrement32(&s_threadSafeDictionaryCount);
    NSString* queueName = [NSString stringWithFormat:@"NSPThreadSafeMutableDictionaryQueue_%u", count];

    _queueName = (char*)malloc(queueName.length);
    _queueName = memcpy(_queueName, queueName.UTF8String, queueName.length);
    _queue = dispatch_queue_create(_queueName, DISPATCH_QUEUE_CONCURRENT);
}

- (void) dealloc
{
    dispatch_release(_queue);
    free(_queueName);
}

#pragma mark - init Overrides

- (id) init
{
    if (self = [super init])
    {
        _innerDictionary = [[NSMutableDictionary alloc] init];
        [self _prepare];
    }
    return self;
}

- (id) initWithCapacity:(NSUInteger)numItems
{
    if (self = [super init])
    {
        _innerDictionary = [[NSMutableDictionary alloc] initWithCapacity:numItems];
        [self _prepare];
    }
    return self;
}

- (id) initWithObjects:(NSArray*)objects forKeys:(NSArray*)keys
{
    if (self = [super init])
    {
        _innerDictionary = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys];
        [self _prepare];
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)otherDictionary
{
    if (self = [super init])
    {
        if (otherDictionary)
            _innerDictionary = (otherDictionary ? otherDictionary.mutableCopy : [[NSMutableDictionary alloc] init]);
        [self _prepare];
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)otherDictionary copyItems:(BOOL)flag
{
    if (self = [super init])
    {
        _innerDictionary = [[NSMutableDictionary alloc] initWithDictionary:otherDictionary copyItems:flag];
        [self _prepare];
    }
    return self;
}

- (id) initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt
{
    if (self = [super init])
    {
        _innerDictionary = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys count:cnt];
        [self _prepare];
    }
    return self;
}

- (id) initWithContentsOfFile:(NSString*)path
{
    if (self = [super init])
    {
        _innerDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        [self _prepare];
    }
    return self;
}

- (id) initWithContentsOfURL:(NSURL*)url
{
    if (self = [super init])
    {
        _innerDictionary = [[NSMutableDictionary alloc] initWithContentsOfURL:url];
        [self _prepare];
    }
    return self;
}

#pragma mark - Get Overrides

- (NSArray*) allKeys
{
    __block NSArray* allKeys;
    dispatch_sync(_queue, ^() {
        allKeys = _innerDictionary.allKeys;
    });
    return allKeys;
}

- (NSArray*) allKeysForObject:(id)anObject
{
    __block NSArray* allKeys;
    dispatch_sync(_queue, ^() {
        allKeys = [_innerDictionary allKeysForObject:anObject];
    });
    return allKeys;
}

- (NSArray*) allValues
{
    __block NSArray* allValues;
    dispatch_sync(_queue, ^() {
        allValues = _innerDictionary.allValues;
    });
    return allValues;
}

- (NSString*) descriptionInStringsFileFormat
{
    __block NSString* description;
    dispatch_sync(_queue, ^() {
        description = _innerDictionary.descriptionInStringsFileFormat;
    });
    return description;
}

- (NSString*) descriptionWithLocale:(id)locale
{
    __block NSString* description;
    dispatch_sync(_queue, ^() {
        description = [_innerDictionary descriptionWithLocale:locale];
    });
    return description;
}

- (NSString*) descriptionWithLocale:(id)locale indent:(NSUInteger)level
{
    __block NSString* description;
    dispatch_sync(_queue, ^() {
        description = [_innerDictionary descriptionWithLocale:locale indent:level];
    });
    return description;
}

- (BOOL)isEqualToDictionary:(NSDictionary*)otherDictionary
{
    __block BOOL isEqual;
    dispatch_sync(_queue, ^() {
        isEqual = [_innerDictionary isEqualToDictionary:otherDictionary];
    });
    return isEqual;
}

- (NSEnumerator*) objectEnumerator
{
    __block NSEnumerator* enumerator;
    dispatch_sync(_queue, ^() {
        enumerator = _innerDictionary.objectEnumerator;
    });
    return enumerator;
}

- (NSArray*) objectsForKeys:(NSArray*)keys notFoundMarker:(id)marker
{
    __block NSArray* objects;
    dispatch_sync(_queue, ^() {
        objects = [_innerDictionary objectsForKeys:keys notFoundMarker:marker];
    });
    return objects;
}

- (BOOL) writeToFile:(NSString*)path atomically:(BOOL)useAuxiliaryFile
{
    __block BOOL success;
    dispatch_sync(_queue, ^() {
        success = [_innerDictionary writeToFile:path atomically:useAuxiliaryFile];
    });
    return success;
}

- (BOOL) writeToURL:(NSURL*)url atomically:(BOOL)atomically
{
    __block BOOL success;
    dispatch_sync(_queue, ^() {
        success = [_innerDictionary writeToURL:url atomically:atomically];
    });
    return success;
}

- (NSArray*) keysSortedByValueUsingSelector:(SEL)comparator
{
    __block NSArray* keys;
    dispatch_sync(_queue, ^() {
        keys = [_innerDictionary keysSortedByValueUsingSelector:comparator];
    });
    return keys;
}

- (void)getObjects:(id __unsafe_unretained [])objects andKeys:(id __unsafe_unretained [])keys
{
    dispatch_sync(_queue, ^() {
        [_innerDictionary getObjects:objects andKeys:keys];
    });
}

- (id)objectForKeyedSubscript:(id)key
{
    __block id obj;
    dispatch_sync(_queue, ^() {
        obj = [_innerDictionary objectForKeyedSubscript:key];
    });
    return obj;
}

#if NS_BLOCKS_AVAILABLE
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block
{
    dispatch_sync(_queue, ^() {
        [_innerDictionary enumerateKeysAndObjectsUsingBlock:block];
    });
}

- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id key, id obj, BOOL *stop))block
{
    dispatch_sync(_queue, ^() {
        [_innerDictionary enumerateKeysAndObjectsWithOptions:opts usingBlock:block];
    });
}

- (NSArray*) keysSortedByValueUsingComparator:(NSComparator)cmptr
{
    __block NSArray* keys;
    dispatch_sync(_queue, ^() {
        keys = [_innerDictionary keysSortedByValueUsingComparator:cmptr];
    });
    return keys;
}

- (NSArray*) keysSortedByValueWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr
{
    __block NSArray* keys;
    dispatch_sync(_queue, ^() {
        keys = [_innerDictionary keysSortedByValueWithOptions:opts usingComparator:cmptr];
    });
    return keys;
}

- (NSSet*) keysOfEntriesPassingTest:(BOOL (^)(id key, id obj, BOOL *stop))predicate
{
    __block NSSet* keys;
    dispatch_sync(_queue, ^() {
        keys = [_innerDictionary keysOfEntriesPassingTest:predicate];
    });
    return keys;
}

- (NSSet*) keysOfEntriesWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id key, id obj, BOOL *stop))predicate
{
    __block NSSet* keys;
    dispatch_sync(_queue, ^() {
        keys = [_innerDictionary keysOfEntriesWithOptions:opts passingTest:predicate];
    });
    return keys;
}
#endif

+ (id) sharedKeySetForKeys:(NSArray*)keys
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:[NSString stringWithFormat:@"%@ does not respond to class method selector %@", NSStringFromClass(self), NSStringFromSelector(_cmd)]
                                 userInfo:nil];
    return nil;
}

+ (id) dictionaryWithSharedKeySet:(id)keyset
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:[NSString stringWithFormat:@"%@ does not respond to class method selector %@", NSStringFromClass(self), NSStringFromSelector(_cmd)]
                                 userInfo:nil];
    return nil;    
}

#pragma mark - Set Overrides

- (void) setObject:(id)anObject forKey:(id <NSCopying>)aKey
{
    dispatch_barrier_async(_queue, ^() {
        [_innerDictionary setObject:anObject forKey:aKey];
    });
}

- (void) removeObjectForKey:(id)aKey
{
    dispatch_barrier_async(_queue, ^() {
        [_innerDictionary removeObjectForKey:aKey];
    });
}

- (NSUInteger) count
{
    __block NSUInteger count;

    dispatch_sync(_queue, ^() {
        count = _innerDictionary.count;
    });
    return count;
}

- (id) objectForKey:(id)aKey
{
    __block id obj;

    dispatch_sync(_queue, ^() {
        obj = [_innerDictionary objectForKey:aKey];
    });
    return obj;
}

- (NSEnumerator*) keyEnumerator
{
    __block NSEnumerator* enumerator;

    dispatch_sync(_queue, ^() {
        enumerator = _innerDictionary.keyEnumerator;
    });
    return enumerator;
}

- (id) copyWithZone:(NSZone*)zone
{
    __block id copy;

    dispatch_sync(_queue, ^() {
        copy = [_innerDictionary copyWithZone:zone];
    });
    return copy;
}

- (id) mutableCopyWithZone:(NSZone*)zone
{
    __block id copy;

    dispatch_sync(_queue, ^() {
        copy = [[[self class] allocWithZone:zone] initWithDictionary:_innerDictionary];
    });
    return copy;
}

- (NSString*) description
{
    __block NSString* dscr;

    dispatch_sync(_queue, ^() {
        dscr = _innerDictionary.description;
    });
    return dscr;
}

#pragma mark - Extension Overrides

- (void) addEntriesFromDictionary:(NSDictionary*)otherDictionary
{
    dispatch_barrier_async(_queue, ^() {
        [_innerDictionary addEntriesFromDictionary:otherDictionary];
    });
}

- (void) removeAllObjects
{
    dispatch_barrier_async(_queue, ^() {
        [_innerDictionary removeAllObjects];
    });
}

- (void) removeObjectsForKeys:(NSArray*)keyArray
{
    dispatch_barrier_async(_queue, ^() {
        [_innerDictionary removeObjectsForKeys:keyArray];
    });
}

- (void) setDictionary:(NSDictionary*)otherDictionary
{
    dispatch_barrier_async(_queue, ^() {
        [_innerDictionary setDictionary:otherDictionary];
    });
}

- (void) setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    dispatch_barrier_async(_queue, ^() {
        [_innerDictionary setObject:obj forKeyedSubscript:key];
    });
}

#pragma mark - Enhancements

- (id) replaceObjectForKey:(id<NSCopying>)key withObject:(id)object
{
    __block id obj;

    dispatch_sync(_queue, ^() {
        obj = [_innerDictionary objectForKey:key];
        [_innerDictionary setObject:object forKey:key];
    });
    return obj;
}

- (id) exclusiveSetObject:(id)object forKey:(id<NSCopying>)key
{
    __block id obj;

    dispatch_sync(_queue, ^() {
        obj = [_innerDictionary objectForKey:key];
        if (!obj)
            [_innerDictionary setObject:object forKey:key];
    });
    return obj;
}

@end
