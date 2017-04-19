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

@property (nonatomic, strong) _VTPlayerView *playerView;
@property (nonatomic, strong) UIView *bottomViewHost;
@property (nonatomic, strong) UIButton *discardButton;
@property (nonatomic, strong) UIButton *shareButton;

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
        
        _playerView = [[_VTPlayerView alloc] init];
        _playerView.player = _player;
        [self addSubview:_playerView];
        
        { // Bottom Controls
            _bottomViewHost = [[UIView alloc] init];
            VTAllowAutolayoutForView(_bottomViewHost);
            _bottomViewHost.backgroundColor = CONTROL_BACKDROP_COLOR;
            [self addSubview:_bottomViewHost];
            
            [_bottomViewHost.heightAnchor constraintEqualToConstant:70.0].active = YES;
            [_bottomViewHost.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
            [_bottomViewHost.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            [_bottomViewHost.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            
            // Share
            _shareButton = [[UIButton alloc] init];
            VTAllowAutolayoutForView(_shareButton);
            _shareButton.backgroundColor = [UIColor blueColor];
            [_bottomViewHost addSubview:_shareButton];
            
            [_shareButton addTarget:self action:@selector(_handleShareButtonPress) forControlEvents:UIControlEventTouchUpInside];
            
            [_shareButton.centerXAnchor constraintEqualToAnchor:_bottomViewHost.centerXAnchor].active = YES;
            [_shareButton.centerYAnchor constraintEqualToAnchor:_bottomViewHost.centerYAnchor].active = YES;
            [_shareButton.widthAnchor constraintEqualToConstant:50.0].active = YES;
            [_shareButton.heightAnchor constraintEqualToConstant:50.0].active = YES;
            
            // Duration Label
            _discardButton = [[UIButton alloc] init];
            VTAllowAutolayoutForView(_discardButton);
            _discardButton.backgroundColor = [UIColor redColor];
            [_bottomViewHost addSubview:_discardButton];
            
            [_discardButton addTarget:self action:@selector(_handleDiscardButtonPress) forControlEvents:UIControlEventTouchUpInside];
            
            [_discardButton.rightAnchor constraintEqualToAnchor:_shareButton.leftAnchor constant:-30.0].active = YES;
            [_discardButton.centerYAnchor constraintEqualToAnchor:_shareButton.centerYAnchor].active = YES;
            [_discardButton.widthAnchor constraintEqualToConstant:40.0].active = YES;
            [_discardButton.heightAnchor constraintEqualToConstant:40.0].active = YES;
        }
        
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

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self _updatePlayback];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerView.frame = self.bounds;
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

@end
