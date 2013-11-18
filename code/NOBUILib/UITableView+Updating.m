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

#import "UITableView+Updating.h"
#include <objc/message.h>

/* 
    NOTE: Optimizations made -

    1) heavily used objective-c methods are directly accessed by their function pointers
    2) method existence is detected once and reused for code that gates based on an optional method
    3) data structures maintaining changes are the same from beginning to the end - no merges
    4) prevent memory bloat with auto release pools
    5) minimal access to properties (example: use the "count" property once to get the count and reuse the value retrieved)

    FUTURE OPTIMIZATIONS (if we want to go crazy):

    1) move memory allocation off the heap onto the stack (use c or c++ data structures instead of Obj-C ones)
    2) there's a non-trivial amount of time wasted on dealloc'ing NSIndexPath objects due to some thread safety issues of these objects
*/

@interface UITableViewUpdates : NSObject
@property (nonatomic, readonly) NSMutableIndexSet* deleteSections;
@property (nonatomic, readonly) NSMutableIndexSet* reloadSections;
@property (nonatomic, readonly) NSMutableIndexSet* insertSections;
@property (nonatomic, readonly) NSMutableArray* deleteRows;
@property (nonatomic, readonly) NSMutableArray* reloadRows;
@property (nonatomic, readonly) NSMutableArray* insertRows;
@end

TYPEDEF_FUNCTION_PTR(isPreviousSectionObjectEqualToSectionObjectFunctionPtr, BOOL, id, SEL, UITableView*, NSObject*, NSObject*);
TYPEDEF_FUNCTION_PTR(isPreviousRowObjectEqualToRowObjectFunctionPtr, BOOL, id, SEL, UITableView*, NSObject*, NSObject*);

// This struct will store seome method implementations of the updating data source to help optimize our loop
typedef struct _UITableViewUpdatingDataSourceRuntimeInfo {
    SEL objectForPreviousSectionSEL;
    IMP objectForPreviousSectionIMP;

    SEL objectForSectionSEL;
    IMP objectForSectionIMP;

    SEL objectAtPreviousIndexPathSEL;
    IMP objectAtPreviousIndexPathIMP;

    SEL objectAtIndexPathSEL;
    IMP objectAtIndexPathIMP;

    SEL keyForSectionObjectSEL;
    IMP keyForSectionObjectIMP;
    
    SEL keyForRowObjectSEL;
    IMP keyForRowObjectIMP;

    BOOL isPreviousSectionObjectEqualToSectionObjectAVL;
    SEL isPreviousSectionObjectEqualToSectionObjectSEL;
    isPreviousSectionObjectEqualToSectionObjectFunctionPtr isPreviousSectionObjectEqualToSectionObjectFP;
    
    BOOL isPreviousRowObjectEqualToRowObjectAVL;
    SEL isPreviousRowObjectEqualToRowObjectSEL;
    isPreviousRowObjectEqualToRowObjectFunctionPtr isPreviousRowObjectEqualToRowObjectFP;
} UITableViewUpdatingDataSourceRuntimeInfo;

// This struct will store some method implementations of our mutable dictionaries to help optimize our loop
typedef struct _NSMutableDictionaryRuntimeInfo {
    SEL objectForKeySEL;
    IMP objectForKeyIMP;

    SEL setObjectForKeySEL;
    IMP setObjectForKeyIMP;
} NSMutableDictionaryRuntimeInfo;

@interface NSMutableDictionary (RuntimeInfo)
- (NSMutableDictionaryRuntimeInfo) runtimeInfo;
@end

@implementation NSMutableDictionary (RuntimeInfo)

- (NSMutableDictionaryRuntimeInfo) runtimeInfo
{
    NSMutableDictionaryRuntimeInfo runtimeInfo;

    Class theClass = [self class];
    runtimeInfo.objectForKeySEL = @selector(objectForKey:);
    runtimeInfo.objectForKeyIMP = class_getMethodImplementation(theClass, runtimeInfo.objectForKeySEL);

    runtimeInfo.setObjectForKeySEL = @selector(setObject:forKey:);
    runtimeInfo.setObjectForKeyIMP = class_getMethodImplementation(theClass, runtimeInfo.setObjectForKeySEL);

    return runtimeInfo;
}

