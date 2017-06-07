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

@property (nonatomic, copy) VTZoomEffectSettings *zoomEffectSettings;

@property (nonatomic, assign) CFTimeInterval startRecordingTime;
@property (nonatomic, strong) dispatch_source_t recordingTimer;

@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@end

@implementation VTCameraController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Prior to iOS 10.0 the app will be at the wim of when iOS wants to drain autorelease from libdispatch queues, instead of the more agressive behavior in iOS 10
        dispatch_queue_attr_t sessionQueueAttr = VTOSAtLeast(10,0,0) ? DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL : DISPATCH_QUEUE_SERIAL;
        sessionQueueAttr = dispatch_queue_attr_make_with_qos_class(sessionQueueAttr, QOS_CLASS_USER_INITIATED, 0);
        _sessionQueue = dispatch_queue_create("vertigo.sessionQueue", sessionQueueAttr);
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if (_recordingTimer)
    {
        dispatch_source_cancel(_recordingTimer);
        _recordingTimer = nil;
    }
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

#pragma mark - Private (Session Queue)

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
    AVCaptureDevice *videoCaptureDevice = nil;
    if (VTOSAtLeast(10,0,0))
    {
        videoCaptureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];

        // Fallback to front facing camera if back is not available for some reason. AVCam notes this is in cases where users drops phone and breaks the camera
        if (!videoCaptureDevice)
        {
            videoCaptureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        }
    }
    else
    {
        videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
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
        NSString *outputFileName = @"vertigo";
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
    
    if (self.recordingTimer)
    {
        dispatch_source_cancel(self.recordingTimer);
        self.recordingTimer = nil;
    }

    if (self.movieFileOutput.isRecording)
    {
        [self.movieFileOutput stopRecording];
    }
}

- (void)_queue_startRecordingTimer
{
    self.startRecordingTime = CACurrentMediaTime();

    VTWeakifySelf(weakSelf);
    dispatch_source_t recordingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.sessionQueue);
    dispatch_source_set_timer(recordingTimer, DISPATCH_TIME_NOW, 1.0/30.0 * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(recordingTimer, ^{
        [weakSelf _queue_tick];
    });
    dispatch_resume(recordingTimer);
    self.recordingTimer = recordingTimer;
}

- (void)_queue_tick
{
    CFTimeInterval currentTime = CACurrentMediaTime();
    CGFloat percentComplete = (currentTime - self.startRecordingTime) / self.zoomEffectSettings.duration;
    percentComplete = VTClamp(percentComplete, 0.0, 1.0);
    
    id<VTCameraControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(cameraController:didUpdateProgress:)])
    {
        [delegate cameraController:self didUpdateProgress:percentComplete];
    }
    
    if (VTFloatIsEqual(percentComplete, 1.0))
    {
        [self _queue_stopRecording];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    dispatch_async(self.sessionQueue, ^{
        [self _queue_startRecordingTimer];
    });

    self.startRecordingTime = CACurrentMediaTime();

    id<VTCameraControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(cameraController:didStartRecordingToOutputFileAtURL:)])
    {
        [delegate cameraController:self didStartRecordingToOutputFileAtURL:fileURL];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    id<VTCameraControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(cameraController:didFinishRecordingToOutputFileAtURL:)])
    {
        [delegate cameraController:self didFinishRecordingToOutputFileAtURL:outputFileURL];
    }
}

@end
