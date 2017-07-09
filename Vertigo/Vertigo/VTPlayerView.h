//
//  VTPlayerView.h
//  Vertigo
//
//  Created by Evan Long on 7/8/17.
//
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface VTPlayerView : UIView

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;

@end
