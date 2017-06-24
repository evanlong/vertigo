//
//  VTCompositeZoomEffectOperation.h
//  Vertigo
//
//  Created by Evan Long on 6/23/17.
//
//

#import <AVFoundation/AVFoundation.h>

#import "VTZoomEffectSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface VTCompositeZoomEffectOperation : NSOperation

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAsset:(AVAsset *)asset zoomEffectSettings:(VTZoomEffectSettings *)zoomEffectSettings NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign, readonly) float progress;
@property (nonatomic, strong, readonly, nullable) NSURL *composedVideoURL;

@end

NS_ASSUME_NONNULL_END
