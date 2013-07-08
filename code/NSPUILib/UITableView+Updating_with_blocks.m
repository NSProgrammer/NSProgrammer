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

// NOTE: set UITABLEVIEW_UPDATING_WITH_BLOCK_ABSTRACTION macro to 1 in NSPUILib-Prefix.pch if abstraction of
// updating the sections and rows is desired.  It offers less code to maintain, particularly less
// duplicate code to maintain.  However, it has the side effect of being slightly slower (linearly).
#if UITABLEVIEW_UPDATING_WITH_BLOCK_ABSTRACTION

#import "UITableView+Updating.h"

typedef NSObject*(^GetObjectBlock)(NSInteger index);
typedef NSInteger(^GetObjectCountBlock)(void);
typedef void (^IndexBlock)(NSInteger index);
typedef BOOL(^BoolReturnIndexedBlock)(NSInteger oldIndex, NSInteger newIndex);

@implementation UITableView (Updating)

- (void) updateData
{
    id<UITableViewDataSource>         dataSource         = self.dataSource;
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
            NSMutableIndexSet* deleteSections = [[NSMutableIndexSet alloc] init];
            NSMutableIndexSet* reloadSections = [[NSMutableIndexSet alloc] init];
            NSMutableIndexSet* insertSections = [[NSMutableIndexSet alloc] init];
            NSMutableArray*    deleteRows     = [[NSMutableArray alloc] init];
            NSMutableArray*    reloadRows     = [[NSMutableArray alloc] init];
            NSMutableArray*    insertRows     = [[NSMutableArray alloc] init];

            reload = [self _updateGenericDataWithDataSource:updatingDataSource
                                getPreviousObjectCountBlock:^NSInteger () {
                          return [updatingDataSource numberOfPreviousSectionsInTableView:self];
                      }
                                        getObjectCountBlock:^NSInteger () {
                          return [updatingDataSource numberOfSectionsInTableView:self];
                      }
                                     getPreviousObjectBlock:^NSObject *(NSInteger index) {
                          return [updatingDataSource tableView:self objectForPreviousSection:index];
                      }
                                             getObjectBlock:^NSObject *(NSInteger index) {
                          return [updatingDataSource tableView:self objectForSection:index];
                      }
                                          deleteObjectBlock:^(NSInteger index) {
                          [deleteSections addIndex:index];
                      }
                                          reloadObjectBlock:^(NSInteger index) {
                          [reloadSections addIndex:index];
                      }
                                          insertObjectBlock:^(NSInteger index) {
                          [insertSections addIndex:index];
                      }
                                      extraReloadCheckBlock:^BOOL (NSInteger oldIndex, NSInteger newIndex) {
                          return [self _updateRowDataWithDataSource:updatingDataSource
                                                 forPreviousSection:oldIndex
                                                            section:newIndex
                                                        deleteArray:deleteRows
                                                        reloadArray:reloadRows
                                                        insertArray:insertRows];
                      }];

            if (!reload)
            {
                @try
                {
                    [self beginUpdates];
                    if (deleteSections.count > 0)
                    {
//                        DLOG(@"deleteSections: %@", deleteSections);
                        [self deleteSections:deleteSections
                            withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    if (deleteRows.count > 0)
                    {
//                        DLOG(@"deleteRows: %@", deleteRows);
                        [self deleteRowsAtIndexPaths:deleteRows
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    if (reloadSections.count > 0)
                    {
//                        DLOG(@"reloadSections: %@", reloadSections);
                        [self reloadSections:reloadSections
                            withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    if (reloadRows.count > 0)
                    {
//                        DLOG(@"reloadRows: %@", reloadRows);
                        [self reloadRowsAtIndexPaths:reloadRows
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    if (insertSections.count > 0)
                    {
//                        DLOG(@"insertSections: %@", insertSections);
                        [self insertSections:insertSections
                            withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    if (insertRows.count > 0)
                    {
//                        DLOG(@"insertRows: %@", insertRows);
                        [self insertRowsAtIndexPaths:insertRows
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    [self endUpdates];
                }
                @catch (NSException* exception)
                {
                    LOG_HI(@"Exception: %@", exception);
                    reload = YES;
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
    __block NSInteger deletes = 0;
    __block NSInteger reloads = 0;
    __block NSInteger inserts = 0;

    @autoreleasepool
    {
        reload = [self _updateGenericDataWithDataSource:updatingDataSource
                            getPreviousObjectCountBlock:^NSInteger () {
                      return [updatingDataSource tableView:self numberOfRowsInPreviousSection:oldSection];
                  }
                                    getObjectCountBlock:^NSInteger () {
                      return [updatingDataSource tableView:self numberOfRowsInSection:newSection];
                  }
                                 getPreviousObjectBlock:^NSObject *(NSInteger index) {
                      return [updatingDataSource tableView:self objectAtPreviousIndexPath:[NSIndexPath indexPathForRow:index inSection:oldSection]];
                  }
                                         getObjectBlock:^NSObject *(NSInteger index) {
                      return [updatingDataSource tableView:self objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:newSection]];
                  }
                                      deleteObjectBlock:^(NSInteger index) {
                      [deleteRows addObject:[NSIndexPath indexPathForRow:index inSection:oldSection]];
                      deletes++;
                  }
                                      reloadObjectBlock:^(NSInteger index) {
                      [reloadRows addObject:[NSIndexPath indexPathForRow:index inSection:oldSection]];
                      reloads++;
                  }
                                      insertObjectBlock:^(NSInteger index) {
                      [insertRows addObject:[NSIndexPath indexPathForRow:index inSection:newSection]];
                      inserts++;
                  }
                                  extraReloadCheckBlock:NULL];
    }

    if (reload)
    {
        // reload occurred, undo what we have done.
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

- (BOOL) _updateGenericDataWithDataSource:(id<UITableViewUpdatingDataSource>)updatingDataSource
              getPreviousObjectCountBlock:(GetObjectCountBlock)getPreviousObjectCountBlock
                      getObjectCountBlock:(GetObjectCountBlock)getObjectCountBlock
                   getPreviousObjectBlock:(GetObjectBlock)getPreviousObjectBlock
                           getObjectBlock:(GetObjectBlock)getObjectBlock
                        deleteObjectBlock:(IndexBlock)deleteObjectBlock
                        reloadObjectBlock:(IndexBlock)reloadObjectBlock
                        insertObjectBlock:(IndexBlock)insertObjectBlock
                    extraReloadCheckBlock:(BoolReturnIndexedBlock)extraReloadCheckBlock
{
    BOOL reload = NO;

    @autoreleasepool
    {
        NSMutableDictionary* oldMap = [[NSMutableDictionary alloc] init];
        NSInteger oldCount = getPreviousObjectCountBlock();

        for (NSInteger i = 0; i < oldCount; i++)
        {
            NSObject* obj = getPreviousObjectBlock(i);
            NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForObject:obj];
            [oldMap setObject:@(i) forKey:key];
        }
        if (oldCount != oldMap.count)
        {
            reload = YES;
        }

        if (!reload)
        {
            NSMutableDictionary* newMap = [[NSMutableDictionary alloc] init];
            NSInteger newCount = getObjectCountBlock();

            for (NSInteger i = 0; i < newCount; i++)
            {
                NSObject* obj = getObjectBlock(i);
                NSObject<NSCopying>* key = [updatingDataSource tableView:self keyForObject:obj];
                [newMap setObject:@(i) forKey:key];
            }
            if (newCount != newMap.count)
            {
                reload = YES;
            }

            if (!reload)
            {
                NSInteger oldIndex = 0;
                NSInteger newIndex = 0;
                NSObject* oldObj, * newObj;
                NSObject<NSCopying>* oldKey, * newKey;

                // Optimize redundant object retrieval
                BOOL repeatOld = NO;
                BOOL repeatNew = NO;
                BOOL delegateHasEqualSelector = [updatingDataSource respondsToSelector:@selector(tableView:isPreviousObject:equalToObject:)];

                for (NSInteger i = 0;; i++)
                {
                    if (!repeatOld)
                    {
                        oldObj = oldKey = nil;
                    }
                    if (!repeatNew)
                    {
                        newObj = newKey = nil;
                    }
                    if (!repeatOld && oldIndex < oldCount)
                    {
                        oldObj = getPreviousObjectBlock(oldIndex);
                    }
                    if (!repeatNew && newIndex < newCount)
                    {
                        newObj = getObjectBlock(newIndex);
                    }
                    if (!repeatOld && oldObj)
                    {
                        oldKey = [updatingDataSource tableView:self keyForObject:oldObj];
                    }
                    if (!repeatNew && newObj)
                    {
                        newKey = [updatingDataSource tableView:self keyForObject:newObj];
                    }

                    repeatOld = repeatNew = NO;

                    if (!oldKey && !newKey)
                    {
                        break;
                    }

                    if (oldKey)
                    {
                        NSNumber* newIndexToMatchOldId = [newMap objectForKey:oldKey];
                        if (!newIndexToMatchOldId)
                        {
                            deleteObjectBlock(oldIndex);
                            oldIndex++;
                            repeatNew = YES;
                            continue;
                        }
                    }

                    if (newKey)
                    {
                        NSNumber* oldIndexToMatchNewId = [oldMap objectForKey:newKey];
                        if (!oldIndexToMatchNewId)
                        {
                            insertObjectBlock(newIndex);
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

                        if (!didChange && extraReloadCheckBlock)
                        {
                            didChange = extraReloadCheckBlock(oldIndex, newIndex);
                        }

                        if (didChange)
                        {
                            reloadObjectBlock(oldIndex);
                        }
                    }

                    oldIndex++;
                    newIndex++;
                }
            }
        }
    }

    return reload;
}

@end

#endif // UITABLEVIEW_UPDATING_WITH_BLOCK_ABSTRACTION