@end

@implementation UITableViewUpdates

- (instancetype) init
{
    if (self = [super init])
    {
        _deleteSections = [[NSMutableIndexSet alloc] init];
        _reloadSections = [[NSMutableIndexSet alloc] init];
        _insertSections = [[NSMutableIndexSet alloc] init];
        _deleteRows = [[NSMutableArray alloc] init];
        _reloadRows = [[NSMutableArray alloc] init];
        _insertRows = [[NSMutableArray alloc] init];
    }
    return self;
}

#ifdef DEBUG
- (NSString*) description
{
    return [@{  @"deleteSections" : _deleteSections,
                @"deleteRows" : _deleteRows,
                @"reloadSections" : _reloadSections,
                @"reloadRows" : _reloadRows,
                @"insertSections" : _insertSections,
                @"insertRows" : _insertRows } description];
}
#endif

@end

@implementation UITableView (Updating)

- (void) updateData
{
    id<UITableViewDataSource> dataSource = self.dataSource;
    id<UITableViewUpdatingDataSource> updatingDataSource = ([dataSource conformsToProtocol:@protocol(UITableViewUpdatingDataSource)] ? (id<UITableViewUpdatingDataSource>)dataSource : nil);
    if (!updatingDataSource)
    {
        [self reloadData];
        return;
    }

    Class updatingDataSourceClass = [updatingDataSource class];
    UITableViewUpdatingDataSourceRuntimeInfo runtimeInfo;

    runtimeInfo.objectForPreviousSectionSEL = @selector(tableView:objectForPreviousSection:);
    runtimeInfo.objectForPreviousSectionIMP = class_getMethodImplementation(updatingDataSourceClass, runtimeInfo.objectForPreviousSectionSEL);

    runtimeInfo.objectForSectionSEL = @selector(tableView:objectForSection:);
    runtimeInfo.objectForSectionIMP = class_getMethodImplementation(updatingDataSourceClass, runtimeInfo.objectForSectionSEL);

    runtimeInfo.objectAtPreviousIndexPathSEL = @selector(tableView:objectAtPreviousIndexPath:);
    runtimeInfo.objectAtPreviousIndexPathIMP = class_getMethodImplementation(updatingDataSourceClass, runtimeInfo.objectAtPreviousIndexPathSEL);

    runtimeInfo.objectAtIndexPathSEL = @selector(tableView:objectAtIndexPath:);
    runtimeInfo.objectAtIndexPathIMP = class_getMethodImplementation(updatingDataSourceClass, runtimeInfo.objectAtIndexPathSEL);

    runtimeInfo.keyForSectionObjectSEL = @selector(tableView:keyForSectionObject:);
    runtimeInfo.keyForSectionObjectIMP = class_getMethodImplementation(updatingDataSourceClass, runtimeInfo.keyForSectionObjectSEL);

    runtimeInfo.keyForRowObjectSEL = @selector(tableView:keyForRowObject:);
    runtimeInfo.keyForRowObjectIMP = class_getMethodImplementation(updatingDataSourceClass, runtimeInfo.keyForRowObjectSEL);

    runtimeInfo.isPreviousSectionObjectEqualToSectionObjectSEL = @selector(tableView:isPreviousRowObject:equalToRowObject:);
    if ((runtimeInfo.isPreviousSectionObjectEqualToSectionObjectAVL = [updatingDataSource respondsToSelector:runtimeInfo.isPreviousSectionObjectEqualToSectionObjectSEL]))
    {
        runtimeInfo.isPreviousSectionObjectEqualToSectionObjectFP = (isPreviousSectionObjectEqualToSectionObjectFunctionPtr)class_getMethodImplementation(updatingDataSourceClass, runtimeInfo.isPreviousSectionObjectEqualToSectionObjectSEL);
    }

    runtimeInfo.isPreviousRowObjectEqualToRowObjectSEL = @selector(tableView:isPreviousRowObject:equalToRowObject:);
    if ((runtimeInfo.isPreviousRowObjectEqualToRowObjectAVL = [updatingDataSource respondsToSelector:runtimeInfo.isPreviousRowObjectEqualToRowObjectSEL]))
    {
        runtimeInfo.isPreviousRowObjectEqualToRowObjectFP = (isPreviousRowObjectEqualToRowObjectFunctionPtr)class_getMethodImplementation(updatingDataSourceClass, runtimeInfo.isPreviousRowObjectEqualToRowObjectSEL);
    }

    [self _updateDataWithDataSource:updatingDataSource runtimeInfoRef:&runtimeInfo];
}

