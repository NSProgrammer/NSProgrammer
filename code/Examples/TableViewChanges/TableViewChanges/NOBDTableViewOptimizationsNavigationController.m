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

#import "NOBDTableViewOptimizationsNavigationController.h"
#include <libkern/OSAtomic.h>

typedef NS_ENUM(NSInteger, NOBDDataEntryChangeLocation) {
    NOBDDataEntryChangeLocation_Beginning   = 0,
    NOBDDataEntryChangeLocation_Middle      = 1,
    NOBDDataEntryChangeLocation_End         = 2,
    NOBDDataEntryChangeLocation_Random      = 3
};

typedef NS_ENUM(NSInteger, NOBDDataEntryModificationType) {
    NOBDDataEntryModificationType_Insert = 0,
    NOBDDataEntryModificationType_Delete = 1,
    NOBDDataEntryModificationType_Modify = 2,
    NOBDDataEntryModificationType_Random = 3
};

@interface NSMutableArray (LocationModification)
- (NSUInteger) indexOfLocation:(NOBDDataEntryChangeLocation)location inclusive:(BOOL)inclusive;
- (void) insertObject:(id)anObject atLocation:(NOBDDataEntryChangeLocation)location;
- (void) removeObjectAtLocation:(NOBDDataEntryChangeLocation)location;
- (id) objectAtLocation:(NOBDDataEntryChangeLocation)location;
@end

@implementation NSMutableArray (LocationModification)

- (NSUInteger) indexOfLocation:(NOBDDataEntryChangeLocation)location inclusive:(BOOL)inclusive
{
    NSUInteger count = self.count;
    NSUInteger index = (inclusive ? NSNotFound : 0);
    if (count > 0)
    {
        switch (location)
        {
            case NOBDDataEntryChangeLocation_Random:
                index = arc4random() % (inclusive ? count : count+1);
                break;
            case NOBDDataEntryChangeLocation_Middle:
                index = count / 2;
                break;
            case NOBDDataEntryChangeLocation_Beginning:
                index = 0;
                break;
            case NOBDDataEntryChangeLocation_End:
            default:
                index = count;
                if (inclusive)
                    index--;
                break;
        }
    }
    return index;
}

- (void) insertObject:(id)anObject atLocation:(NOBDDataEntryChangeLocation)location
{
    [self insertObject:anObject atIndex:[self indexOfLocation:location inclusive:NO]];
}

- (void) removeObjectAtLocation:(NOBDDataEntryChangeLocation)location
{
    NSUInteger i = [self indexOfLocation:location inclusive:YES];
    if (NSNotFound != i)
        [self removeObjectAtIndex:i];
}

- (id) objectAtLocation:(NOBDDataEntryChangeLocation)location
{
    NSUInteger i = [self indexOfLocation:location inclusive:YES];
    if (NSNotFound == i)
        return nil;
    return [self objectAtIndex:i];
}

@end

@interface NOBDDataEntry : NSObject <NSCopying>
@property (nonatomic, assign) int32_t unchangeableProperty;
@property (nonatomic, assign) int32_t changeableProperty;
- (void) changeProperty;
- (id) init;
@end

@interface NOBDDataSection : NOBDDataEntry
@property (nonatomic, readonly) NSMutableArray* entries;
- (void) addEntry:(NOBDDataEntryChangeLocation)location;
- (id) init;
@end

static volatile int32_t s_changeable = 0;
static volatile int32_t s_unchangeable = 0;
static volatile int32_t s_total = 0;

@implementation NOBDDataEntry

- (id) initWithEntry:(NOBDDataEntry*)entry
{
    if (self = [super init])
    {
        OSAtomicIncrement32(&s_total);
        _changeableProperty = entry->_changeableProperty;
        _unchangeableProperty = entry->_unchangeableProperty;
    }
    return self;
}

- (void) changeProperty
{
    _changeableProperty = OSAtomicIncrement32(&s_changeable);
}

