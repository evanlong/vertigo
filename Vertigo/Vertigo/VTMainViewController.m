//
//  VTMainViewController.m
//  Vertigo
//
//  Created by Evan Long on 1/6/17.
//
//

#import "VTMainViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

#import "AVCamPreviewView.h"

@interface VTMainViewController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (nonatomic, strong) AVCamPreviewView *previewView;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@end

@implementation VTMainViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1. Setup Session and Input
    self.captureSession = [[AVCaptureSession alloc] init];
    self.videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoCaptureDevice error:&error];
    if (videoInput)
    {
        [self.captureSession addInput:videoInput];
    }
    else
    {
        // Need permission? Failure reasons?
    }
    
    VTLogFunctionWithObject(@([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]));

    // 2. Provide User Preview of Input
    self.previewView = [[AVCamPreviewView alloc] init];
    self.previewView.bounds = self.view.bounds;
    self.previewView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));

    self.previewView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.previewView.clipsToBounds = NO;
    self.previewView.session = self.captureSession;
    [self.view addSubview:self.previewView];

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation != UIInterfaceOrientationUnknown)
    {
        self.previewView.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)orientation;
    }
    
    // 3. Configure device capture mode
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        self.videoCaptureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        self.videoCaptureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        [self.videoCaptureDevice unlockForConfiguration];
    }

    // 4. Session stuff needs to happen on its own queue, don't bother starting or running if we don't have permissions etc...
    [self.captureSession startRunning];
    
    // 5. Configure the output source
    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.captureSession canAddOutput:movieFileOutput])
    {
        self.movieFileOutput = movieFileOutput;
        [self.captureSession addOutput:movieFileOutput];
        
        AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoStabilizationSupported)
        {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    else
    {
        // What does it mean if we could not add an output? Is this an error?
    }
    
    // Last: Layout Control UI
    UIButton *zoomOutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    zoomOutButton.backgroundColor = [UIColor whiteColor];
    zoomOutButton.titleLabel.textColor = [UIColor blackColor];
    [zoomOutButton setTitle:@"Zoom Out" forState:UIControlStateNormal];
    [zoomOutButton sizeToFit];
    [zoomOutButton addTarget:self action:@selector(_zoomOut) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:zoomOutButton];

    UIButton *zoomInButton = [UIButton buttonWithType:UIButtonTypeSystem];
    zoomInButton.backgroundColor = [UIColor whiteColor];
    [zoomInButton setTitle:@"Zoom In" forState:UIControlStateNormal];
    [zoomInButton sizeToFit];
    [zoomInButton addTarget:self action:@selector(_zoomIn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:zoomInButton];
    
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    recordButton.backgroundColor = [UIColor whiteColor];
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [recordButton sizeToFit];
    [recordButton addTarget:self action:@selector(_record) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordButton];
    
    zoomOutButton.translatesAutoresizingMaskIntoConstraints = NO;
    [zoomOutButton.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:50.0].active = YES;
    [zoomOutButton.rightAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:-20.0].active = YES;
    
    zoomInButton.translatesAutoresizingMaskIntoConstraints = NO;
    [zoomInButton.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:50.0].active = YES;
    [zoomInButton.leftAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:20.0].active = YES;
    
    recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    [recordButton.topAnchor constraintEqualToAnchor:zoomInButton.bottomAnchor constant:20.0].active = YES;
    [recordButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation))
    {
        self.previewView.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Private

- (void)_zoomOut
{
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        [self.videoCaptureDevice rampToVideoZoomFactor:1.0 withRate:8.0];
        [self.videoCaptureDevice unlockForConfiguration];
    }
}

- (void)_zoomIn
{
    if (self.videoCaptureDevice.videoZoomFactor >= 2.0) return;
    
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
//        [self.videoCaptureDevice rampToVideoZoomFactor:self.videoCaptureDevice.videoZoomFactor + 0.01 withRate:0.5];
        self.videoCaptureDevice.videoZoomFactor += 0.01;
        [self.videoCaptureDevice unlockForConfiguration];
    }
    [self performSelector:@selector(_zoomIn) withObject:nil afterDelay:1.0/60.0];
}

- (void)_record
{
    if (self.movieFileOutput.isRecording)
    {
        [self.movieFileOutput stopRecording];
    }
    else
    {
        // Update the orientation on the movie file output video connection before starting recording.
        AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        movieFileOutputConnection.videoOrientation = self.previewView.videoPreviewLayer.connection.videoOrientation;
        
        // Start recording to a temporary file.
        NSString *outputFileName = [NSUUID UUID].UUIDString;
        NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];

        [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    VTLogFunctionWithObject(fileURL);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    VTLogFunctionWithObject(outputFileURL);
    
    // EL TODO: cleanup of files in /tmp
    // Check for errors as a result of the recording
    [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
        if (status == PHAuthorizationStatusAuthorized)
        {
            // Save the movie file to the photo library and cleanup.
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                options.shouldMoveFile = YES;
                PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                [creationRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
            } completionHandler:^( BOOL success, NSError *error ) {
                if (!success)
                {
                    NSLog( @"Could not save movie to photo library: %@", error );
                }
//                cleanup();
            }];
        }
        else
        {
//            cleanup();
        }
    }];
}

@end
