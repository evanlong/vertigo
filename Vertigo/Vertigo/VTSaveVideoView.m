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
@property (nonatomic, strong) UIToolbar *bottomToolbar;

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
