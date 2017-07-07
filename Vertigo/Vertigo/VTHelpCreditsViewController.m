//
//  VTHelpCreditsViewController.m
//  Vertigo
//
//  Created by Evan Long on 7/7/17.
//
//

#import "VTHelpCreditsViewController.h"

@interface VTHelpCreditsViewController ()

@end

@implementation VTHelpCreditsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITextView *textView = [[UITextView alloc] init];
    NSString *licenseInfo = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"LICENSE" withExtension:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    textView.text = licenseInfo;
    textView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    textView.frame = self.view.bounds;
    [self.view addSubview:textView];
}

@end
