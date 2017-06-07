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

#import "VTMath.h"
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
@property (nonatomic, strong) UIToolbar *bottomToolbar;

@property (nonatomic, assign) float secondsComplete;
@property (nonatomic, assign) float secondsTotal;

@property (nonatomic, strong) UISlider *zoomAdjustSlider;

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
        VTAllowAutolayoutForView(_clippingView);
        _clippingView.clipsToBounds = YES;
        [self addSubview:_clippingView];

        _playerView = [[_VTPlayerView alloc] init];
        VTAllowAutolayoutForView(_playerView);
        _playerView.player = _player;
        [_clippingView addSubview:_playerView];

        _zoomAdjustSlider = [[UISlider alloc] init];
        _zoomAdjustSlider.tintColor = [UIColor whiteColor];
        VTAllowAutolayoutForView(_zoomAdjustSlider);
        _zoomAdjustSlider.minimumValue = -2.0;
        _zoomAdjustSlider.maximumValue = 2.0;
        [self addSubview:_zoomAdjustSlider];
        
        VTWeakifySelf(weakSelf);
        [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0/60.0, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            VTStrongifySelf(strongSelf, weakSelf);
            if (strongSelf)
            {
                strongSelf.secondsTotal = 1.0 * strongSelf.playerItem.duration.value / strongSelf.playerItem.duration.timescale;
                strongSelf.secondsComplete = 1.0 * time.value / time.timescale;
            }
        }];

        { // Bottom Controls
            _bottomToolbar = [[UIToolbar alloc] init];
            VTAllowAutolayoutForView(_bottomToolbar);
            _bottomToolbar.tintColor = [UIColor whiteColor];
            _bottomToolbar.barStyle = UIBarStyleBlack;
            [self addSubview:_bottomToolbar];
            
            UIBarButtonItem *spacer1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *spacer2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *leftSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *rightSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            fixedSpace.width = 30.0;
            
            UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(_handleShareButtonPress)];
            UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(_handleDiscardButtonPress)];
            _bottomToolbar.items = @[leftSpacer, trashButton, spacer1, shareButton, spacer2, fixedSpace, rightSpacer];
            
            [_bottomToolbar.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            [_bottomToolbar.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            [_bottomToolbar.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
            [_bottomToolbar.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
        }
        
        {
            [_zoomAdjustSlider.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            [_zoomAdjustSlider.topAnchor constraintEqualToAnchor:self.topAnchor constant:30.0].active = YES;
            [_zoomAdjustSlider.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.8].active = YES;
        }
        
        {
            [_clippingView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            [_clippingView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
            [_clippingView.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.8].active = YES;
            [_clippingView.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.8].active = YES;
            
            [_playerView.centerXAnchor constraintEqualToAnchor:_clippingView.centerXAnchor].active = YES;
            [_playerView.centerYAnchor constraintEqualToAnchor:_clippingView.centerYAnchor].active = YES;
            [_playerView.widthAnchor constraintEqualToAnchor:_clippingView.widthAnchor].active = YES;
            [_playerView.heightAnchor constraintEqualToAnchor:_clippingView.heightAnchor].active = YES;
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_itemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self _updatePlayback];
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
    CGFloat targetScale = VTRoundToNearestFactor(self.zoomAdjustSlider.value, 0.01);
    BOOL isPull = targetScale >= 0.0;
    targetScale = ABS(targetScale) + 1.0;
    
    VTMutableZoomEffectSettings *settings = [[VTMutableZoomEffectSettings alloc] init];
    if (isPull)
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

# pragma mark - Notifications

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

@end
