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

#import "VTCaptureTypes.h"
#import "VTOverlayButton.h"
#import "VTMath.h"
#import "VTPushPullAnimationView.h"
#import "VTTargetAnimationView.h"
#import "VTZoomEffect.h"

#define CONTROL_BACKDROP_COLOR          [UIColor colorWithWhite:0.1 alpha:0.70]

@interface _VTPlayerView : UIView
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;
@end

@implementation _VTPlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (AVPlayer *)player
{
    return self.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player
{
    self.playerLayer.player = player;
}

@end

@interface VTSaveVideoView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) UIView *clippingView;

@property (nonatomic, strong) _VTPlayerView *playerView;

@property (nonatomic, assign) float secondsComplete;
@property (nonatomic, assign) float secondsTotal;

@property (nonatomic, strong) NSLayoutConstraint *clippingWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *clippingHeightConstraint;

@property (nonatomic, strong) UIView *controlHostView;
@property (nonatomic, strong) VTOverlayButton *backArrowButton;
@property (nonatomic, strong) VTOverlayButton *shareButton;
@property (nonatomic, strong) UISlider *zoomAdjustSlider;
@property (nonatomic, strong) UILayoutGuide *sliderSpaceGuide;
@property (nonatomic, strong) UIView *sliderMidpointView;
@property (nonatomic, strong) UILabel *zoomLevelLabel;

