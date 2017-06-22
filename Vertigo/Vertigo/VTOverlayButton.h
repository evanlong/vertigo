//
//  VTArrowButton.h
//  Vertigo
//
//  Created by Evan Long on 6/21/17.
//
//

NS_ASSUME_NONNULL_BEGIN

@interface VTOverlayButton : UIControl

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithOverlayImageName:(NSString *)imageName NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign) BOOL useBlurBackground; // Defaults to YES

@end

NS_ASSUME_NONNULL_END
