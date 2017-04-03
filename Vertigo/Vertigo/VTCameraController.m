//
//  VTCameraController.m
//  Vertigo
//
//  Created by Evan Long on 3/24/17.
//
//

#import "VTCameraController.h"

#import "HFKVOBlocks.h"

#import "VTZoomEffect.h"

#define USE_VT_ZOOM_EFFECT 0

@interface VTCameraController () <AVCaptureFileOutputRecordingDelegate, VTZoomEffectDelegate>

@property (nonatomic, assign, getter=isConfigured) BOOL configured;

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, readwrite, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (nonatomic, strong) id rampingVideoZoomToken;
@property (nonatomic, assign, getter=isDeviceRampingVideoZoom) BOOL deviceRampingVideoZoom;
@property (nonatomic, assign) NSTimeInterval zoomDuration;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

#if USE_VT_ZOOM_EFFECT
@property (nonatomic, strong) VTZoomEffect *zoomEffect;
#endif

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
#if USE_VT_ZOOM_EFFECT
        _zoomEffect = [[VTZoomEffect alloc] init];
        _zoomEffect.queue = _sessionQueue;
        _zoomEffect.delegate = self;
#endif
    }
    return self;
}

- (void)dealloc
{
    [_videoCaptureDevice hf_removeBlockObserverWithToken:_rampingVideoZoomToken];
}

#pragma mark - VTCameraController Public

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

- (void)startRecordingWithOrientation:(AVCaptureVideoOrientation)orientation duration:(NSTimeInterval)duration
{
    dispatch_async(self.sessionQueue, ^{
        [self _queue_startRecordingWithOrientation:orientation duration:duration];
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

- (void)_resetVideoZoomFactor
{
    dispatch_async(self.sessionQueue, ^{
        [self _queue_resetVideoZoomFactor];
    });
}

#pragma mark - Private (Session Queue)

- (void)setVideoCaptureDevice:(AVCaptureDevice *)videoCaptureDevice
{
    if (_videoCaptureDevice != videoCaptureDevice)
    {
#if !USE_VT_ZOOM_EFFECT
        // Remove observer from the previous videoCaptureDevice
        [_videoCaptureDevice hf_removeBlockObserverWithToken:self.rampingVideoZoomToken];
#endif
        
        _videoCaptureDevice = videoCaptureDevice;
        
#if !USE_VT_ZOOM_EFFECT
        __weak typeof(self) weakSelf = self;
        self.rampingVideoZoomToken = [videoCaptureDevice hf_addBlockObserver:^(AVCaptureDevice *_Nonnull object, NSDictionary *_Nonnull change) {
            [weakSelf _rampingVideoZoomDidChange];
        } forKeyPath:VTKeyPath(self.videoCaptureDevice, rampingVideoZoom)];
#endif
        self.deviceRampingVideoZoom = self.videoCaptureDevice.isRampingVideoZoom;
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

- (void)_queue_resetVideoZoomFactor
{
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        self.videoCaptureDevice.videoZoomFactor = 1.0;
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

- (void)_queue_startRecordingWithOrientation:(AVCaptureVideoOrientation)orientation duration:(NSTimeInterval)duration
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
        self.zoomDuration = duration;
        
#if USE_VT_ZOOM_EFFECT
        self.zoomEffect.duration = duration;
        [self.zoomEffect start];
#endif
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
#if USE_VT_ZOOM_EFFECT
        [self.zoomEffect stop];
#endif
    }
}

- (void)_queue_startZoom
{
    CGFloat zoomFactor = MIN(2.0, self.videoCaptureDevice.activeFormat.videoMaxZoomFactor);
    float rate = log2(zoomFactor) / self.zoomDuration;
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        [self.videoCaptureDevice rampToVideoZoomFactor:zoomFactor withRate:rate];
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
    [self _resetVideoZoomFactor];

    id<VTCameraControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(cameraController:didFinishRecordingToOutputFileAtURL:)])
    {
        [delegate cameraController:self didFinishRecordingToOutputFileAtURL:outputFileURL];
    }
}

#pragma mark - VTZoomEffectDelegate

#if USE_VT_ZOOM_EFFECT
- (void)zoomEffectDidStart:(VTZoomEffect *)zoomEffect
{
}

- (void)zoomEffectDidComplete:(VTZoomEffect *)zoomEffect
{
    [self _queue_stopRecording];
}

- (void)zoomEffectZoomLevelDidChange:(VTZoomEffect *)zoomEffect
{
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        self.videoCaptureDevice.videoZoomFactor = zoomEffect.zoomLevel;
        [self.videoCaptureDevice unlockForConfiguration];
    }
}
#endif

@end