- (id) init
{
    if (self = [super init])
    {
        OSAtomicIncrement32(&s_total);
        _unchangeableProperty = OSAtomicIncrement32(&s_unchangeable);
        [self changeProperty];
    }
    return self;
}

- (void) dealloc
{
    OSAtomicDecrement32(&s_total);
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[NOBDDataEntry alloc] initWithEntry:self];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"[%i,%i]", _unchangeableProperty, _changeableProperty];
}

- (BOOL) isEqual:(id)object
{
    if (object == self)
        return YES;
    return [object isKindOfClass:[NOBDDataEntry class]] &&
           _changeableProperty == [object changeableProperty] &&
           _unchangeableProperty == [object unchangeableProperty];
}

- (NSUInteger) hash
{
    return _unchangeableProperty + _changeableProperty;
}

@end

@implementation NOBDDataSection

- (id) initWithSection:(NOBDDataSection*)section
{
    if (self = [super initWithEntry:section])
    {
        _entries = [[NSMutableArray alloc] initWithCapacity:section->_entries.count];
        for (NOBDDataEntry* entry in section->_entries)
        {
            [_entries addObject:[entry copy]];
        }
    }
    return self;
}

- (id) init
{
    if (self = [super init])
    {
        _entries = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addEntry:(NOBDDataEntryChangeLocation)location
{
    NOBDDataEntry* entry = [[NOBDDataEntry alloc] init];
    [_entries insertObject:entry atLocation:location];
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[NOBDDataSection alloc] initWithSection:self];
}

- (NSString*) description
{
    return [@{ [super description] : [_entries description] } description];
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;

    return [super isEqual:object] &&
           [object isKindOfClass:[NOBDDataSection class]] &&
           [_entries isEqualToArray:[object entries]];
}

- (NSUInteger) hash
{
    return super.hash + _entries.hash;
}

@end

@interface NOBDTableViewOptimizationsNavigationController () <UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewUpdatingDataSource>
{
    IBOutlet UIPickerView* _editTypePicker;
    IBOutlet UIPickerView* _locationPicker;
    IBOutlet UIStepper*    _quantityStepper;
    IBOutlet UILabel*      _changesCount;
    IBOutlet UITableView*  _tableView;
}

- (void) createSection:(NOBDDataEntryChangeLocation)location;
- (void) createRow:(NOBDDataEntryChangeLocation)rowLocation
 inSectionLocation:(NOBDDataEntryChangeLocation)sectionLocation;

- (void) deleteSection:(NOBDDataEntryChangeLocation)location;
- (void) deleteRow:(NOBDDataEntryChangeLocation)rowLocation
 inSectionLocation:(NOBDDataEntryChangeLocation)sectionLocation;

- (void) modifySection:(NOBDDataEntryChangeLocation)location;
- (void) modifyRow:(NOBDDataEntryChangeLocation)rowLocation
   sectionLocation:(NOBDDataEntryChangeLocation)sectionLocation;

- (IBAction) go:(id)sender;

@end

@implementation NOBDTableViewOptimizationsNavigationController
{
    NSMutableArray* _dataSource; // NOBDateSection objects
    NSMutableArray* _oldDataSource;
}

- (id) init
{
    if (self = [super initWithNibName:@"NOBDView" bundle:nil])
    {
        _dataSource = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
    for (NSUInteger i = 0; i < 3; i++)
    {
        [self createSection:NOBDDataEntryChangeLocation_End];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSObject*) tableView:(UITableView *)tableView objectForSection:(NSInteger)section
{
    return [_dataSource objectAtIndex:section];
}

- (NSObject*) tableView:(UITableView *)tableView objectForPreviousSection:(NSInteger)section
{
    return [_oldDataSource objectAtIndex:section];
}

- (NSObject*) tableView:(UITableView *)tableView objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[_dataSource objectAtIndex:indexPath.section] entries] objectAtIndex:indexPath.row];
}

- (NSObject*) tableView:(UITableView *)tableView objectAtPreviousIndexPath:(NSIndexPath *)indexPath
{
    return [[[_oldDataSource objectAtIndex:indexPath.section] entries] objectAtIndex:indexPath.row];
}

