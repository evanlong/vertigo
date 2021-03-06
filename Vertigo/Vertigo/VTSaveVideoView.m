//
//  VTSaveVideoView.m
//  Vertigo
//
//  Created by Evan Long on 4/19/17.
//
//

#import "VTSaveVideoView.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "HFKVOBlocks.h"
#import "VTCaptureTypes.h"
#import "VTOverlayButton.h"
#import "VTMath.h"
#import "VTPlayerView.h"
#import "VTPushPullAnimationView.h"
#import "VTTargetAnimationView.h"
#import "VTZoomEffect.h"

#import "UIView+VTUtil.h"

#define CONTROL_BACKDROP_COLOR          [UIColor colorWithWhite:0.1 alpha:0.70]

@interface VTSaveVideoView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) id playerTimeObserver;
@property (nonatomic, strong) id playerItemStatusObserver;

@property (nonatomic, strong) UIView *clippingView;

@property (nonatomic, strong) VTPlayerView *playerView;

@property (nonatomic, assign) float secondsComplete;
@property (nonatomic, assign) float secondsTotal;

@property (nonatomic, strong) UIView *controlHostView;
@property (nonatomic, strong) VTOverlayButton *backArrowButton;
@property (nonatomic, strong) VTOverlayButton *shareButton;
@property (nonatomic, strong) VTOverlayButton *helpButton;
@property (nonatomic, strong) UISlider *zoomAdjustSlider;
@property (nonatomic, strong) UILayoutGuide *sliderSpaceGuide;
@property (nonatomic, strong) UIView *sliderMidpointView;
@property (nonatomic, strong) UILabel *zoomLevelLabel;

@property (nonatomic, strong) UILayoutGuide *shareButtonCenterXGuide;
@property (nonatomic, strong) NSLayoutConstraint *shareButtonGuidePortraitLeft;
@property (nonatomic, strong) NSLayoutConstraint *shareButtonGuideLandscapeLeft;

@property (nonatomic, strong) VTTargetAnimationView *targetAnimationView;
@property (nonatomic, strong) VTPushPullAnimationView *pushAnimationView;
@property (nonatomic, strong) VTPushPullAnimationView *pullAnimationView;
@property (nonatomic, strong) VTPushPullAnimationView *staticAnimationView;
@property (nonatomic, assign, getter=isTouchingZoomSlider) BOOL touchingZoomSlider;

@property (nonatomic, copy) NSArray *portraitCameraConstraints;
@property (nonatomic, copy) NSArray *landscapeCameraConstraints;

@end

@implementation VTSaveVideoView

