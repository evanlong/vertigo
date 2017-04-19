//
//  VTSaveVideoView.h
//  Vertigo
//
//  Created by Evan Long on 4/19/17.
//
//

NS_ASSUME_NONNULL_BEGIN

@protocol VTSaveVideoViewDelegate;

@interface VTSaveVideoView : UIView

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithVideoURL:(NSURL *)videoURL NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) NSURL *videoURL;
@property (nonatomic, weak) id<VTSaveVideoViewDelegate> delegate;

@end

@protocol VTSaveVideoViewDelegate <NSObject>

@optional
- (void)saveVideoViewDidPressShare:(VTSaveVideoView *)saveVideoView;
- (void)saveVideoViewDidPressDiscard:(VTSaveVideoView *)saveVideoView;

@end

NS_ASSUME_NONNULL_END