@property (nonatomic, strong) VTTargetAnimationView *targetAnimationView;
@property (nonatomic, strong) VTPushPullAnimationView *pushAnimationView;
@property (nonatomic, strong) VTPushPullAnimationView *pullAnimationView;
@property (nonatomic, assign, getter=isPushPullAnimationRunning) BOOL pushPullAnimationRunning;

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

        _playerView = [[_VTPlayerView alloc] init];
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
        [_controlHostView addSubview:_zoomAdjustSlider];
        
        _zoomLevelLabel = [[UILabel alloc] init];
        _zoomLevelLabel.textAlignment = NSTextAlignmentRight;
        _zoomLevelLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _zoomLevelLabel.layer.shadowRadius = 2.0;
        _zoomLevelLabel.layer.shadowOpacity = 1.0;
        _zoomLevelLabel.layer.shadowOffset = CGSizeZero;
        _zoomLevelLabel.textAlignment = NSTextAlignmentCenter;
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

        _backArrowButton = [[VTOverlayButton alloc] initWithOverlayImageName:@"BackIcon"];
        VTAllowAutolayoutForView(_backArrowButton);
        [_backArrowButton addTarget:self action:@selector(_handleDiscardButtonPress) forControlEvents:UIControlEventTouchUpInside];
        [_controlHostView addSubview:_backArrowButton];
        
        _shareButton = [[VTOverlayButton alloc] initWithOverlayImageName:@"Sharrow"];
        VTAllowAutolayoutForView(_shareButton);
        [_shareButton addTarget:self action:@selector(_handleShareButtonPress) forControlEvents:UIControlEventTouchUpInside];
        [_controlHostView addSubview:_shareButton];
        
        VTWeakifySelf(weakSelf);
        [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0/60.0, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
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
            [_shareButton.centerXAnchor constraintEqualToAnchor:_controlHostView.centerXAnchor].active = YES;
            [_shareButton.bottomAnchor constraintEqualToAnchor:_controlHostView.bottomAnchor constant:-20.0].active = YES;
        }
        
        { // Back Arrow
            [_backArrowButton.leftAnchor constraintEqualToAnchor:_controlHostView.leftAnchor constant:24.0].active = YES;
            [_backArrowButton.topAnchor constraintEqualToAnchor:_controlHostView.topAnchor constant:24.0].active = YES;
        }
        
        {
            UILayoutGuide *sliderGuideTopInset = [[UILayoutGuide alloc] init];
            [_controlHostView addLayoutGuide:sliderGuideTopInset];
            [sliderGuideTopInset.topAnchor constraintEqualToAnchor:_controlHostView.topAnchor].active = YES;
            [sliderGuideTopInset.bottomAnchor constraintEqualToAnchor:_backArrowButton.bottomAnchor].active = YES;
            
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
            [_targetAnimationView.bottomAnchor constraintEqualToAnchor:_pushAnimationView.topAnchor].active = YES;
            
            [_pushAnimationView.centerYAnchor constraintEqualToAnchor:_controlHostView.centerYAnchor].active = YES;
            [_pushAnimationView.leftAnchor constraintEqualToAnchor:_controlHostView.leftAnchor constant:10.0].active = YES;

            [_pullAnimationView.centerYAnchor constraintEqualToAnchor:_controlHostView.centerYAnchor].active = YES;
            [_pullAnimationView.leftAnchor constraintEqualToAnchor:_controlHostView.leftAnchor constant:10.0].active = YES;
        }
        
        {
            [_playerView.centerXAnchor constraintEqualToAnchor:_clippingView.centerXAnchor].active = YES;
            [_playerView.centerYAnchor constraintEqualToAnchor:_clippingView.centerYAnchor].active = YES;
            [_playerView.widthAnchor constraintEqualToAnchor:_clippingView.widthAnchor].active = YES;
            [_playerView.heightAnchor constraintEqualToAnchor:_clippingView.heightAnchor].active = YES;
        }
        
        [UIView performWithoutAnimation:^{
            [self _updatePushPullAnimationRunning];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];

    [UIView performWithoutAnimation:^{
        [self _updateZoomLevelLabelPosition];
    }];

    CGRect clippingViewFrame = self.bounds;
    CGSize presentationSize = self.playerItem.presentationSize;
    if (!CGSizeEqualToSize(presentationSize, CGSizeZero))
    {
        clippingViewFrame = AVMakeRectWithAspectRatioInsideRect(presentationSize, self.bounds);
    }
    self.clippingView.frame = clippingViewFrame;
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

- (void)_handleZoomSliderValueChanged
{
    [self _updatePushPullAnimationRunning];
    [self _updatePushPullAnimationVisibility];
    [self _updateZoomLevelLabelText];
    [self _updateZoomLevelLabelPosition];
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

    if (self.superview && [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
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

- (void)setPushPullAnimationRunning:(BOOL)pushPullAnimationRunning
{
    if (_pushPullAnimationRunning != pushPullAnimationRunning)
    {
        _pushPullAnimationRunning = pushPullAnimationRunning;
        
        if (!pushPullAnimationRunning)
        {
            [self.pushAnimationView removeAllAnimations];
            [self.pullAnimationView removeAllAnimations];
        }
        else
        {
            // Player will restart animation if allowed when starting from the beginning
        }
    }
}

- (void)_updatePushPullAnimation
{
    [self.pushAnimationView removeAllAnimations];
    [self.pullAnimationView removeAllAnimations];
 
    if (self.isPushPullAnimationRunning)
    {
        [self.pushAnimationView addPullAnimationReverse:YES totalDuration:MAX(1.0, self.secondsTotal) completionBlock:NULL];
        [self.pullAnimationView addPullAnimationReverse:NO totalDuration:MAX(1.0, self.secondsTotal) completionBlock:NULL];
    }
}

- (void)_updatePushPullAnimationRunning
{
    // Run the animation when magnitude isn't 1.0
    self.pushPullAnimationRunning = !VTFloatIsEqual([self _directionMagnitide].magnitude, 1.0);
}

- (void)_updatePushPullAnimationVisibility
{
    VTDirectionMagnitude dm = [self _directionMagnitide];
    if (dm.direction == VTVertigoDirectionPush)
    {
        self.pushAnimationView.hidden = NO;
        self.pullAnimationView.hidden = YES;
    }
    else
    {
        self.pushAnimationView.hidden = YES;
        self.pullAnimationView.hidden = NO;
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
    } completion:NULL];
}

@end
