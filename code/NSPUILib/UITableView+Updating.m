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

    [self updateDataWithDataSource:updatingDataSource];
}

- (void) updateDataWithDataSource:(id<UITableViewUpdatingDataSource>)updatingDataSource
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
                NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForObject:obj];
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
                    NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForObject:obj];
                    [newSectionMap setObject:@(i) forKey:key];
                }
                if (newSectionCount != newSectionMap.count)
                    reload = YES;

                if (!reload)
                {
                    NSMutableIndexSet* deleteSections = [[NSMutableIndexSet alloc] init];
                    NSMutableIndexSet* reloadSections = [[NSMutableIndexSet alloc] init];
                    NSMutableIndexSet* insertSections = [[NSMutableIndexSet alloc] init];
                    NSMutableArray*    deleteRows = [[NSMutableArray alloc] init];
                    NSMutableArray*    reloadRows = [[NSMutableArray alloc] init];
                    NSMutableArray*    insertRows = [[NSMutableArray alloc] init];

                    NSInteger oldIndex = 0;
                    NSInteger newIndex = 0;
                    NSObject* oldObj, *newObj;
                    NSObject<NSCopying>* oldKey, *newKey;

                    // Optimize redundant object retrieval
                    BOOL repeatOld = NO;
                    BOOL repeatNew = NO;
                    BOOL delegateHasEqualSelector = [updatingDataSource respondsToSelector:@selector(tableView:isPreviousObject:equalToObject:)];

                    while (true)
                    {
                        if (!repeatOld)
                            oldObj = oldKey = nil;
                        if (!repeatNew)
                            newObj = newKey = nil;
                        if (!repeatOld && oldIndex < oldSectionCount)
                            oldObj = [updatingDataSource tableView:self objectForPreviousSection:oldIndex];
                        if (!repeatNew && newIndex < newSectionCount)
                            newObj = [updatingDataSource tableView:self objectForSection:newIndex];
                        if (!repeatOld && oldObj)
                            oldKey = [updatingDataSource tableView:self keyForObject:oldObj];
                        if (!repeatNew && newObj)
                            newKey = [updatingDataSource tableView:self keyForObject:newObj];
                        
                        repeatOld = repeatNew = NO;
                        
                        if (!oldKey && !newKey)
                            break;
                        
                        if (oldKey)
                        {
                            NSNumber* newIndexToMatchOldId = [newSectionMap objectForKey:oldKey];
                            if (!newIndexToMatchOldId)
                            {
                                [deleteSections addIndex:oldIndex];
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
                                [insertSections addIndex:newIndex];
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
                            if (delegateHasEqualSelector)
                            {
                                didChange = ![updatingDataSource tableView:self isPreviousObject:oldObj equalToObject:newObj];
                            }
                            else
                            {
                                didChange = ![oldObj isEqual:newObj];
                            }

                            if (didChange)
                            {
                                [reloadSections addIndex:oldIndex];
                            }
                            else
                            {
                                // check row changes
                                if ([self _updateRowDataWithDataSource:updatingDataSource
                                                    forPreviousSection:oldIndex
                                                               section:newIndex
                                                           deleteArray:deleteRows
                                                           reloadArray:reloadRows
                                                           insertArray:insertRows])
                                {
                                    [reloadSections addIndex:oldIndex];
                                }
                            }
                        }
                        
                        oldIndex++;
                        newIndex++;
                    }

                    if (!reload)
                    {
                        @try
                        {
                            [self beginUpdates];
                            if (deleteSections.count > 0)
                            {
//                                DLOG(@"deleteSections: %@", deleteSections);
                                [self deleteSections:deleteSections
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                            if (deleteRows.count > 0)
                            {
//                                DLOG(@"deleteRows: %@", deleteRows);
                                [self deleteRowsAtIndexPaths:deleteRows
                                            withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                            if (reloadSections.count > 0)
                            {
//                                DLOG(@"reloadSections: %@", reloadSections);
                                [self reloadSections:reloadSections
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                            if (reloadRows.count > 0)
                            {
//                                DLOG(@"reloadRows: %@", reloadRows);
                                [self reloadRowsAtIndexPaths:reloadRows
                                            withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                            if (insertSections.count > 0)
                            {
//                                DLOG(@"insertSections: %@", insertSections);
                                [self insertSections:insertSections
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                            if (insertRows.count > 0)
                            {
//                                DLOG(@"insertRows: %@", insertRows);
                                [self insertRowsAtIndexPaths:insertRows
                                            withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                            [self endUpdates];
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

- (BOOL) _updateRowDataWithDataSource:(id<UITableViewUpdatingDataSource>)updatingDataSource
                   forPreviousSection:(NSInteger)oldSection
                              section:(NSInteger)newSection
                          deleteArray:(NSMutableArray*)deleteRows
                          reloadArray:(NSMutableArray*)reloadRows
                          insertArray:(NSMutableArray*)insertRows
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
            NSObject* obj = [updatingDataSource tableView:self objectAtPreviousIndexPath:[NSIndexPath indexPathForRow:i inSection:oldSection]];
            NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForObject:obj];
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
                NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForObject:obj];
                [newRowMap setObject:@(i) forKey:key];
            }
            if (newRowCount != newRowMap.count)
                reload = YES;

            if (!reload)
            {
                NSPAssert(deleteRows);
                NSPAssert(reloadRows);
                NSPAssert(insertRows);

                NSInteger oldIndex = 0;
                NSInteger newIndex = 0;
                NSObject* oldObj, *newObj;
                NSObject<NSCopying>* oldKey, *newKey;
                
                // Optimize redundant object retrieval
                BOOL repeatOld = NO;
                BOOL repeatNew = NO;
                BOOL delegateHasEqualSelector = [updatingDataSource respondsToSelector:@selector(tableView:isPreviousObject:equalToObject:)];

                while (true)
                {
                    if (!repeatOld)
                        oldObj = oldKey = nil;
                    if (!repeatNew)
                        newObj = newKey = nil;
                    if (!repeatOld && oldIndex < oldRowCount)
                        oldObj = [updatingDataSource tableView:self objectAtPreviousIndexPath:[NSIndexPath indexPathForRow:oldIndex inSection:oldSection]];
                    if (!repeatNew && newIndex < newRowCount)
                        newObj = [updatingDataSource tableView:self objectAtIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:newSection]];
                    if (!repeatOld && oldObj)
                        oldKey = [updatingDataSource tableView:self keyForObject:oldObj];
                    if (!repeatNew && newObj)
                        newKey = [updatingDataSource tableView:self keyForObject:newObj];
                    
                    repeatOld = repeatNew = NO;
                    
                    if (!oldKey && !newKey)
                        break;
                    
                    if (oldKey)
                    {
                        NSNumber* newIndexToMatchOldId = [newRowMap objectForKey:oldKey];
                        if (!newIndexToMatchOldId)
                        {
                            [deleteRows addObject:[NSIndexPath indexPathForRow:oldIndex inSection:oldSection]];
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
                            [insertRows addObject:[NSIndexPath indexPathForRow:newIndex inSection:newSection]];
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
                        if (delegateHasEqualSelector)
                        {
                            didChange = ![updatingDataSource tableView:self isPreviousObject:oldObj equalToObject:newObj];
                        }
                        else
                        {
                            didChange = ![oldObj isEqual:newObj];
                        }
                        
                        if (didChange)
                        {
                            [reloadRows addObject:[NSIndexPath indexPathForRow:oldIndex inSection:oldSection]];
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
        if (deletes)
        {
            [deleteRows removeObjectsInRange:NSMakeRange(deleteRows.count - deletes, deletes)];
        }
        if (inserts)
        {
            [insertRows removeObjectsInRange:NSMakeRange(insertRows.count - inserts, inserts)];
        }
        if (reloads)
        {
            [reloadRows removeObjectsInRange:NSMakeRange(reloadRows.count - reloads, reloads)];
        }
    }

    return reload;
}

@end

#endif // !UITABLEVIEW_UPDATING_WITH_BLOCK_ABSTRACTION
