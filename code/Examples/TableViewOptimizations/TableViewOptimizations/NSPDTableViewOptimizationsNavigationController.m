//
//  NSPDViewController.m
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/8/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import "NSPDTableViewOptimizationsNavigationController.h"
#import "NSPDNetworkOperationQueue.h"
#import "NSPDGlobalDataSource.h"
#import "NSPDDebugSettingsViewController.h"

@interface NSPDMovieTableViewCell : UITableViewCell
@property (nonatomic, assign) BOOL optimizeRunLoopModes;
@property (nonatomic, assign) BOOL optimizeImageRendering;

- (id) init;
+ (NSString*) reuseIdentifier;

- (void) setMovieInfo:(NSDictionary*)movieInfo;
@end

@interface NSPDTableViewOptimizationsTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (instancetype) init;
@end

@interface NSPDTableViewOptimizationsNavigationController ()
@end

@implementation NSPDTableViewOptimizationsNavigationController

- (instancetype) init
{
    UIViewController* rootVC = [[NSPDTableViewOptimizationsTableViewController alloc] init];
    return [super initWithRootViewController:rootVC];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

@implementation NSPDTableViewOptimizationsTableViewController
{
    UITableView* _table;
    NSIndexPath* _topCell;
}

- (id) init
{
    if (self = [super init])
    {
        self.navigationItem.title = @"Harrison Ford";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                               target:self
                                                                                               action:@selector(debugSettings:)];
    }
    return self;
}

- (void) loadView
{
    [super loadView];
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.delegate = self;
    _table.dataSource = self;
    _table.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_table];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    BOOL translucent = [NSPVersion osVersion].majorVersion >= 7 && self.navigationController.navigationBar.translucent;
    CGRect frame = translucent ? self.navigationController.view.bounds : self.view.bounds;
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOptimizationKey_BufferedTableView])
    {
        CGFloat height = self.view.bounds.size.height;
        frame.size.height += height;
        height /= 2;
        frame.origin.y -= height;
        insets.top = height;
        insets.bottom = height;
    }

    if (translucent)
    {
        insets.top += 64;
    }

    _table.frame = frame;
    _table.scrollIndicatorInsets = insets;
    _table.contentInset = insets;

    if (_topCell)
    {
        [_table scrollToRowAtIndexPath:_topCell
                      atScrollPosition:UITableViewScrollPositionTop
                              animated:NO];
        _topCell = nil;
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _topCell = [_table indexPathForRowAtPoint:[_table convertPoint:CGPointZero fromView:self.view]];
}

- (void) debugSettings:(id)sender
{
    NSPDDebugSettingsViewController* debugVC = [[NSPDDebugSettingsViewController alloc] init];
    debugVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(debugSettingsFinished:)];
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:debugVC];
    if ([NSPVersion osVersion].majorVersion >= 7)
        nav.navigationBar.translucent = NO;
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void) debugSettingsFinished:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [NSPDGlobalDataSource globalDataSource].results.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSPDMovieTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[NSPDMovieTableViewCell reuseIdentifier]];
    if (!cell)
    {
        cell = [[NSPDMovieTableViewCell alloc] init];
    }

    cell.optimizeImageRendering = [[NSUserDefaults standardUserDefaults] boolForKey:kOptimizationKey_BackgroundImageRendering];
    cell.optimizeRunLoopModes = [[NSUserDefaults standardUserDefaults] boolForKey:kOptimizationKey_RunLoopModes];
    [cell setMovieInfo:[[NSPDGlobalDataSource globalDataSource].results objectAtIndex:indexPath.row]];

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 70;
//}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

@end

@implementation NSPDMovieTableViewCell
{
    UILabel* _title;
    UIImageView* _poster;
    AFHTTPRequestOperation* _imageOp;
}

+ (NSString*) reuseIdentifier
{
    return @"NSPDMovieTableViewCell";
}

- (id) init
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NSPDMovieTableViewCell reuseIdentifier]])
    {
        self.backgroundColor = [UIColor whiteColor];
        
        _poster = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 50, 50)];
        _poster.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        _poster.contentMode = UIViewContentModeScaleAspectFit;
        _poster.backgroundColor = [UIColor clearColor];

        _title = [[UILabel alloc] initWithFrame:CGRectMake(70, 10, 320-120-10, self.bounds.size.height - 20)];
        _title.backgroundColor = [UIColor clearColor];
        _title.textColor = [UIColor blackColor];
        _title.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _title.font = [UIFont systemFontOfSize:14];

        [self.contentView addSubview:_poster];
        [self.contentView addSubview:_title];
    }
    return self;
}

- (void) prepareForReuse
{
    [_imageOp cancel];
    _imageOp = nil;
    _title.text = nil;
    _poster.image = nil;
}

- (void) setMovieInfo:(NSDictionary*)movieInfo
{
    _title.text = [movieInfo objectForKey:@"trackName"];

    _imageOp = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[movieInfo objectForKey:@"artworkUrl100"]]]];
    [_imageOp setCacheResponseBlock:^NSCachedURLResponse*(NSURLConnection* connection, NSCachedURLResponse* cachedResponse) {
        return nil; // no image cache
    }];
    if (!_optimizeRunLoopModes)
    {
        [_imageOp setRunLoopModes:[NSSet setWithObject:NSDefaultRunLoopMode]];
    }

    __weak typeof(self) weakSelf = self;
    [_imageOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation* op, id responseObject) { [weakSelf loadImage:op success:YES]; }
                                    failure:^(AFHTTPRequestOperation* op, NSError* error) { [weakSelf loadImage:op success:NO]; }];
    [_imageOp begin];
}

- (void) loadImage:(AFHTTPRequestOperation*)imageOp success:(BOOL)success
{
    if (success)
    {
        if (_optimizeImageRendering)
        {
            [UIImage imageByRenderingData:imageOp.responseData
                               completion:^(UIImage* image) {
                                   [self setPoster:image];
                               }];
        }
        else
        {
            [self setPoster:[UIImage imageWithData:imageOp.responseData]];
        }
    }

    if (imageOp == _imageOp)
        _imageOp = nil;
}

- (void) setPoster:(UIImage*)image
{
    _poster.image = image;
}

@end
