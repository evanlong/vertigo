//
//  VTCameraController.m
//  Vertigo
//
//  Created by Evan Long on 3/24/17.
//
//

#import "VTCameraController.h"

#import "HFKVOBlocks.h"

#import "VTMath.h"
#import "VTZoomEffectSettings.h"

@interface VTCameraController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, assign, getter=isConfigured) BOOL configured;

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, readwrite, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (nonatomic, readonly, assign) CGFloat maximumZoomLevel;

// Value captured via public API, so it may be out of change of the current videoCaptureDevice. videoCaptureDevice zoom
// level updated to range of [1.0, maximumZoomLevel] when this value changes or when the videoCaptureDevice changes
@property (nonatomic, assign) CGFloat previewZoomLevel;
@property (nonatomic, strong) id rampingVideoZoomToken;
@property (nonatomic, assign, getter=isDeviceRampingVideoZoom) BOOL deviceRampingVideoZoom;
@property (nonatomic, assign) NSTimeInterval zoomDuration;
@property (nonatomic, copy) VTZoomEffectSettings *zoomEffectSettings;

@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@end

@implementation VTCameraController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        dispatch_queue_attr_t sessionQueueAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL, QOS_CLASS_USER_INITIATED, 0);
        _sessionQueue = dispatch_queue_create("vertigo.sessionQueue", sessionQueueAttr);
        _captureSession = [[AVCaptureSession alloc] init];
        _previewZoomLevel = 1.0;
    }
    return self;
}

- (void)dealloc
{
    [_videoCaptureDevice hf_removeBlockObserverWithToken:_rampingVideoZoomToken];
}

#pragma mark - VTCameraController Public

- (void)updatePreviewZoomLevel:(CGFloat)previewZoomLevel
{
    dispatch_async(self.sessionQueue, ^{
        self.previewZoomLevel = previewZoomLevel;
    });
}

- (void)startRunning
{
    dispatch_async(self.sessionQueue, ^{
        [self _queue_startRunning];
    });
}

- (void)stopRunning
{
    dispatch_async(self.sessionQueue, ^{
        [self _queue_stopRunning];
    });
}

- (void)startRecordingWithOrientation:(AVCaptureVideoOrientation)orientation withZoomEffectSettings:(VTZoomEffectSettings *)zoomEffectSettings
{
    // If a mutable varient is passed in, the calling thread may change it before sessionQueue gets a chance to use it. Copying now eliminates that problem
    VTZoomEffectSettings *copiedSettings = [zoomEffectSettings copy];
    dispatch_async(self.sessionQueue, ^{
        [self _queue_startRecordingWithOrientation:orientation withZoomEffectSettings:copiedSettings];
    });
}

- (void)stopRecording
{
    dispatch_async(self.sessionQueue, ^{
        [self _queue_stopRecording];
    });
}

#pragma mark - Private (Unknown Queue)

- (void)_rampingVideoZoomDidChange
{
    dispatch_async(self.sessionQueue, ^{
        self.deviceRampingVideoZoom = self.videoCaptureDevice.isRampingVideoZoom;
    });
}

- (void)_resetWithPreviewVideoZoomLevel
{
    dispatch_async(self.sessionQueue, ^{
        [self _queue_resetWithPreviewVideoZoomLevel];
    });
}

#pragma mark - Private (Session Queue)

- (void)setVideoCaptureDevice:(AVCaptureDevice *)videoCaptureDevice
{
    if (_videoCaptureDevice != videoCaptureDevice)
    {
        // Remove observer from the previous videoCaptureDevice
        [_videoCaptureDevice hf_removeBlockObserverWithToken:self.rampingVideoZoomToken];

        _videoCaptureDevice = videoCaptureDevice;
        
        __weak typeof(self) weakSelf = self;
        self.rampingVideoZoomToken = [videoCaptureDevice hf_addBlockObserver:^(AVCaptureDevice *_Nonnull object, NSDictionary *_Nonnull change) {
            [weakSelf _rampingVideoZoomDidChange];
        } forKeyPath:VTKeyPath(self.videoCaptureDevice, rampingVideoZoom)];

        self.deviceRampingVideoZoom = self.videoCaptureDevice.isRampingVideoZoom;
        [self _queue_resetWithPreviewVideoZoomLevel];
    }
}

- (void)setPreviewZoomLevel:(CGFloat)previewZoomLevel
{
    if (_previewZoomLevel != previewZoomLevel)
    {
        _previewZoomLevel = previewZoomLevel;
        [self _queue_resetWithPreviewVideoZoomLevel];
    }
}

- (void)setDeviceRampingVideoZoom:(BOOL)deviceRampingVideoZoom
{
    if (_deviceRampingVideoZoom != deviceRampingVideoZoom)
    {
        _deviceRampingVideoZoom = deviceRampingVideoZoom;
        
        if (!deviceRampingVideoZoom)
        {
            // EL TODO: This will be more complex in the future (eg: are we previewing or recording)
            // For now, we assume if the zoom stopped, we want to stop recording
            
            // A call to _queue_stopRecording might result in zoom factor stopping by virtue of resetting zoom factor
            [self _queue_stopRecording];
        }
    }
}

- (CGFloat)maximumZoomLevel
{
    return self.videoCaptureDevice.activeFormat.videoMaxZoomFactor;
}

- (void)_queue_resetWithPreviewVideoZoomLevel
{
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        CGFloat previewZoomLevel = VTClamp(self.previewZoomLevel, 1.0, self.maximumZoomLevel);
        self.videoCaptureDevice.videoZoomFactor = previewZoomLevel;
        [self.videoCaptureDevice unlockForConfiguration];
    }
}

