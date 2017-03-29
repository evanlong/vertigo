//
//  VTZoomEffect.m
//  Vertigo
//
//  Created by Evan Long on 3/27/17.
//
//

#import "VTZoomEffect.h"

#import "VTMath.h"

static const NSInteger FRAMES_PER_SECOND = 120;

@interface VTZoomEffect ()

@property (nonatomic, assign) CGFloat zoomLevelPerTick;
@property (nonatomic, assign) CGFloat minZoom;
@property (nonatomic, assign) CGFloat maxZoom;
@property (nonatomic, assign) CGFloat expectedFinalZoomLevel;
@property (nonatomic, readwrite, assign) CGFloat zoomLevel;
@property (nonatomic, assign, getter=isFirstTick) BOOL firstTick;

@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation VTZoomEffect

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _initalZoomLevel = 1.0;
        _finalZoomLevel = 2.0;
        _duration = 1.0;
        _queue = dispatch_get_main_queue();
    }
    return self;
}

#pragma mark - VTZoomEffect

- (void)setQueue:(dispatch_queue_t)queue
{
    if (queue == NULL)
    {
        queue = dispatch_get_main_queue();
    }

    if (_queue != queue)
    {
        _queue = queue;
    }
}

- (BOOL)isRunning
{
    return (self.timer != NULL);
}

- (void)start
{
    if (!self.isRunning)
    {
        CGFloat zoomLevelDelta = self.finalZoomLevel - self.initalZoomLevel;
        CGFloat numberOfTicks = self.duration * FRAMES_PER_SECOND;

        self.zoomLevelPerTick = (zoomLevelDelta / numberOfTicks);
        self.zoomLevel = self.initalZoomLevel;
        self.minZoom = MIN(self.initalZoomLevel, self.finalZoomLevel);
        self.maxZoom = MAX(self.initalZoomLevel, self.finalZoomLevel);
        self.expectedFinalZoomLevel = self.finalZoomLevel;
        self.firstTick = YES;
        
        __weak typeof(self) weakSelf = self;
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0/FRAMES_PER_SECOND * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            [weakSelf _tick];
        });
        dispatch_resume(timer);
        self.timer = timer;

        if ([self.delegate respondsToSelector:@selector(zoomEffectDidStart:)])
        {
            [self.delegate zoomEffectDidStart:self];
        }
    }
}

- (void)stop
{
    if (self.isRunning)
    {
        self.timer = nil;

        if ([self.delegate respondsToSelector:@selector(zoomEffectDidComplete:)])
        {
            [self.delegate zoomEffectDidComplete:self];
        }
    }
}

#pragma mark - Private

- (void)_tick
{
    // Note: This tick function makes sure we get to the intended zoom level. If the run loop or others things slow down
    // it is possible may take longer than the original duration to get there
    CGFloat zoomLevelPerTick = self.isFirstTick ? 0.0 : self.zoomLevelPerTick;
    self.zoomLevel = VTClamp(self.zoomLevel + zoomLevelPerTick, self.minZoom, self.maxZoom);
    self.firstTick = NO;
    
    if ([self.delegate respondsToSelector:@selector(zoomEffectZoomLevelDidChange:)])
    {
        [self.delegate zoomEffectZoomLevelDidChange:self];
    }
    
    if (VTFloatIsEqual(self.zoomLevel, self.expectedFinalZoomLevel))
    {
        [self stop];
    }
}

@end
