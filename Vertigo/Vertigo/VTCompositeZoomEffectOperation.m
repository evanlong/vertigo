//
//  VTCompositeZoomEffectOperation.m
//  Vertigo
//
//  Created by Evan Long on 6/23/17.
//
//

#import "VTCompositeZoomEffectOperation.h"

#import "VTMath.h"

@interface VTCompositeZoomEffectOperation ()

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, copy) VTZoomEffectSettings *zoomEffectSettings;
@property (nonatomic, strong) dispatch_queue_t progressQueue;

@property (nonatomic, assign) float progress;
@property (nonatomic, strong, nullable) NSURL *composedVideoURL;

@end

@implementation VTCompositeZoomEffectOperation

- (instancetype)initWithAsset:(AVAsset *)asset zoomEffectSettings:(VTZoomEffectSettings *)zoomEffectSettings
{
    self = [super init];
    if (self)
    {
        _asset = asset;
        _zoomEffectSettings = [zoomEffectSettings copy];
        _progressQueue = dispatch_queue_create("vertigo.compositeProgressQueue", 0);
    }
    return self;
}

- (void)main
{
    AVAsset *asset = self.asset;
    VTZoomEffectSettings *zoomEffectSettings = self.zoomEffectSettings;

    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithAsset:asset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        NSError *err = nil;
        CIImage *filtered = request.sourceImage;
        
        NSTimeInterval duration = 1.0 * asset.duration.value / asset.duration.timescale;
        NSTimeInterval currentTime = 1.0 * request.compositionTime.value / request.compositionTime.timescale;
        
        CGFloat pushPowerScale = VTVertigoEffectZoomPowerScale(zoomEffectSettings.initalZoomLevel, zoomEffectSettings.finalZoomLevel, currentTime, duration);
        
        // Map scale rate change to tx/ty change
        CGSize size = filtered.extent.size;
        CGFloat tx = ABS(size.width - (pushPowerScale * size.width)) / -2.0;
        CGFloat ty = ABS(size.height - (pushPowerScale * size.height)) / -2.0;
        CGAffineTransform t = CGAffineTransformIdentity;
        
        t = CGAffineTransformTranslate(t, tx, ty);
        t = CGAffineTransformScale(t, pushPowerScale, pushPowerScale);
        filtered = [filtered imageByApplyingTransform:t];
        
        if (filtered)
        {
            [request finishWithImage:filtered context:nil];
        }
        else
        {
            [request finishWithError:err];
        }
    }];
    
    NSString *composedVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"composed.mov"];
    NSURL *composedVideoURL = [NSURL fileURLWithPath:composedVideoPath];
    [[NSFileManager defaultManager] removeItemAtPath:composedVideoPath error:nil];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    exportSession.videoComposition = videoComposition;
    exportSession.outputURL = composedVideoURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    dispatch_semaphore_t s = dispatch_semaphore_create(0);
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_semaphore_signal(s);
    }];
    
    VTWeakifySelf(weakSelf);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.progressQueue);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0/60.0 * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        weakSelf.progress = exportSession.progress;
    });
    dispatch_resume(timer);
    
    dispatch_semaphore_wait(s, DISPATCH_TIME_FOREVER);
    
    dispatch_source_cancel(timer);
    
    self.progress = 1.0;
    self.composedVideoURL = composedVideoURL;
}

@end
