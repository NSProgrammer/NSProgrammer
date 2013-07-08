//
//  UITableView+Updating.h
//  NSPUILib
//
//  Created by Nolan O'Brien on 7/7/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

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
    @return the key used for identifying the section or row object.
    @note is is the callee's responsibility to know if the \a object is for a section or a row.
 */
- (NSObject<NSCopying>*) tableView:(UITableView*)tableView keyForObject:(NSObject*)object;

@optional
/**
    Called to determine if there was a modification to an object.  If not implemented in the implementing class, \a isEqual: will be used instead.
    If a modification is found, the modified section or row is reloaded.
    @param tableView the \c UITableView.
    @param previousObject an \c NSObject of the previous data's section OR row.
    @param object an \c NSObject of the current data's section OR row.
    @return \c YES if the objects are equal, \c NO otherwise.
    @note is is the callee's responsibility to know if the \a previousObject and \a object are for a section or a row.
 */
- (BOOL) tableView:(UITableView *)tableView isPreviousObject:(NSObject*)previousObject equalToObject:(NSObject*)object;

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
