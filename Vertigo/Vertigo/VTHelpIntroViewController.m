//
//  VTHelpIntroViewController.m
//  Vertigo
//
//  Created by Evan Long on 7/7/17.
//
//

#import "VTHelpIntroViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "VTPlayerView.h"
#import "VTPushPullAnimationView.h"

@interface VTHelpIntroViewController ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *footerLabel;

@property (nonatomic, strong) VTPushPullAnimationView *cameraAnimation;

@end

@implementation VTHelpIntroViewController

static id commonInit(VTHelpIntroViewController *self)
{
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleContentSizeChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.playerItem = [AVPlayerItem playerItemWithURL:[[NSBundle mainBundle] URLForResource:@"plane_push_720_pull" withExtension:@"m4v"]];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.player.allowsExternalPlayback = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_itemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
    self.headerLabel = [[UILabel alloc] init];
    VTAllowAutolayoutForView(self.headerLabel);
    self.headerLabel.numberOfLines = 0;
    self.headerLabel.textAlignment = NSTextAlignmentCenter;
    self.headerLabel.text = NSLocalizedString(@"PushEffect", nil);
    self.headerLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.headerLabel];
    
    self.footerLabel = [[UILabel alloc] init];
    VTAllowAutolayoutForView(self.footerLabel);
    self.footerLabel.numberOfLines = 0;
    self.footerLabel.textAlignment = NSTextAlignmentCenter;
    self.footerLabel.text = NSLocalizedString(@"PushEffectDetail", nil);
    self.footerLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.footerLabel];
    
    UILayoutGuide *spaceBetweenHeaderLabelAndCenterGuide = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:spaceBetweenHeaderLabelAndCenterGuide];
    
    VTPlayerView *playerView = [[VTPlayerView alloc] init];
    VTAllowAutolayoutForView(playerView);
    playerView.layer.shadowColor = [UIColor blackColor].CGColor;
    playerView.layer.shadowRadius = 2.5;
    playerView.layer.shadowOpacity = 0.75;
    playerView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    playerView.player = self.player;
    [self.view addSubview:playerView];
    
    UIView *horizontalBreak = [[UIView alloc] init];
    VTAllowAutolayoutForView(horizontalBreak);
    horizontalBreak.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.4];
    horizontalBreak.layer.shadowColor = [UIColor blackColor].CGColor;
    horizontalBreak.layer.shadowRadius = 2.5;
    horizontalBreak.layer.shadowOpacity = 0.75;
    horizontalBreak.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    [self.view addSubview:horizontalBreak];
    
    UILayoutGuide *spaceBetweenCenterAndFooterGuide = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:spaceBetweenCenterAndFooterGuide];
    
    UIImageView *planeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Plane"]];
    VTAllowAutolayoutForView(planeImageView);
    planeImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:planeImageView];
    
    self.cameraAnimation = [[VTPushPullAnimationView alloc] init];
    VTAllowAutolayoutForView(self.cameraAnimation);
    self.cameraAnimation.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [self.view addSubview:self.cameraAnimation];
    
    UILayoutGuide *rotatedCameraAnimationSizeGuide = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:rotatedCameraAnimationSizeGuide];
    
    [spaceBetweenHeaderLabelAndCenterGuide.topAnchor constraintEqualToAnchor:self.headerLabel.bottomAnchor].active = YES;
    [spaceBetweenHeaderLabelAndCenterGuide.bottomAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    
    [spaceBetweenCenterAndFooterGuide.topAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    [spaceBetweenCenterAndFooterGuide.bottomAnchor constraintEqualToAnchor:self.footerLabel.topAnchor].active = YES;
    
    [rotatedCameraAnimationSizeGuide.heightAnchor constraintEqualToAnchor:self.cameraAnimation.widthAnchor].active = YES;
    [rotatedCameraAnimationSizeGuide.widthAnchor constraintEqualToAnchor:self.cameraAnimation.heightAnchor].active = YES;
    [rotatedCameraAnimationSizeGuide.rightAnchor constraintEqualToAnchor:playerView.rightAnchor].active = YES;
    [rotatedCameraAnimationSizeGuide.centerYAnchor constraintEqualToAnchor:spaceBetweenCenterAndFooterGuide.centerYAnchor].active = YES;
    
    [self.headerLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.headerLabel.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:20.0].active = YES;
    
    [self.footerLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.footerLabel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-20.0].active = YES;
    [self.footerLabel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.75].active = YES;
    
    [playerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [playerView.centerYAnchor constraintEqualToAnchor:spaceBetweenHeaderLabelAndCenterGuide.centerYAnchor constant:-4.0].active = YES;
    [playerView.heightAnchor constraintEqualToAnchor:playerView.widthAnchor multiplier:720.0/1280.0].active = YES;
    [playerView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.9].active = YES;
    
    [horizontalBreak.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [horizontalBreak.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    [horizontalBreak.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [horizontalBreak.heightAnchor constraintEqualToConstant:1.0].active = YES;
    
    [planeImageView.centerYAnchor constraintEqualToAnchor:spaceBetweenCenterAndFooterGuide.centerYAnchor].active = YES;
    [planeImageView.leftAnchor constraintEqualToAnchor:playerView.leftAnchor].active = YES;
    [planeImageView.rightAnchor constraintLessThanOrEqualToAnchor:rotatedCameraAnimationSizeGuide.leftAnchor constant:20.0].active = YES;

    [self.cameraAnimation.centerXAnchor constraintEqualToAnchor:rotatedCameraAnimationSizeGuide.centerXAnchor].active = YES;
    [self.cameraAnimation.centerYAnchor constraintEqualToAnchor:spaceBetweenCenterAndFooterGuide.centerYAnchor].active = YES;
    
    [self _updateLabelFonts];
    [self _updatePlayback];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSString *)title
{
    return  NSLocalizedString(@"HelpIntro", nil);
}

#pragma mark - Notifications

- (void)_handleContentSizeChange:(NSNotification *)notification
{
    [self _updateLabelFonts];
}

- (void)_itemDidPlayToEnd:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updatePlayback];
    });
}

- (void)_applicationDidBecomeActive:(NSNotification *)notification
{
    [self _updatePlayback];
}

#pragma mark - Private

- (void)_updateLabelFonts
{
    self.headerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.footerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)_updatePlayback
{
    [self _updatePushPullAnimation];
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)_updatePushPullAnimation
{
    [self.cameraAnimation removeAllAnimations];
    [self.cameraAnimation addPullAnimationReverse:YES totalDuration:3.0 completionBlock:nil];
}

@end