- (void) _updateDataWithDataSource:(id<UITableViewUpdatingDataSource>)updatingDataSource runtimeInfoRef:(UITableViewUpdatingDataSourceRuntimeInfo*)pRuntimeInfo
{
    @autoreleasepool
    {
        NOBAssert(updatingDataSource);
        NOBAssert(pRuntimeInfo);
        if ([updatingDataSource respondsToSelector:@selector(tableViewWillUpdate:)])
        {
            [updatingDataSource tableViewWillUpdate:self];
        }

        BOOL reload = !self.window;
        if (!reload)
        {
            NSInteger oldSectionCount = [updatingDataSource numberOfPreviousSectionsInTableView:self];
            NSMutableDictionary* oldSectionMap = [[NSMutableDictionary alloc] initWithCapacity:oldSectionCount];
            NSMutableDictionaryRuntimeInfo oldSectionMapRuntimeInfo = oldSectionMap.runtimeInfo;

            for (NSInteger i = 0; i < oldSectionCount; i++)
            {
                NSObject* obj = pRuntimeInfo->objectForPreviousSectionIMP(updatingDataSource, pRuntimeInfo->objectForPreviousSectionSEL, self, i);
                NSObject<NSCopying>* key = pRuntimeInfo->keyForSectionObjectIMP(updatingDataSource, pRuntimeInfo->keyForSectionObjectSEL, self, obj);
                oldSectionMapRuntimeInfo.setObjectForKeyIMP(oldSectionMap, oldSectionMapRuntimeInfo.setObjectForKeySEL, @(i), key);
            }
            if (oldSectionCount != oldSectionMap.count)
                reload = YES;
            
            if (!reload)
            {
                NSInteger newSectionCount = [updatingDataSource numberOfSectionsInTableView:self];
                NSMutableDictionary* newSectionMap = [[NSMutableDictionary alloc] initWithCapacity:newSectionCount];
                NSMutableDictionaryRuntimeInfo newSectionMapRuntimeInfo = newSectionMap.runtimeInfo;

                for (NSInteger i = 0; i < newSectionCount; i++)
                {
                    NSObject* obj = pRuntimeInfo->objectForSectionIMP(updatingDataSource, pRuntimeInfo->objectForSectionSEL, self, i);
                    NSObject<NSCopying>* key = pRuntimeInfo->keyForSectionObjectIMP(updatingDataSource, pRuntimeInfo->keyForSectionObjectSEL, self, obj);
                    newSectionMapRuntimeInfo.setObjectForKeyIMP(newSectionMap, newSectionMapRuntimeInfo.setObjectForKeySEL, @(i), key);
                }
                if (newSectionCount != newSectionMap.count)
                    reload = YES;

                if (!reload)
                {
                    UITableViewUpdates* updates = [[UITableViewUpdates alloc] init];

                    reload = [self _detectSectionUpdates:updates
                                  withUpdatingDataSource:updatingDataSource
                                dataSourceRuntimeInfoRef:pRuntimeInfo
                                           oldSectionMap:oldSectionMap
                             oldSectionMapRuntimeInfoRef:&oldSectionMapRuntimeInfo
                                           newSectionMap:newSectionMap
                             newSectionMapRuntimeInfoRef:&newSectionMapRuntimeInfo];

                    if (!reload)
                    {
                        @try
                        {
                            // NSLog(@"%@", updates);
                            [self _applyUpdates:updates];
                        }
                        @catch (NSException *exception)
                        {
                            LOG_HI(@"Exception: %@", exception);
                            reload = YES;
                        }
                    }
                }
            }
        }

        if (reload)
        {
            [self reloadData];
        }

        if ([updatingDataSource respondsToSelector:@selector(tableViewDidUpate:)])
        {
            [updatingDataSource tableViewDidUpate:self];
        }
    }
}

