//
//  VTPlayerView.m
//  Vertigo
//
//  Created by Evan Long on 7/8/17.
//
//

#import "VTPlayerView.h"

@implementation VTPlayerView

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
