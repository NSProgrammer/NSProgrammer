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

#if !UITABLEVIEW_UPDATING_WITH_BLOCK_ABSTRACTION

#import "UITableView+Updating.h"

@interface UITableViewUpdates : NSObject
@property (nonatomic, readonly) NSMutableIndexSet* deleteSections;
@property (nonatomic, readonly) NSMutableIndexSet* reloadSections;
@property (nonatomic, readonly) NSMutableIndexSet* insertSections;
@property (nonatomic, readonly) NSMutableArray* deleteRows;
@property (nonatomic, readonly) NSMutableArray* reloadRows;
@property (nonatomic, readonly) NSMutableArray* insertRows;
@end

@implementation UITableViewUpdates

- (id) init
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

    [self _updateDataWithDataSource:updatingDataSource];
}

- (void) _updateDataWithDataSource:(id<UITableViewUpdatingDataSource>)updatingDataSource
{
    @autoreleasepool
    {
        if ([updatingDataSource respondsToSelector:@selector(tableViewWillUpdate:)])
        {
            [updatingDataSource tableViewWillUpdate:self];
        }

        BOOL reload = !self.window;
        if (!reload)
        {
            NSMutableDictionary* oldSectionMap = [[NSMutableDictionary alloc] init];
            NSInteger oldSectionCount = [updatingDataSource numberOfPreviousSectionsInTableView:self];
            
            for (NSInteger i = 0; i < oldSectionCount; i++)
            {
                NSObject* obj = [updatingDataSource tableView:self objectForPreviousSection:i];
                NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForSectionObject:obj];
                [oldSectionMap setObject:@(i) forKey:key];
            }
            if (oldSectionCount != oldSectionMap.count)
                reload = YES;
            
            if (!reload)
            {
                NSMutableDictionary* newSectionMap = [[NSMutableDictionary alloc] init];
                NSInteger newSectionCount = [updatingDataSource numberOfSectionsInTableView:self];

                for (NSInteger i = 0; i < newSectionCount; i++)
                {
                    NSObject* obj = [updatingDataSource tableView:self objectForSection:i];
                    NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForSectionObject:obj];
                    [newSectionMap setObject:@(i) forKey:key];
                }
                if (newSectionCount != newSectionMap.count)
                    reload = YES;

                if (!reload)
                {
                    UITableViewUpdates* updates = [[UITableViewUpdates alloc] init];

                    reload = [self _detectSectionUpdates:updates
                                  withUpdatingDataSource:updatingDataSource
                                           oldSectionMap:oldSectionMap
                                           newSectionMap:newSectionMap];

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
                 oldSectionMap:(NSDictionary*)oldSectionMap
                 newSectionMap:(NSDictionary*)newSectionMap
{
    NSPAssert(oldSectionMap);
    NSPAssert(newSectionMap);
    NSPAssert(updates);
    NSPAssert(updatingDataSource);

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
    BOOL delegateHasSectionEqualSelector = [updatingDataSource respondsToSelector:@selector(tableView:isPreviousSectionObject:equalToSectionObject:)];
    BOOL delegateHasRowEqualSelector = [updatingDataSource respondsToSelector:@selector(tableView:isPreviousRowObject:equalToRowObject:)];
    
    while (true)
    {
        if (!repeatOld)
            oldObj = oldKey = nil;
        if (!repeatNew)
            newObj = newKey = nil;
        if (!oldObj && oldIndex < oldSectionCount)
            oldObj = [updatingDataSource tableView:self objectForPreviousSection:oldIndex];
        if (!newObj && newIndex < newSectionCount)
            newObj = [updatingDataSource tableView:self objectForSection:newIndex];
        if (!oldKey && oldObj)
            oldKey = [updatingDataSource tableView:self keyForSectionObject:oldObj];
        if (!newKey && newObj)
            newKey = [updatingDataSource tableView:self keyForSectionObject:newObj];
        
        repeatOld = repeatNew = NO;
        
        if (!oldKey && !newKey)
            break;
        
        if (oldKey)
        {
            NSNumber* newIndexToMatchOldId = [newSectionMap objectForKey:oldKey];
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
            NSNumber* oldIndexToMatchNewId = [oldSectionMap objectForKey:newKey];
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
            if (delegateHasSectionEqualSelector)
            {
                didChange = ![updatingDataSource tableView:self
                                   isPreviousSectionObject:oldObj
                                      equalToSectionObject:newObj];
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
                         usingEqualSelector:delegateHasRowEqualSelector
                         forPreviousSection:oldIndex
                                    section:newIndex])
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
        usingEqualSelector:(BOOL)dataSourceHasEqualSelector
        forPreviousSection:(NSInteger)oldSection
                   section:(NSInteger)newSection
{
    BOOL reload = NO;
    NSInteger deletes = 0;
    NSInteger reloads = 0;
    NSInteger inserts = 0;
    @autoreleasepool
    {
        NSMutableDictionary* oldRowMap = [[NSMutableDictionary alloc] init];
        NSInteger oldRowCount = [updatingDataSource tableView:self numberOfRowsInPreviousSection:oldSection];
        
        for (NSInteger i = 0; i < oldRowCount; i++)
        {
            NSObject* obj = [updatingDataSource tableView:self
                                objectAtPreviousIndexPath:[NSIndexPath indexPathForRow:i inSection:oldSection]];
            NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForRowObject:obj];
            [oldRowMap setObject:@(i) forKey:key];
        }
        if (oldRowCount != oldRowMap.count)
            reload = YES;

        if (!reload)
        {
            NSMutableDictionary* newRowMap = [[NSMutableDictionary alloc] init];
            NSInteger newRowCount = [updatingDataSource tableView:self numberOfRowsInSection:newSection];
            
            for (NSInteger i = 0; i < newRowCount; i++)
            {
                NSObject* obj = [updatingDataSource tableView:self objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:newSection]];
                NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForRowObject:obj];
                [newRowMap setObject:@(i) forKey:key];
            }
            if (newRowCount != newRowMap.count)
                reload = YES;

            if (!reload)
            {
                NSPAssert(updates);

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
                    if (!oldObj && oldIndex < oldRowCount)
                        oldObj = [updatingDataSource tableView:self objectAtPreviousIndexPath:[NSIndexPath indexPathForRow:oldIndex inSection:oldSection]];
                    if (!newObj && newIndex < newRowCount)
                        newObj = [updatingDataSource tableView:self objectAtIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:newSection]];
                    if (!oldKey && oldObj)
                        oldKey = [updatingDataSource tableView:self keyForRowObject:oldObj];
                    if (!newKey && newObj)
                        newKey = [updatingDataSource tableView:self keyForRowObject:newObj];

                    repeatOld = repeatNew = NO;
                    
                    if (!oldKey && !newKey)
                        break;
                    
                    if (oldKey)
                    {
                        NSNumber* newIndexToMatchOldId = [newRowMap objectForKey:oldKey];
                        if (!newIndexToMatchOldId)
                        {
                            [updates.deleteRows addObject:[NSIndexPath indexPathForRow:oldIndex inSection:oldSection]];
                            oldIndex++;
                            deletes++;
                            repeatNew = YES;
                            continue;
                        }
                    }

                    if (newKey)
                    {
                        NSNumber* oldIndexToMatchNewId = [oldRowMap objectForKey:newKey];
                        if (!oldIndexToMatchNewId)
                        {
                            [updates.insertRows addObject:[NSIndexPath indexPathForRow:newIndex inSection:newSection]];
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
                        if (dataSourceHasEqualSelector)
                        {
                            didChange = ![updatingDataSource tableView:self
                                                   isPreviousRowObject:oldObj
                                                      equalToRowObject:newObj];
                        }
                        else
                        {
                            didChange = ![oldObj isEqual:newObj];
                        }

                        if (didChange)
                        {
                            [updates.reloadRows addObject:[NSIndexPath indexPathForRow:oldIndex inSection:oldSection]];
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

#endif // !UITABLEVIEW_UPDATING_WITH_BLOCK_ABSTRACTION