- (BOOL) _detectSectionUpdates:(UITableViewUpdates*)updates
        withUpdatingDataSource:(id<UITableViewUpdatingDataSource>)updatingDataSource
      dataSourceRuntimeInfoRef:(UITableViewUpdatingDataSourceRuntimeInfo*)pRuntimeInfo
                 oldSectionMap:(NSDictionary*)oldSectionMap
   oldSectionMapRuntimeInfoRef:(NSMutableDictionaryRuntimeInfo*)pOldSectionMapRuntimeInfo
                 newSectionMap:(NSDictionary*)newSectionMap
   newSectionMapRuntimeInfoRef:(NSMutableDictionaryRuntimeInfo*)pNewSectionMapRuntimeInfo
{
    NOBAssert(pOldSectionMapRuntimeInfo);
    NOBAssert(pNewSectionMapRuntimeInfo);
    NOBAssert(pRuntimeInfo);
    NOBAssert(oldSectionMap);
    NOBAssert(newSectionMap);
    NOBAssert(updates);
    NOBAssert(updatingDataSource);

    BOOL reload = NO;
    NSUInteger oldSectionCount = oldSectionMap.count;
    NSUInteger newSectionCount = newSectionMap.count;
    NSInteger oldIndex = 0;
    NSInteger newIndex = 0;
    NSObject* oldObj, *newObj;
    NSObject<NSCopying>* oldKey, *newKey;
    
    // Optimize redundant object retrieval
    BOOL repeatOld = NO;
    BOOL repeatNew = NO;

    while (true)
    {
        if (!repeatOld)
            oldObj = oldKey = nil;
        if (!repeatNew)
            newObj = newKey = nil;
        if (!oldObj && oldIndex < oldSectionCount)
            oldObj = pRuntimeInfo->objectForPreviousSectionIMP(updatingDataSource, pRuntimeInfo->objectForPreviousSectionSEL, self, oldIndex);
        if (!newObj && newIndex < newSectionCount)
            newObj = pRuntimeInfo->objectForSectionIMP(updatingDataSource, pRuntimeInfo->objectForSectionSEL, self, newIndex);
        if (!oldKey && oldObj)
            oldKey = pRuntimeInfo->keyForSectionObjectIMP(updatingDataSource, pRuntimeInfo->keyForSectionObjectSEL, self, oldObj);
        if (!newKey && newObj)
            newKey = pRuntimeInfo->keyForSectionObjectIMP(updatingDataSource, pRuntimeInfo->keyForSectionObjectSEL, self, newObj);

        repeatOld = repeatNew = NO;

        if (!oldKey && !newKey)
            break;

        if (oldKey)
        {
            NSNumber* newIndexToMatchOldId = pNewSectionMapRuntimeInfo->objectForKeyIMP(newSectionMap, pNewSectionMapRuntimeInfo->objectForKeySEL, oldKey);
            if (!newIndexToMatchOldId)
            {
                [updates.deleteSections addIndex:oldIndex];
                oldIndex++;
                repeatNew = YES;
                continue;
            }
        }
        
        if (newKey)
        {
            NSNumber* oldIndexToMatchNewId = pOldSectionMapRuntimeInfo->objectForKeyIMP(oldSectionMap, pOldSectionMapRuntimeInfo->objectForKeySEL, newKey);
            if (!oldIndexToMatchNewId)
            {
                [updates.insertSections addIndex:newIndex];
                newIndex++;
                repeatOld = YES;
                continue;
            }
        }
        
        if (newKey && oldKey)
        {
            // The order of items was manipulated beyond just additions and removals
            // Bail
            if (![oldKey isEqual:newKey])
            {
                reload = YES;
                break;
            }
            
            BOOL didChange = NO;
            if (pRuntimeInfo->isPreviousSectionObjectEqualToSectionObjectAVL)
            {
                didChange = !pRuntimeInfo->isPreviousSectionObjectEqualToSectionObjectFP(updatingDataSource,
                                                                                         pRuntimeInfo->isPreviousSectionObjectEqualToSectionObjectSEL,
                                                                                         self,
                                                                                         oldObj,
                                                                                         newObj);
            }
            else
            {
                didChange = ![oldObj isEqual:newObj];
            }
            
            if (didChange)
            {
                [updates.reloadSections addIndex:oldIndex];
            }
            else
            {
                // check row changes
                if ([self _detectRowUpdates:updates
                             withDataSource:updatingDataSource
                         forPreviousSection:oldIndex
                                    section:newIndex
                             runtimeInfoRef:pRuntimeInfo])
                {
                    [updates.reloadSections addIndex:oldIndex];
                }
            }
        }
        
        oldIndex++;
        newIndex++;
    }
    return reload;
}

