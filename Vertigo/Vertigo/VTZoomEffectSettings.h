//
//  VTZoomEffectSettings.h
//  Vertigo
//
//  Created by Evan Long on 4/3/17.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VTZoomEffectSettings : NSObject <NSCopying, NSMutableCopying>

- (instancetype)initWithZoomEffectSettings:(VTZoomEffectSettings *)settings;

@property (nonatomic, readonly, assign) CGFloat initalZoomLevel; // defaults to 1.0
@property (nonatomic, readonly, assign) CGFloat finalZoomLevel; // defaults to 2.0
@property (nonatomic, readonly, assign) NSTimeInterval duration; // defaults to 1.0

@end


@interface VTMutableZoomEffectSettings : VTZoomEffectSettings

@property (nonatomic, readwrite, assign) CGFloat initalZoomLevel;
@property (nonatomic, readwrite, assign) CGFloat finalZoomLevel;
@property (nonatomic, readwrite, assign) NSTimeInterval duration;

@end

NS_ASSUME_NONNULL_END
