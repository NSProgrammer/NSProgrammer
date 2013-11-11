//
//  NSPDDebugSettingsViewController.m
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/10/13.
//  Copyright (c) 2013 NSProgrammer. All rights reserved.
//

#import "NSPDDebugSettingsViewController.h"

@interface NSPDDebugSettingsViewController ()

@end

@implementation NSPDDebugSettingsViewController
{
    IBOutlet UISwitch* _runLoopSwitch;
    IBOutlet UISwitch* _bufferSwitch;
    IBOutlet UISwitch* _renderingSwitch;
}

- (id)init
{
    self = [super initWithNibName:@"NSPDDebugSettingsViewController" bundle:nil];
    if (self) {
        // Custom initialization
        self.navigationItem.title = @"Settings";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _runLoopSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kOptimizationKey_RunLoopModes];
    _bufferSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kOptimizationKey_BufferedTableView];
    _renderingSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kOptimizationKey_BackgroundImageRendering];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) didUpdateSwitch:(id)sender
{
    if (sender == _runLoopSwitch)
    {
        [[NSUserDefaults standardUserDefaults] setBool:_runLoopSwitch.isOn forKey:kOptimizationKey_RunLoopModes];
    }
    else if (sender == _bufferSwitch)
    {
        [[NSUserDefaults standardUserDefaults] setBool:_bufferSwitch.isOn forKey:kOptimizationKey_BufferedTableView];
    }
    else if (sender == _renderingSwitch)
    {
        [[NSUserDefaults standardUserDefaults] setBool:_renderingSwitch.isOn forKey:kOptimizationKey_BackgroundImageRendering];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