- (NSObject<NSCopying>*) tableView:(UITableView *)tableView keyForSectionObject:(NSObject *)object
{
    return @([(NOBDDataSection*)object unchangeableProperty]);
}

- (NSObject<NSCopying>*) tableView:(UITableView *)tableView keyForRowObject:(NSObject *)object
{
    return @([(NOBDDataEntry*)object unchangeableProperty]);
}

- (BOOL) tableView:(UITableView *)tableView isPreviousSectionObject:(NSObject*)previousObject equalToSectionObject:(NSObject*)object
{
    return [(NOBDDataSection*)previousObject changeableProperty] == [(NOBDDataSection*)object changeableProperty];
}

- (BOOL) tableView:(UITableView *)tableView isPreviousRowObject:(NSObject*)previousObject equalToRowObject:(NSObject*)object
{
    return [(NOBDDataEntry*)previousObject changeableProperty] == [(NOBDDataEntry*)object changeableProperty];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _dataSource.count;
}

- (NSInteger) numberOfPreviousSectionsInTableView:(UITableView *)tableView
{
    return _oldDataSource.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_dataSource objectAtIndex:section] entries].count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInPreviousSection:(NSInteger)section
{
    return [[_oldDataSource objectAtIndex:section] entries].count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:@"Cell"];
    }
    
    NOBDDataSection* section = [_dataSource objectAtIndex:indexPath.section];
    NOBDDataEntry* row = [section.entries objectAtIndex:indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"%i", row.unchangeableProperty];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%i", row.changeableProperty];

    return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NOBDDataSection* sectionEntry = [_dataSource objectAtIndex:section];
    return [NSString stringWithFormat:@"%i (%i)", sectionEntry.unchangeableProperty, sectionEntry.changeableProperty];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Pickers

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return (pickerView == _locationPicker ? 2 : 1);
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == _editTypePicker)
    {
        return 4;
    }
    else if (pickerView == _locationPicker)
    {
        if (0 == component)
            return 4;
        else
            return 6;
    }

    return 10;
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == _editTypePicker)
    {
        NOBDDataEntryModificationType modType = row;
        switch (modType)
        {
            case NOBDDataEntryModificationType_Delete:
                return @"Delete";
            case NOBDDataEntryModificationType_Insert:
                return @"Insert";
            case NOBDDataEntryModificationType_Modify:
                return @"Modify";
            case NOBDDataEntryModificationType_Random:
            default:
                return @"Random";
        }
    }
    else if (pickerView == _locationPicker)
    {
        if (4 == row)
        {
            return @"None";
        }
        if (5 == row)
        {
            return @"Rnd w/ None";
        }

        NOBDDataEntryChangeLocation loc = row;
        switch (loc)
        {
            case NOBDDataEntryChangeLocation_Beginning:
                return @"Beginning";
            case NOBDDataEntryChangeLocation_Middle:
                return @"Middle";
            case NOBDDataEntryChangeLocation_End:
                return @"End";
            case NOBDDataEntryChangeLocation_Random:
            default:
                return @"Random";
        }
    }

    return [NSString stringWithFormat:@"%i", row];
}

#pragma mark - Stepper

- (IBAction) stepChange:(id)sender
{
    _changesCount.text = [NSString stringWithFormat:@"%i", (NSInteger)_quantityStepper.value];
}

#pragma mark - editing

- (void) createSection:(NOBDDataEntryChangeLocation)location
{
    NOBDDataSection* section = [[NOBDDataSection alloc] init];
    [section addEntry:NOBDDataEntryChangeLocation_End];
    [section addEntry:NOBDDataEntryChangeLocation_End];
    [section addEntry:NOBDDataEntryChangeLocation_End];
    [_dataSource insertObject:section atLocation:location];
}

- (void) createRow:(NOBDDataEntryChangeLocation)rowLocation
 inSectionLocation:(NOBDDataEntryChangeLocation)sectionLocation
{
    NOBDDataSection* section = [_dataSource objectAtLocation:sectionLocation];
    [section addEntry:rowLocation];
}

