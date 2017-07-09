//
//  VTHelpRootViewController.m
//  Vertigo
//
//  Created by Evan Long on 7/2/17.
//
//

#import "VTHelpRootViewController.h"

#import "VTHelpCreditsViewController.h"
#import "VTHelpIntroViewController.h"
#import "VTHelpStepByStepViewController.h"

static NSString *const VTHelpTitleKey = @"VTHelpTitleKey";
static NSString *const VTHelpViewControllerClassKey = @"VTHelpViewControllerClassKey";

@interface VTHelpRootViewController ()

@property (nonatomic, copy) NSArray<NSDictionary<NSString *, Class> *> *helpViewControllers;

@end

@implementation VTHelpRootViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        _helpViewControllers = @[@{VTHelpTitleKey : NSLocalizedString(@"HelpIntroDetail", nil), VTHelpViewControllerClassKey : [VTHelpIntroViewController class]},
//                                 @{VTHelpTitleKey : NSLocalizedString(@"HelpUsingTheApp", nil), VTHelpViewControllerClassKey : [VTHelpStepByStepViewController class]},
                                 @{VTHelpTitleKey : NSLocalizedString(@"HelpCredits", nil), VTHelpViewControllerClassKey : [VTHelpCreditsViewController class]},
                                 ];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSString *)title
{
    return NSLocalizedString(@"HelpTitle", nil);
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *element = self.helpViewControllers[indexPath.row];
    Class helpVCClass = element[VTHelpViewControllerClassKey];
    
    UIViewController *helpVC = [[helpVCClass alloc] init];
    [self.navigationController pushViewController:helpVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.helpViewControllers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSDictionary *element = self.helpViewControllers[indexPath.row];
    NSString *title = element[VTHelpTitleKey];
    
    cell.textLabel.text = title;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

@end