- (void) _applyUpdates:(UITableViewUpdates*)updates
{
    [self beginUpdates];
    if (updates.deleteSections.count > 0)
    {
        [self deleteSections:updates.deleteSections
            withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if (updates.deleteRows.count > 0)
    {
        [self deleteRowsAtIndexPaths:updates.deleteRows
                    withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if (updates.reloadSections.count > 0)
    {
        [self reloadSections:updates.reloadSections
            withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if (updates.reloadRows.count > 0)
    {
        [self reloadRowsAtIndexPaths:updates.reloadRows
                    withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if (updates.insertSections.count > 0)
    {
        [self insertSections:updates.insertSections
            withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if (updates.insertRows.count > 0)
    {
        [self insertRowsAtIndexPaths:updates.insertRows
                    withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self endUpdates];
}

- (BOOL) _detectRowUpdates:(UITableViewUpdates*)updates
            withDataSource:(id<UITableViewUpdatingDataSource>)updatingDataSource
        forPreviousSection:(NSInteger)oldSection
                   section:(NSInteger)newSection
            runtimeInfoRef:(UITableViewUpdatingDataSourceRuntimeInfo*)pRuntimeInfo
{
    BOOL reload = NO;
    NSInteger deletes = 0;
    NSInteger reloads = 0;
    NSInteger inserts = 0;
    @autoreleasepool
    {
        NSInteger oldRowCount = [updatingDataSource tableView:self numberOfRowsInPreviousSection:oldSection];
        NSMutableDictionary* oldRowMap = [[NSMutableDictionary alloc] initWithCapacity:oldRowCount];
        NSMutableDictionaryRuntimeInfo oldRowMapRuntimeInfo = oldRowMap.runtimeInfo;
        
        for (NSInteger i = 0; i < oldRowCount; i++)
        {
            NSObject* obj = pRuntimeInfo->objectAtPreviousIndexPathIMP(updatingDataSource,
                                                                       pRuntimeInfo->objectAtPreviousIndexPathSEL,
                                                                       self,
                                                                       [NSIndexPath indexPathForRow:i inSection:oldSection]);
            NSObject<NSCopying>* key = pRuntimeInfo->keyForRowObjectIMP(updatingDataSource, pRuntimeInfo->keyForRowObjectSEL, self, obj);
            oldRowMapRuntimeInfo.setObjectForKeyIMP(oldRowMap, oldRowMapRuntimeInfo.setObjectForKeySEL, @(i), key);
        }
        if (oldRowCount != oldRowMap.count)
            reload = YES;

        if (!reload)
        {
            NSInteger newRowCount = [updatingDataSource tableView:self numberOfRowsInSection:newSection];
            NSMutableDictionary* newRowMap = [[NSMutableDictionary alloc] initWithCapacity:newRowCount];
            NSMutableDictionaryRuntimeInfo newRowMapRuntimeInfo = newRowMap.runtimeInfo;

            for (NSInteger i = 0; i < newRowCount; i++)
            {
                NSObject* obj = pRuntimeInfo->objectAtIndexPathIMP(updatingDataSource,
                                                                   pRuntimeInfo->objectAtIndexPathSEL,
                                                                   self,
                                                                   [NSIndexPath indexPathForRow:i inSection:newSection]);
                NSObject<NSCopying>* key = pRuntimeInfo->keyForRowObjectIMP(updatingDataSource, pRuntimeInfo->keyForRowObjectSEL, self, obj);
                newRowMapRuntimeInfo.setObjectForKeyIMP(newRowMap, newRowMapRuntimeInfo.setObjectForKeySEL, @(i), key);
            }
            if (newRowCount != newRowMap.count)
                reload = YES;

            if (!reload)
            {
                NOBAssert(updates);

                NSInteger oldIndex = 0;
                NSInteger newIndex = 0;
                NSObject* oldObj, *newObj;
                NSObject<NSCopying>* oldKey, *newKey;
                
                // Optimize redundant object retrieval
                BOOL repeatOld = NO;
                BOOL repeatNew = NO;

                while (true)
                {
                    NSIndexPath* oldPath = [NSIndexPath indexPathForRow:oldIndex inSection:oldSection];
                    NSIndexPath* newPath = [NSIndexPath indexPathForRow:newIndex inSection:newSection];
                    if (!repeatOld)
                        oldObj = oldKey = nil;
                    if (!repeatNew)
                        newObj = newKey = nil;
                    if (!oldObj && oldIndex < oldRowCount)
                        oldObj = pRuntimeInfo->objectAtPreviousIndexPathIMP(updatingDataSource,
                                                                            pRuntimeInfo->objectAtPreviousIndexPathSEL,
                                                                            self,
                                                                            oldPath);
                    if (!newObj && newIndex < newRowCount)
                        newObj = pRuntimeInfo->objectAtIndexPathIMP(updatingDataSource,
                                                                    pRuntimeInfo->objectAtIndexPathSEL,
                                                                    self,
                                                                    newPath);
                    if (!oldKey && oldObj)
                        oldKey = pRuntimeInfo->keyForRowObjectIMP(updatingDataSource,
                                                                  pRuntimeInfo->keyForRowObjectSEL,
                                                                  self,
                                                                  oldObj);
                    if (!newKey && newObj)
                        newKey = pRuntimeInfo->keyForRowObjectIMP(updatingDataSource,
                                                                  pRuntimeInfo->keyForRowObjectSEL,
                                                                  self,
                                                                  newObj);

                    repeatOld = repeatNew = NO;
                    
                    if (!oldKey && !newKey)
                        break;
                    
                    if (oldKey)
                    {
                        NSNumber* newIndexToMatchOldId = newRowMapRuntimeInfo.objectForKeyIMP(newRowMap, newRowMapRuntimeInfo.objectForKeySEL, oldKey);
                        if (!newIndexToMatchOldId)
                        {
                            [updates.deleteRows addObject:oldPath];
                            oldIndex++;
                            deletes++;
                            repeatNew = YES;
                            continue;
                        }
                    }

                    if (newKey)
                    {
                        NSNumber* oldIndexToMatchNewId = oldRowMapRuntimeInfo.objectForKeyIMP(oldRowMap, oldRowMapRuntimeInfo.objectForKeySEL, newKey);
                        if (!oldIndexToMatchNewId)
                        {
                            [updates.insertRows addObject:newPath];
                            newIndex++;
                            inserts++;
                            repeatOld = YES;
                            continue;
                        }
                    }

                    if (newKey && oldKey)
                    {
                        // The order of items was manipulated beyond just additions and removals
                        // Bail
                        if (![oldKey isEqual:newKey])
                        {
                            reload = YES;
                            break;
                        }

                        BOOL didChange = NO;
                        if (pRuntimeInfo->isPreviousRowObjectEqualToRowObjectAVL)
                        {
                            didChange = !pRuntimeInfo->isPreviousRowObjectEqualToRowObjectFP(updatingDataSource,
                                                                                             pRuntimeInfo->isPreviousRowObjectEqualToRowObjectSEL,
                                                                                             self,
                                                                                             oldObj,
                                                                                             newObj);
                        }
                        else
                        {
                            didChange = ![oldObj isEqual:newObj];
                        }

                        if (didChange)
                        {
                            [updates.reloadRows addObject:oldPath];
                            reloads++;
                        }
                    }

                    oldIndex++;
                    newIndex++;
                }
            }
        }
    }

    if (reload)
    {
        // Cleanup our modified lists of changes
        if (deletes)
        {
            [updates.deleteRows removeObjectsInRange:NSMakeRange(updates.deleteRows.count - deletes, deletes)];
        }
        if (inserts)
        {
            [updates.insertRows removeObjectsInRange:NSMakeRange(updates.insertRows.count - inserts, inserts)];
        }
        if (reloads)
        {
            [updates.reloadRows removeObjectsInRange:NSMakeRange(updates.reloadRows.count - reloads, reloads)];
        }
    }

    return reload;
}

@end