- (void) deleteSection:(NOBDDataEntryChangeLocation)location
{
    [_dataSource removeObjectAtLocation:location];
}

- (void) deleteRow:(NOBDDataEntryChangeLocation)rowLocation
 inSectionLocation:(NOBDDataEntryChangeLocation)sectionLocation
{
    NOBDDataSection* section = [_dataSource objectAtLocation:sectionLocation];
    [section.entries removeObjectAtLocation:rowLocation];
}

- (void) modifySection:(NOBDDataEntryChangeLocation)location
{
    NOBDDataSection* section = [_dataSource objectAtLocation:location];
    [section changeProperty];
}

- (void) modifyRow:(NOBDDataEntryChangeLocation)rowLocation
   sectionLocation:(NOBDDataEntryChangeLocation)sectionLocation
{
    NOBDDataSection* section = [_dataSource objectAtLocation:sectionLocation];
    NOBDDataEntry* entry = [section.entries objectAtLocation:rowLocation];
    [entry changeProperty];
}

#pragma mark - Actions

- (IBAction) go:(id)sender
{
    NSInteger type, sectionLocation, rowLocation, count;
    type = [_editTypePicker selectedRowInComponent:0];
    sectionLocation = [_locationPicker selectedRowInComponent:0];
    rowLocation = [_locationPicker selectedRowInComponent:1];
    count = _quantityStepper.value;
    if (count < 1)
        count = 1;

    if (type < 0)
    {
        [self showAlert:@"Must make a \"Change\" selection!"];
        return;
    }
    
    if (sectionLocation < 0)
    {
        [self showAlert:@"Must make a \"Section Location\" selection!"];
        return;
    }
    
    if (rowLocation < 0)
    {
        [self showAlert:@"Must make a \"Row Location\" selection!"];
        return;
    }

    NSLog(@"Modifying Started");
    StartTiming(@"Modifying");
    _oldDataSource = [[NSMutableArray alloc] initWithCapacity:_dataSource.count];
    for (NOBDDataSection* section in _dataSource)
    {
        [_oldDataSource addObject:[section copy]];
    }

    for (NSInteger i = 0; i < count; i++)
    {
        [self execute:type sectionLocation:sectionLocation rowLocation:rowLocation];
    }
    NSLog(@"Modifying Ended: %.4f", StopTiming(@"Modifying"));

    NSLog(@"Update Table View Data Started");
    StartTiming(@"Update");
    [_tableView updateData];
    NSLog(@"Update Table View Data Ended: %.4f", StopTiming(@"Update"));

    _oldDataSource = nil;
}

- (void) execute:(NOBDDataEntryModificationType)type
 sectionLocation:(NOBDDataEntryChangeLocation)sectionLocation
     rowLocation:(NOBDDataEntryChangeLocation)rowLocation
{
    if (NOBDDataEntryModificationType_Random == type)
        type = arc4random() % NOBDDataEntryModificationType_Random;

    if (5 == (NSInteger)rowLocation)
        rowLocation = arc4random() % 5;

    switch (type)
    {
        case NOBDDataEntryModificationType_Insert:
        {
            if (4 == (NSInteger)rowLocation)
            {
                [self createSection:sectionLocation];
            }
            else
            {
                [self createRow:rowLocation inSectionLocation:sectionLocation];
            }
            break;
        }
        case NOBDDataEntryModificationType_Delete:
        {
            if (4 == (NSInteger)rowLocation)
            {
                [self deleteSection:sectionLocation];
            }
            else
            {
                [self deleteRow:rowLocation inSectionLocation:sectionLocation];
            }
            break;
        }
        case NOBDDataEntryModificationType_Modify:
        {
            if (4 == (NSInteger)rowLocation)
            {
                [self modifySection:sectionLocation];
            }
            else
            {
                [self modifyRow:rowLocation sectionLocation:sectionLocation];
            }
            break;
        }
        default:
            break;
    }
}

- (void) showAlert:(NSString*)message
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
