//
//  VTSaveVideoView.h
//  Vertigo
//
//  Created by Evan Long on 4/19/17.
//
//

#import "VTZoomEffectSettings.h"

NS_ASSUME_NONNULL_BEGIN

@protocol VTSaveVideoViewDelegate;

@interface VTSaveVideoView : UIView

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithVideoURL:(NSURL *)videoURL NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) NSURL *videoURL;
@property (nonatomic, weak) id<VTSaveVideoViewDelegate> delegate;

@property (nonatomic, copy, readonly) VTZoomEffectSettings *settings;

@property (nonatomic, assign) BOOL hideControls;
- (void)setHideControls:(BOOL)hideControls animated:(BOOL)animated;

@end

@protocol VTSaveVideoViewDelegate <NSObject>

@optional
- (void)saveVideoViewDidPressShare:(VTSaveVideoView *)saveVideoView;
- (void)saveVideoViewDidPressSave:(VTSaveVideoView *)saveVideoView;
- (void)saveVideoViewDidPressDiscard:(VTSaveVideoView *)saveVideoView;

@end

NS_ASSUME_NONNULL_END