- (instancetype)initWithVideoURL:(NSURL *)videoURL
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        _videoURL = videoURL;
        _playerItem = [AVPlayerItem playerItemWithURL:videoURL];
        _player = [AVPlayer playerWithPlayerItem:_playerItem];
        _player.allowsExternalPlayback = NO;
        
        _clippingView = [[UIView alloc] init];
        _clippingView.clipsToBounds = YES;
        [self addSubview:_clippingView];

        _playerView = [[VTPlayerView alloc] init];
        VTAllowAutolayoutForView(_playerView);
        _playerView.player = _player;
        [_clippingView addSubview:_playerView];
        
        _controlHostView = [[UIView alloc] init];
        VTAllowAutolayoutForView(_controlHostView);
        [self addSubview:_controlHostView];
        
        _sliderMidpointView = [[UIView alloc] init];
        _sliderMidpointView.backgroundColor = [UIColor whiteColor];
        _sliderMidpointView.layer.shadowColor = [UIColor blackColor].CGColor;
        _sliderMidpointView.layer.shadowRadius = 2.25;
        _sliderMidpointView.layer.shadowOpacity = 1.0;
        _sliderMidpointView.layer.shadowOffset = CGSizeZero;
        VTAllowAutolayoutForView(_sliderMidpointView);
        [_controlHostView addSubview:_sliderMidpointView];

        _zoomAdjustSlider = [[UISlider alloc] init];
        VTAllowAutolayoutForView(_zoomAdjustSlider);
        _zoomAdjustSlider.layer.shadowColor = [UIColor blackColor].CGColor;
        _zoomAdjustSlider.layer.shadowRadius = 2.25;
        _zoomAdjustSlider.layer.shadowOpacity = 1.0;
        _zoomAdjustSlider.layer.shadowOffset = CGSizeZero;
        _zoomAdjustSlider.tintColor = [UIColor whiteColor];
        _zoomAdjustSlider.minimumValue = -2.0;
        _zoomAdjustSlider.maximumValue = 2.0;
        _zoomAdjustSlider.minimumTrackTintColor = [UIColor whiteColor];
        _zoomAdjustSlider.maximumTrackTintColor = [UIColor whiteColor];
        _zoomAdjustSlider.minimumValueImage = [UIImage imageNamed:@"LeftIcon"];
        _zoomAdjustSlider.maximumValueImage = [UIImage imageNamed:@"RightIcon"];
        [_zoomAdjustSlider addTarget:self action:@selector(_handleZoomSliderValueChanged) forControlEvents:UIControlEventValueChanged];
        [_zoomAdjustSlider addTarget:self action:@selector(_handleZoomSliderTouchDown) forControlEvents:UIControlEventTouchDown];
        [_zoomAdjustSlider addTarget:self action:@selector(_handleZoomSliderTouchUp) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
        [_controlHostView addSubview:_zoomAdjustSlider];
        
        _zoomLevelLabel = [[UILabel alloc] init];
        _zoomLevelLabel.textAlignment = NSTextAlignmentRight;
        _zoomLevelLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _zoomLevelLabel.layer.shadowRadius = 2.0;
        _zoomLevelLabel.layer.shadowOpacity = 1.0;
        _zoomLevelLabel.layer.shadowOffset = CGSizeZero;
        [_controlHostView addSubview:_zoomLevelLabel];
        
        _targetAnimationView = [[VTTargetAnimationView alloc] init];
        VTAllowAutolayoutForView(_targetAnimationView);
        [_targetAnimationView addBorderAnimation];
        [_controlHostView addSubview:_targetAnimationView];
        
        _pullAnimationView = [[VTPushPullAnimationView alloc] init];
        VTAllowAutolayoutForView(_pullAnimationView);
        [_controlHostView addSubview:_pullAnimationView];

        _pushAnimationView = [[VTPushPullAnimationView alloc] init];
        VTAllowAutolayoutForView(_pushAnimationView);
        [_controlHostView addSubview:_pushAnimationView];
        
        _staticAnimationView = [[VTPushPullAnimationView alloc] init];
        VTAllowAutolayoutForView(_staticAnimationView);
        [_controlHostView addSubview:_staticAnimationView];

        _backArrowButton = [[VTOverlayButton alloc] initWithOverlayImageName:@"BackIcon"];
        VTAllowAutolayoutForView(_backArrowButton);
        [_backArrowButton addTarget:self action:@selector(_handleDiscardButtonPress) forControlEvents:UIControlEventTouchUpInside];
        [_controlHostView addSubview:_backArrowButton];
        
        _shareButton = [[VTOverlayButton alloc] initWithOverlayImageName:@"Sharrow"];
        VTAllowAutolayoutForView(_shareButton);
        [_shareButton addTarget:self action:@selector(_handleShareButtonPress) forControlEvents:UIControlEventTouchUpInside];
        [_controlHostView addSubview:_shareButton];
        
        _helpButton = [[VTOverlayButton alloc] initWithOverlayImageName:@"HelpIcon"];
        VTAllowAutolayoutForView(_helpButton);
        [_helpButton addTarget:self action:@selector(_handleHelpButtonPress) forControlEvents:UIControlEventTouchUpInside];
        [_controlHostView addSubview:_helpButton];
        
        VTWeakifySelf(weakSelf);
        
        _playerItemStatusObserver = [_playerItem hf_addBlockObserver:^(id  _Nonnull object, NSDictionary * _Nonnull change) {
            VTStrongifySelf(strongSelf, weakSelf);
            if (strongSelf)
            {
                [self _handePlayerItemStatusChange];
            }
        } forKeyPath:VTKeyPath(_playerItem, status)];
        
        _playerTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0/60.0, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            VTStrongifySelf(strongSelf, weakSelf);
            if (strongSelf)
            {
                strongSelf.secondsTotal = 1.0 * strongSelf.playerItem.duration.value / strongSelf.playerItem.duration.timescale;
                strongSelf.secondsComplete = 1.0 * time.value / time.timescale;
            }
        }];
        
        {
            [_controlHostView.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
            [_controlHostView.heightAnchor constraintEqualToAnchor:self.heightAnchor].active = YES;
            [_controlHostView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            [_controlHostView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        }
        
        { // Bottom Share/Save Controls
            _shareButtonCenterXGuide = [[UILayoutGuide alloc] init];
            [self addLayoutGuide:_shareButtonCenterXGuide];
            
            _shareButtonGuidePortraitLeft = [_shareButtonCenterXGuide.leftAnchor constraintEqualToAnchor:self.leftAnchor];
            _shareButtonGuideLandscapeLeft = [_shareButtonCenterXGuide.leftAnchor constraintEqualToAnchor:self.centerXAnchor];
            
            [_shareButtonCenterXGuide.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
            [_shareButton.centerXAnchor constraintEqualToAnchor:_shareButtonCenterXGuide.centerXAnchor].active = YES;
            [_shareButton.centerYAnchor constraintEqualToAnchor:_controlHostView.bottomAnchor constant:-54.0].active = YES;
        }
        
        { // Back Arrow
            [_backArrowButton.leftAnchor constraintEqualToAnchor:_controlHostView.leftAnchor constant:24.0].active = YES;
            [_backArrowButton.topAnchor constraintEqualToAnchor:_controlHostView.topAnchor constant:24.0].active = YES;
        }
        
        {
            [_helpButton.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:24.0].active = YES;
            [_helpButton.centerYAnchor constraintEqualToAnchor:_shareButton.centerYAnchor].active = YES;
        }
        
        {
            UILayoutGuide *sliderGuideTopInset = [[UILayoutGuide alloc] init];
            [_controlHostView addLayoutGuide:sliderGuideTopInset];
            [sliderGuideTopInset.topAnchor constraintEqualToAnchor:_controlHostView.topAnchor].active = YES;
            [sliderGuideTopInset.bottomAnchor constraintEqualToAnchor:_backArrowButton.topAnchor].active = YES;
            
            UILayoutGuide *sliderGuideBottomInset = [[UILayoutGuide alloc] init];
            [_controlHostView addLayoutGuide:sliderGuideBottomInset];
            [sliderGuideBottomInset.topAnchor constraintEqualToAnchor:_shareButton.topAnchor].active = YES;
            [sliderGuideBottomInset.bottomAnchor constraintEqualToAnchor:_controlHostView.bottomAnchor].active = YES;
            
            _sliderSpaceGuide = [[UILayoutGuide alloc] init];
            [_controlHostView addLayoutGuide:_sliderSpaceGuide];
            [_sliderSpaceGuide.topAnchor constraintEqualToAnchor:sliderGuideTopInset.bottomAnchor].active = YES;
            [_sliderSpaceGuide.bottomAnchor constraintEqualToAnchor:sliderGuideBottomInset.topAnchor].active = YES;
            [_sliderSpaceGuide.leftAnchor constraintEqualToAnchor:_zoomAdjustSlider.centerXAnchor].active = YES;
            
            [_zoomAdjustSlider.centerXAnchor constraintEqualToAnchor:_controlHostView.rightAnchor constant:-40.0].active = YES;
            [_zoomAdjustSlider.centerYAnchor constraintEqualToAnchor:_sliderSpaceGuide.centerYAnchor].active = YES;
            [_zoomAdjustSlider.widthAnchor constraintEqualToAnchor:_sliderSpaceGuide.heightAnchor].active = YES;
            _zoomAdjustSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
            
            [_sliderMidpointView.widthAnchor constraintEqualToConstant:20.0].active = YES;
            [_sliderMidpointView.heightAnchor constraintEqualToConstant:4.0].active = YES;
            [_sliderMidpointView.rightAnchor constraintEqualToAnchor:_controlHostView.rightAnchor constant:-4.0].active = YES;
            [_sliderMidpointView.centerYAnchor constraintEqualToAnchor:_sliderSpaceGuide.centerYAnchor].active = YES;
        }
        
        {
            [_targetAnimationView.centerXAnchor constraintEqualToAnchor:_pushAnimationView.centerXAnchor].active = YES;
            [_targetAnimationView.topAnchor constraintEqualToAnchor:_pushAnimationView.topAnchor].active = YES;

            // Portrait
            self.portraitCameraConstraints = @[[_pushAnimationView.centerYAnchor constraintEqualToAnchor:_controlHostView.centerYAnchor],
                                               [_pullAnimationView.centerYAnchor constraintEqualToAnchor:_controlHostView.centerYAnchor],
                                               [_staticAnimationView.centerYAnchor constraintEqualToAnchor:_controlHostView.centerYAnchor],
                                               [_pushAnimationView.leftAnchor constraintEqualToAnchor:_controlHostView.leftAnchor constant:10.0],
                                               [_pullAnimationView.leftAnchor constraintEqualToAnchor:_controlHostView.leftAnchor constant:10.0],
                                               [_staticAnimationView.leftAnchor constraintEqualToAnchor:_controlHostView.leftAnchor constant:10.0],
                                               ];
            // Landscape
            self.landscapeCameraConstraints = @[[_pullAnimationView.topAnchor constraintEqualToAnchor:_backArrowButton.bottomAnchor constant:20.0],
                                                [_pushAnimationView.topAnchor constraintEqualToAnchor:_backArrowButton.bottomAnchor constant:20.0],
                                                [_staticAnimationView.topAnchor constraintEqualToAnchor:_backArrowButton.bottomAnchor constant:20.0],
                                                [_pushAnimationView.leftAnchor constraintEqualToAnchor:_backArrowButton.rightAnchor constant:10.0],
                                                [_pullAnimationView.leftAnchor constraintEqualToAnchor:_backArrowButton.rightAnchor constant:10.0],
                                                [_staticAnimationView.leftAnchor constraintEqualToAnchor:_backArrowButton.rightAnchor constant:10.0],
                                                ];
        }
        
        {
            [_playerView.centerXAnchor constraintEqualToAnchor:_clippingView.centerXAnchor].active = YES;
            [_playerView.centerYAnchor constraintEqualToAnchor:_clippingView.centerYAnchor].active = YES;
            [_playerView.widthAnchor constraintEqualToAnchor:_clippingView.widthAnchor].active = YES;
            [_playerView.heightAnchor constraintEqualToAnchor:_clippingView.heightAnchor].active = YES;
        }
        
        [UIView performWithoutAnimation:^{
            [self _updatePushPullAnimationVisibility];
            [self _updateZoomLevelLabelText];
        }];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_itemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [_player removeTimeObserver:_playerTimeObserver];
    [_playerItem hf_removeBlockObserverWithToken:_playerItemStatusObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (CGRectGetWidth(self.bounds) < CGRectGetHeight(self.bounds))
    {
        self.shareButtonGuideLandscapeLeft.active = NO;
        [NSLayoutConstraint deactivateConstraints:self.landscapeCameraConstraints];
        [NSLayoutConstraint activateConstraints:self.portraitCameraConstraints];
        self.shareButtonGuidePortraitLeft.active = YES;
    }
    else
    {
        self.shareButtonGuidePortraitLeft.active = NO;
        [NSLayoutConstraint deactivateConstraints:self.portraitCameraConstraints];
        [NSLayoutConstraint activateConstraints:self.landscapeCameraConstraints];
        self.shareButtonGuideLandscapeLeft.active = YES;
    }
    
    // Update layout of controlHostView now since _updateZoomLevelLabelPosition depends on UISlider being the correct size when it runs
    [self.controlHostView layoutIfNeeded];

    CGRect clippingViewFrame = self.bounds;
    CGSize presentationSize = self.playerItem.presentationSize;
    if (!CGSizeEqualToSize(presentationSize, CGSizeZero))
    {
        clippingViewFrame = AVMakeRectWithAspectRatioInsideRect(presentationSize, self.bounds);
    }
    self.clippingView.frame = clippingViewFrame;
    
    [UIView performWithoutAnimation:^{
        [self _updateZoomLevelLabelPosition];
    }];
    
#if 0
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIImage *i = [self renderedAsImage];
        NSString *f = [NSTemporaryDirectory() stringByAppendingPathComponent:@"save_video_view_screenshot.png"];
        [UIImagePNGRepresentation(i) writeToFile:f atomically:YES];
    });
#endif
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    [self _updatePlayback];
    [self _updatePushPullAnimationVisibility];
}

#pragma mark - VTSaveVideoView

- (void)setSecondsComplete:(float)secondsComplete
{
    if (_secondsComplete != secondsComplete)
    {
        _secondsComplete = secondsComplete;
        [self _updateVideoScale];
    }
}

- (void)setTouchingZoomSlider:(BOOL)touchingZoomSlider
{
    if (_touchingZoomSlider != touchingZoomSlider)
    {
        _touchingZoomSlider = touchingZoomSlider;
        [self _updatePushPullAnimationVisibility];
    }
}

- (VTZoomEffectSettings *)settings
{
    const VTDirectionMagnitude dm = [self _directionMagnitide];
    const CGFloat targetScale = dm.magnitude;
    
    VTMutableZoomEffectSettings *settings = [[VTMutableZoomEffectSettings alloc] init];
    if (dm.direction == VTVertigoDirectionPull)
    {
        settings.initalZoomLevel = 1.0;
        settings.finalZoomLevel = targetScale;
    }
    else
    {
        settings.initalZoomLevel = targetScale;
        settings.finalZoomLevel = 1.0;
    }
    
    settings.duration = self.secondsTotal;
    
    return [settings copy];
}

- (void)setHideControls:(BOOL)hideControls
{
    [self setHideControls:hideControls animated:NO];
}

- (void)setHideControls:(BOOL)hideControls animated:(BOOL)animated
{
    if (_hideControls != hideControls)
    {
        _hideControls = hideControls;
        void(^block)(void) = ^{
            self.controlHostView.alpha = hideControls ? 0.0 : 1.0;
            self.controlHostView.transform = hideControls ? CGAffineTransformMakeScale(0.97, 0.97) : CGAffineTransformIdentity;
        };
        
        if (animated)
        {
            [UIView animateWithDuration:0.33 animations:block];
        }
        else
        {
            block();
        }
    }
}

#pragma mark - Events

- (void)_handleShareButtonPress
{
    id<VTSaveVideoViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(saveVideoViewDidPressShare:)])
    {
        [delegate saveVideoViewDidPressShare:self];
    }
}

