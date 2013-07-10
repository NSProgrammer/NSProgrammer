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

#import <UIKit/UIKit.h>

@protocol UITableViewUpdatingDataSource;

@interface UITableView (Updating)

/**
    Updates the rows and sections of the receiver with an animation.
    @discussion Call this method when the data of the \a dataSource has changed and 
    the data is to be reloaded into the table view via an animation.
    If \a dataSource is \c nil or does not conform to the \c UITableViewUpdatingDataSource protocol,
    this method merely uses \a reloadData to update the receiver.
    The \c UITableViewUpdatingDataSource methods will be used to create a diff between the previous data source data and
    the current data source data and apply that to the receiver.
    @note Insertions, deletions and modifications to sections and rows are supported.
    Movement, however, is not.  When there is a move detected among sections, \a reloadData is called.
    When there is a move detected among rows in a section, that section is reloaded.
    Also, \c updateData is only for table views where each section and row is unique.  
    Repeated entries, determined by \c tableView:keyForObject: will result in \a reloadData being called.
 */
- (void) updateData;

@end

/**
    This protocol provides the necessary callbacks for creating a diff between the previous table data and the current table data.
 */
@protocol UITableViewUpdatingDataSource <UITableViewDataSource>

@required

/**
    @param tableView the \c UITableView.
    @return the number of sections in the previous data.
 */
- (NSInteger) numberOfPreviousSectionsInTableView:(UITableView*)tableView;
/**
    @param tableView the \c UITableView.
    @return the number of sections in the current data.
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView; /**< promote to be a required method */

/**
    @param tableView the \c UITableView.
    @param section the section of previous data whose row count is to be determined.
    @return the row count of the provided \a section in the previous data.
 */
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInPreviousSection:(NSInteger)section;
/**
    @param tableView the \c UITableView.
    @param section the section of current data whose row count is to be determined.
    @return the row count of the provided \a section in the current data.
 */
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;

/**
    @param tableView the \c UITableView.
    @param section the section of the previous data.
    @return the \c NSObject representation of the previous data's section queried.
 */
- (NSObject*) tableView:(UITableView*)tableView objectForPreviousSection:(NSInteger)section;
/**
    @param tableView the \c UITableView.
    @param section the section of the current data.
    @return the \c NSObject representation of the current data's section queried.
 */
- (NSObject*) tableView:(UITableView*)tableView objectForSection:(NSInteger)section;

/**
    @param tableView the \c UITableView.
    @param indexPath the \c NSIndexPath to the row of the previous data.
    @return the \c NSObject representation of the previous data's row queried using \a indexPath.
 */
- (NSObject*) tableView:(UITableView*)tableView objectAtPreviousIndexPath:(NSIndexPath*)indexPath;
/**
    @param tableView the \c UITableView.
    @param indexPath the \c NSIndexPath to the row of the current data.
    @return the \c NSObject representation of the current data's row queried using \a indexPath.
 */
- (NSObject*) tableView:(UITableView*)tableView objectAtIndexPath:(NSIndexPath*)indexPath;

/**
    Called to determine the unique identification key of a table view data's object.
    @param tableView the \c UITableView.
    @param object the \c NSObject to identify.
    @return the key used for identifying the section object.
 */
- (NSObject<NSCopying>*) tableView:(UITableView*)tableView keyForSectionObject:(NSObject*)object;

/**
    Called to determine the unique identification key of a table view data's object.
    @param tableView the \c UITableView.
    @param object the \c NSObject to identify.
    @return the key used for identifying the row object.
 */
- (NSObject<NSCopying>*) tableView:(UITableView*)tableView keyForRowObject:(NSObject*)object;

@optional
/**
    Called to determine if there was a modification to an object.  If not implemented in the implementing class, \a isEqual: will be used instead.
    If a modification is found, the modified section is reloaded.
    @param tableView the \c UITableView.
    @param previousObject an \c NSObject of the previous data's section.
    @param object an \c NSObject of the current data's section.
    @return \c YES if the objects are equal, \c NO otherwise.
 */
- (BOOL) tableView:(UITableView *)tableView isPreviousSectionObject:(NSObject*)previousObject equalToSectionObject:(NSObject*)object;

/**
    Called to determine if there was a modification to an object.  If not implemented in the implementing class, \a isEqual: will be used instead.
    If a modification is found, the modified row is reloaded.
    @param tableView the \c UITableView.
    @param previousObject an \c NSObject of the previous data's row.
    @param object an \c NSObject of the current data's row.
    @return \c YES if the objects are equal, \c NO otherwise.
 */
- (BOOL) tableView:(UITableView *)tableView isPreviousRowObject:(NSObject*)previousObject equalToRowObject:(NSObject*)object;

/**
    Called as \a updateData starts.  Once this callback is completed, the previous table data MUST be available for all previous data query calls.
    @param tableView the \c UITableView that will update.
    @see tableViewDidUpdate:
 */
- (void) tableViewWillUpdate:(UITableView*)tableView;
/**
    Called when \a updateData is completing.  This is a good spot to unload any memory allocated to maintaining the previous table data.
    @param tableView the \c UITableView that did update.
    @see tableViewWillUpdate:
 */
- (void) tableViewDidUpate:(UITableView*)tableView;

@end