- (void)_queue_startRunning
{
    [self _queue_configureIfNeeded];
    
    if (self.isConfigured)
    {
        [self.captureSession startRunning];

        if (self.captureSession.isRunning)
        {
            id<VTCameraControllerDelegate> delegate = self.delegate;
            if ([delegate respondsToSelector:@selector(cameraControllerDidStartRunning:)])
            {
                [delegate cameraControllerDidStartRunning:self];
            }
        }
        else
        {
            // EL TODO: Failed to start running
        }
    }
}

- (void)_queue_stopRunning
{
    [self.captureSession stopRunning];

    id<VTCameraControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(cameraControllerDidStopRunning:)])
    {
        [delegate cameraControllerDidStopRunning:self];
    }
}

- (void)_queue_configureIfNeeded
{
    if (self.isConfigured)
    {
        return;
    }
    
    BOOL successfullyConfigured = YES;

    [self.captureSession beginConfiguration];
    
    // Logic from AVCam sample for picking the device
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDuoCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    if (!videoCaptureDevice)
    {
        videoCaptureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        
        // Fallback to front facing camera if back is not available for some reason. AVCam notes this is in cases where users drop the phone
        if (!videoCaptureDevice)
        {
            videoCaptureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        }
    }
    
    // Configure Capture Input
    if (videoCaptureDevice)
    {
        NSError *error = nil;
        AVCaptureDeviceInput *videoCaptureInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
        if (videoCaptureInput && [self.captureSession canAddInput:videoCaptureInput])
        {
            [self.captureSession addInput:videoCaptureInput];
        }
        else
        {
            // EL TODO: Failure Reasons? for lack of videoCaptureInput? facetime?
            // EL TODO: error message and button to retry?
            successfullyConfigured = NO;
        }
    }
    else
    {
        // EL TODO: Failure Reasons? for lack of videoCaptureDevice? facetime?
        // EL TODO: error message and button to retry?
        successfullyConfigured = NO;
    }

    // Configure Capture Output if everything OK up to this point
    AVCaptureMovieFileOutput *movieFileOutput = nil;
    if (successfullyConfigured)
    {
        movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([self.captureSession canAddOutput:movieFileOutput])
        {
            [self.captureSession addOutput:movieFileOutput];
            
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if (connection.isVideoStabilizationSupported)
            {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
        }
        else
        {
            successfullyConfigured = NO;
        }
    }

    self.configured = successfullyConfigured;
    if (successfullyConfigured)
    {
        self.videoCaptureDevice = videoCaptureDevice;
        self.movieFileOutput = movieFileOutput;
    }
    else
    {
        // Cleanup captureSession since all the pieces were not configured
        for (AVCaptureInput *input in self.captureSession.inputs)
        {
            [self.captureSession removeInput:input];
        }
        
        for (AVCaptureOutput *output in self.captureSession.outputs)
        {
            [self.captureSession removeOutput:output];
        }
    }
    
    [self.captureSession commitConfiguration];
}

- (void)_queue_startRecordingWithOrientation:(AVCaptureVideoOrientation)orientation withZoomEffectSettings:(VTZoomEffectSettings *)zoomEffectSettings
{
    if (!self.captureSession.isRunning)
    {
        return;
    }

    if (!self.movieFileOutput.isRecording)
    {
        // EL TODO: Prepare for possible app backgrounding. Check AVCam sample

        AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        movieFileOutputConnection.videoOrientation = orientation;
        
        // Start recording to a temporary file.
        NSString *outputFileName = [NSUUID UUID].UUIDString;
        NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
        [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
        
        // Capture Recording Preferences for this Recording Session
        self.zoomEffectSettings = zoomEffectSettings;
        
        // Reset to initial zoom position
        if ([self.videoCaptureDevice lockForConfiguration:nil])
        {
            self.videoCaptureDevice.videoZoomFactor = self.zoomEffectSettings.initalZoomLevel;
            [self.videoCaptureDevice unlockForConfiguration];
        }
    }
}

- (void)_queue_stopRecording
{
    if (!self.captureSession.isRunning)
    {
        return;
    }

    if (self.movieFileOutput.isRecording)
    {
        [self.movieFileOutput stopRecording];
    }
}

- (void)_queue_startZoom
{
    CGFloat safeFinalZoomLevel = VTClamp(self.zoomEffectSettings.finalZoomLevel, 1.0, self.maximumZoomLevel);
    CGFloat min = MIN(self.zoomEffectSettings.initalZoomLevel, safeFinalZoomLevel);
    CGFloat max = MAX(self.zoomEffectSettings.initalZoomLevel, safeFinalZoomLevel);
    float rate = log2(max/min) / self.zoomEffectSettings.duration;

    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        [self.videoCaptureDevice rampToVideoZoomFactor:safeFinalZoomLevel withRate:rate];
        [self.videoCaptureDevice unlockForConfiguration];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    dispatch_async(self.sessionQueue, ^{
        // EL NOTE: It looks like the zoom starts pretty quickly with respect didStartRecording. If we inline the calls to
        // [self.movieFileOutput startRecordingToOutputFileURL...] and [self.videoCaptureDevice rampToVideoZoomFactor...],
        // I noticed the zoom would sometimes start much sonoer than the actual recording. I don't know of a better way to
        // synchronize the "record" and "zoom" other than simply starting the zoom once the didStartRecording call occurs
        [self _queue_startZoom];
    });

    id<VTCameraControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(cameraController:didStartRecordingToOutputFileAtURL:)])
    {
        [delegate cameraController:self didStartRecordingToOutputFileAtURL:fileURL];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    [self _resetWithPreviewVideoZoomLevel];

    id<VTCameraControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(cameraController:didFinishRecordingToOutputFileAtURL:)])
    {
        [delegate cameraController:self didFinishRecordingToOutputFileAtURL:outputFileURL];
    }
}

@end
