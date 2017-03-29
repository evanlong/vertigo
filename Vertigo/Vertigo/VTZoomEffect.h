//
//  VTZoomEffect.h
//  Vertigo
//
//  Created by Evan Long on 3/27/17.
//
//

@protocol VTZoomEffectDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 VTZoomEffect takes as input initial and final zoom levels, a duration and emits as output changes to the zoomLevel over for
 the length of the duration. While running, the zoomLevel will take on the values in the range: [initalZoomLevel, finalZoomLevel].
 
 EL NOTE: Probably would be better to split up the "effect model" and "running" parts, but for, now a single object will do.
 A refactor might look like:
    VTZoomEffect
    VTZoomEffectRunner
 */
@interface VTZoomEffect : NSObject

@property (nonatomic, nullable, weak) id<VTZoomEffectDelegate> delegate;

//! Determines which queue the zoom effect will run on. Defaults to the main queue
@property (nonatomic, null_resettable, strong) dispatch_queue_t queue;

@property (nonatomic, assign) CGFloat initalZoomLevel; // defaults to 1.0
@property (nonatomic, assign) CGFloat finalZoomLevel; // defaults to 2.0
@property (nonatomic, assign) NSTimeInterval duration; // defaults to 1.0

@property (nonatomic, readonly, assign, getter=isRunning) BOOL running;
@property (nonatomic, readonly, assign) CGFloat zoomLevel;

- (void)start;
- (void)stop;

@end

@protocol VTZoomEffectDelegate <NSObject>

@optional
- (void)zoomEffectDidStart:(VTZoomEffect *)zoomEffect;
- (void)zoomEffectDidComplete:(VTZoomEffect *)zoomEffect;
- (void)zoomEffectZoomLevelDidChange:(VTZoomEffect *)zoomEffect;

@end

NS_ASSUME_NONNULL_END
