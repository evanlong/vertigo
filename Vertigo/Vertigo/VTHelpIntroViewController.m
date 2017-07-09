//
//  VTHelpIntroViewController.m
//  Vertigo
//
//  Created by Evan Long on 7/7/17.
//
//

#import "VTHelpIntroViewController.h"

#import "VTHelpIntroPageViewController.h"

@interface VTHelpIntroViewController () <UIPageViewControllerDataSource>

@property (nonatomic, copy) NSArray<UIViewController *> *pages;

@end

@implementation VTHelpIntroViewController

+ (void)initialize
{
    if (self == [VTHelpIntroViewController class])
    {
        UIPageControl *pageControlAppearance = [UIPageControl appearanceWhenContainedInInstancesOfClasses:@[[VTHelpIntroViewController class]]];
        pageControlAppearance.pageIndicatorTintColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        pageControlAppearance.currentPageIndicatorTintColor = [UIColor colorWithWhite:0.1 alpha:0.8];
    }
}

static id commonInit(VTHelpIntroViewController *self)
{
    if (self)
    {
        self->_pages = @[[[VTHelpIntroPushPageViewController alloc] init],
                         [[VTHelpIntroPullPageViewController alloc] init],
                         ];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self = commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self = commonInit(self);
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self = commonInit(self);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;

    UIPageViewController *pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    [pageViewController setViewControllers:@[self.pages.firstObject] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    pageViewController.dataSource = self;
    [self addChildViewController:pageViewController];
    pageViewController.view.frame = self.view.bounds;
    pageViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:pageViewController.view];
    VTAllowAutolayoutForView(pageViewController.view);
    [pageViewController didMoveToParentViewController:self];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSString *)title
{
    return  NSLocalizedString(@"HelpIntro", nil);
}

#pragma mark - UIPageViewControllerDataSource

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger indexOfViewController = [self.pages indexOfObject:viewController];
    if (indexOfViewController == 0)
    {
        return nil;
    }
    else
    {
        return self.pages[indexOfViewController - 1];
    }
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger indexOfViewController = [self.pages indexOfObject:viewController];
    if (indexOfViewController == self.pages.count - 1)
    {
        return nil;
    }
    else
    {
        return self.pages[indexOfViewController + 1];
    }
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return self.pages.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

@end
