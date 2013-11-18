//
//  NOBDDebugSettingsViewController.h
//  TableViewOptimizations
//
//  Created by Nolan O'Brien on 11/10/13.
//  Copyright (c) 2013 NOBrogrammer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kOptimizationKey_RunLoopModes               @"RunLoopModes"
#define kOptimizationKey_BufferedTableView          @"BufferedTableView"
#define kOptimizationKey_BackgroundImageRendering   @"BackgroundImageRendering"

@interface NOBDDebugSettingsViewController : UIViewController
- (id) init;
@end
