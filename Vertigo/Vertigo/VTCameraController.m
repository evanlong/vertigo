//
//  VTCameraController.m
//  Vertigo
//
//  Created by Evan Long on 3/24/17.
//
//

#import "VTCameraController.h"

@interface VTCameraController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, assign, getter=isConfigured) BOOL configured;

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, readwrite, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@end

@implementation VTCameraController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _sessionQueue = dispatch_queue_create("vertigo.sessionQueue", DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
        _captureSession = [[AVCaptureSession alloc] init];
        
        // How much of initial AVCaptureSession can be done here...
        // If some of the camera config (devices, capture output) fails, then what?
        
        // Simply signal a "ready" state once configuration is complete? Lazily setup when startRunning called?
    }
    return self;
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

- (void)startRecordingWithOrientation:(AVCaptureVideoOrientation)orientation
{
    dispatch_async(self.sessionQueue, ^{
        [self _queue_startRecordingWithOrientation:orientation];
    });
}

- (void)stopRecording
{
    dispatch_async(self.sessionQueue, ^{
        [self _queue_stopRecording];
    });
}

#pragma mark - Session Queue

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

- (void)_queue_startRecordingWithOrientation:(AVCaptureVideoOrientation)orientation
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

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
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


//- (void)_session_queue_toggleRecording
//{
//    if (self.movieFileOutput.isRecording)
//    {
//        [self.movieFileOutput stopRecording];
//    }
//    else
//    {
//        [self _session_queue_startRecording];
//    }
//}

//- (void)_session_queue_startRecording
//{
//    /*
//     1. Prepare camera for initial state
//     2. Start recording and the camera effect
//     3. Trigger end when camera effect is done
//     */
//
//    CGFloat initialZoomLevel;
//    CGFloat finalZoomLevel;
//    if (self.mainControlHostView.direction == VTRecordDirectionPush)
//    {
//        initialZoomLevel = self.mainControlHostView.pulledZoomLevel;
//        finalZoomLevel = self.mainControlHostView.pushedZoomLevel;
//    }
//    else
//    {
//        initialZoomLevel = self.mainControlHostView.pushedZoomLevel;
//        finalZoomLevel = self.mainControlHostView.pulledZoomLevel;
//    }
//
//    CGFloat duration = (CGFloat)self.mainControlHostView.duration;
//
//    dispatch_async(self.sessionQueue, ^{
//        AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//        movieFileOutputConnection.videoOrientation = videoPreviewLayerVideoOrientation;
//
//        if ([self.videoCaptureDevice lockForConfiguration:nil])
//        {
//            self.videoCaptureDevice.videoZoomFactor = initialZoomLevel;
//            [self.videoCaptureDevice unlockForConfiguration];
//        }
//
//        // Start recording to a temporary file.
//        NSString *outputFileName = [NSUUID UUID].UUIDString;
//        NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
//        [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
//    });
//}

