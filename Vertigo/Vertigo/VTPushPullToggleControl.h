//
//  VTPushPullToggleControl.h
//  Vertigo
//
//  Created by Evan Long on 4/10/17.
//
//

#import "VTCaptureTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface VTPushPullToggleControl : UIControl

@property (nonatomic, assign) VTVertigoDirection direction;
- (void)setDirection:(VTVertigoDirection)direction animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