- (void)_handleHelpButtonPress
{
    id<VTSaveVideoViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(saveVideoViewDidPressHelp:)])
    {
        [delegate saveVideoViewDidPressHelp:self];
    }
}

- (void)_handleSaveButtonPress
{
    id<VTSaveVideoViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(saveVideoViewDidPressSave:)])
    {
        [delegate saveVideoViewDidPressSave:self];
    }
}

- (void)_handleDiscardButtonPress
{
    id<VTSaveVideoViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(saveVideoViewDidPressDiscard:)])
    {
        [delegate saveVideoViewDidPressDiscard:self];
    }
}

- (void)_handePlayerItemStatusChange
{
    [self _updatePlayback];
}

- (void)_handleZoomSliderValueChanged
{
    [self _updatePushPullAnimationVisibility];
    [self _updateZoomLevelLabelText];
    [self _updateZoomLevelLabelPosition];
}

- (void)_handleZoomSliderTouchDown
{
    self.touchingZoomSlider = YES;
}

- (void)_handleZoomSliderTouchUp
{
    self.touchingZoomSlider = NO;
}

#pragma mark - Notifications

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

#pragma mark - Player

- (void)_updatePlayback
{
    [self _updatePushPullAnimation];

    [self.player seekToTime:kCMTimeZero];

    if (self.playerItem.status == AVPlayerStatusReadyToPlay && self.superview && [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        [self.player play];
    }
    else
    {
        [self.player pause];
    }
}

- (void)_updateVideoScale
{
    VTZoomEffectSettings *settings = self.settings;
    CGFloat scale = VTVertigoEffectZoomPowerScale(settings.initalZoomLevel, settings.finalZoomLevel, self.secondsComplete, self.secondsTotal);
    self.playerView.transform = CGAffineTransformMakeScale(scale, scale);
}

#pragma mark - Private

- (void)_updatePushPullAnimation
{
    [self.pushAnimationView removeAllAnimations];
    [self.pullAnimationView removeAllAnimations];
 
    [self.pushAnimationView addPullAnimationReverse:YES totalDuration:MAX(1.0, self.secondsTotal) completionBlock:nil];
    [self.pullAnimationView addPullAnimationReverse:NO totalDuration:MAX(1.0, self.secondsTotal) completionBlock:nil];
}

- (void)_updatePushPullAnimationVisibility
{
    VTDirectionMagnitude dm = [self _directionMagnitide];
    if (VTFloatIsEqual(dm.magnitude, 1.0) && !self.isTouchingZoomSlider)
    {
        self.pushAnimationView.hidden = YES;
        self.pullAnimationView.hidden = YES;
        self.staticAnimationView.hidden = NO;
    }
    else if (dm.direction == VTVertigoDirectionPush)
    {
        self.pushAnimationView.hidden = NO;
        self.pullAnimationView.hidden = YES;
        self.staticAnimationView.hidden = YES;
    }
    else
    {
        self.pushAnimationView.hidden = YES;
        self.pullAnimationView.hidden = NO;
        self.staticAnimationView.hidden = YES;
    }
}

- (VTDirectionMagnitude)_directionMagnitide
{
    VTDirectionMagnitude dm;
    
    CGFloat targetScale = VTRoundToNearestFactor(self.zoomAdjustSlider.value, 0.05);
    dm.direction = targetScale <= 0.0 ? VTVertigoDirectionPull : VTVertigoDirectionPush;
    dm.magnitude = ABS(targetScale) + 1.0;
    return dm;
}

- (void)_updateZoomLevelLabelText
{
    VTDirectionMagnitude dm = [self _directionMagnitide];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSStrokeColorAttributeName : [UIColor colorWithWhite:0.0 alpha:0.5],
                                 NSStrokeWidthAttributeName : @(-2.0),
                                 NSFontAttributeName : [UIFont monospacedDigitSystemFontOfSize:22.0 weight:UIFontWeightBold]};
    NSString *zoomLevelText = [NSString stringWithFormat:NSLocalizedString(@"ZoomLevel", nil), dm.magnitude];
    self.zoomLevelLabel.attributedText = [[NSAttributedString alloc] initWithString:zoomLevelText attributes:attributes];
}

- (void)_updateZoomLevelLabelPosition
{
    [self.zoomLevelLabel sizeToFit];
    
    CGRect trackRect = [self.zoomAdjustSlider trackRectForBounds:self.zoomAdjustSlider.bounds];
    
    CGFloat zoomLevelLabelHeight = CGRectGetHeight(self.zoomLevelLabel.bounds);
    CGRect guideFrame = self.sliderSpaceGuide.layoutFrame;
    CGFloat sliderHeight = CGRectGetWidth(trackRect) - zoomLevelLabelHeight; // width -> height since slider is rotated 90 degrees
    CGFloat guideCenterY = CGRectGetMidY(guideFrame);
    CGFloat minY = guideCenterY - sliderHeight * 0.5;
    CGFloat maxY = guideCenterY + sliderHeight * 0.5;
    
    CGFloat positionY = VTMapValueFromRangeToNewRange(self.zoomAdjustSlider.value, 2.0, -2.0, minY, maxY);
    
    [UIView animateWithDuration:0.1 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveLinear) animations:^{
        self.zoomLevelLabel.center = CGPointMake(CGRectGetMaxX(guideFrame) - CGRectGetWidth(self.zoomLevelLabel.bounds), positionY);
    } completion:nil];
}

@end
