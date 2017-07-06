//
//  VTHelpRootViewController.m
//  Vertigo
//
//  Created by Evan Long on 7/2/17.
//
//

#import "VTHelpRootViewController.h"

@interface VTHelpRootViewController ()

@end

@implementation VTHelpRootViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

@end
