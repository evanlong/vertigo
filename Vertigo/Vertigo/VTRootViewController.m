//
//  VTRootViewController.m
//  Vertigo
//
//  Created by Evan Long on 3/16/17.
//
//

#import "VTRootViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

#import "VTCameraPreviewView.h"
#import "VTCameraController.h"
#import "VTCameraControlView.h"
#import "VTRequiresCameraPermissionView.h"
#import "VTZoomEffectSettings.h"

typedef NS_ENUM(NSInteger, VTRecordingState) {
    VTRecordingStateWaiting,
    VTRecordingStateTransitionToRecording,
    VTRecordingStateRecording,
    VTRecordingStateTransitionToWaiting,
};

@interface VTRootViewController () <VTCameraControlViewDelegate, VTCameraControllerDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@property (nonatomic, strong) VTCameraController *cameraController;
@property (nonatomic, assign) VTRecordingState recordingState;

// Views
@property (nonatomic, strong) VTCameraPreviewView *previewView; // camera preview
@property (nonatomic, strong) VTCameraControlView *cameraControlView; // fixed controls are placed in here

@end

@implementation VTRootViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Request permission if needed but otherwise configure rest of UI given video permission state
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _setupViewsWithVideoPermissionState:granted];
            });
        }];
    }
    else
    {
        BOOL granted = (videoAuthStatus == AVAuthorizationStatusAuthorized);
        [self _setupViewsWithVideoPermissionState:granted];
    }
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

- (BOOL)shouldAutorotate
{
    return (self.recordingState == VTRecordingStateWaiting);
}

#pragma mark - VTRootViewController

- (void)setRecordingState:(VTRecordingState)recordingState
{
    if (_recordingState != recordingState)
    {
        _recordingState = recordingState;
        [self _updateCameraControlView];
    }
}

#pragma mark - VTCameraControlViewDelegate

- (void)cameraControlViewDidPressRecordButton:(VTCameraControlView *)cameraControlView
{
    VTRecordingState recordingState = self.recordingState;
    if (recordingState == VTRecordingStateWaiting)
    {
        AVCaptureVideoOrientation orientation = self.previewView.videoPreviewLayer.connection.videoOrientation;
        
        VTZoomEffectSettings *zoomEffectSettings = [self _settingsForCurrentCameraControlViewState];
        [self.cameraController startRecordingWithOrientation:orientation withZoomEffectSettings:zoomEffectSettings];
        self.recordingState = VTRecordingStateTransitionToRecording;
    }
    else if (recordingState == VTRecordingStateRecording)
    {
        [self.cameraController stopRecording];
        self.recordingState = VTRecordingStateTransitionToWaiting;
    }
    // else: nop transitioning between recording <-> waiting states
}

- (void)cameraControlViewDidChangeDirection:(VTCameraControlView *)cameraControlView
{
    [self _updatePreviewZoomLevel];
}

#pragma mark - VTCameraControllerDelegate

- (void)cameraControllerDidStartRunning:(VTCameraController *)cameraController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Following AVCam state here, since it started running successfully make sure previewLayer connection has write orientation
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
        if (statusBarOrientation != UIInterfaceOrientationUnknown)
        {
            initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
        }
        
        self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
    });
}

- (void)cameraControllerDidStopRunning:(VTCameraController *)cameraController
{
}

- (void)cameraController:(VTCameraController *)cameraController didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recordingState = VTRecordingStateRecording;
    });
}

- (void)cameraController:(VTCameraController *)cameraController didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
{
    dispatch_async(dispatch_get_main_queue(), ^{
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
                    // cleanup();
                }];
            }
            else
            {
                // cleanup();
            }
        }];

        self.recordingState = VTRecordingStateWaiting;
    });

    // EL TODO: cleanup of files in /tmp
    // Check for errors as a result of the recording
}

#pragma mark - Private (Setup)

- (void)_setupViewsWithVideoPermissionState:(BOOL)granted
{
    if (granted)
    {
        [self _setupForGrantedPermission];
    }
    else
    {
        [self _setupForPermissionRequired];
    }
}

- (void)_setupForGrantedPermission
{
    // 1. Setup Camera Controller
    self.cameraController = [[VTCameraController alloc] init];
    self.cameraController.delegate = self;

    // 2. Setup Camera Preview and Connect
    CGRect viewBounds = self.view.bounds;
    self.previewView = [[VTCameraPreviewView alloc] init];
    self.previewView.frame = viewBounds;
    self.previewView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.previewView.clipsToBounds = NO;
    [self.view addSubview:self.previewView];
    self.previewView.session = self.cameraController.captureSession;
    
    // 3. Control Host View
    self.cameraControlView = [[VTCameraControlView alloc] init];
    self.cameraControlView.delegate = self;
    self.cameraControlView.frame = viewBounds;
    self.cameraControlView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:self.cameraControlView];

    [self.cameraController startRunning];
    
    [self _updatePreviewZoomLevel];
}

- (void)_setupForPermissionRequired
{
    VTRequiresCameraPermissionView *requirePermissionView = [[VTRequiresCameraPermissionView alloc] init];
    requirePermissionView.frame = self.view.bounds;
    requirePermissionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:requirePermissionView];
}

#pragma mark - Private

- (VTZoomEffectSettings *)_settingsForCurrentCameraControlViewState
{
    VTMutableZoomEffectSettings *zoomEffectSettings = [[VTMutableZoomEffectSettings alloc] init];
    zoomEffectSettings.duration = self.cameraControlView.duration;
    if (self.cameraControlView.direction == VTRecordDirectionPush)
    {
        zoomEffectSettings.initalZoomLevel = self.cameraControlView.pulledZoomLevel;
        zoomEffectSettings.finalZoomLevel = self.cameraControlView.pushedZoomLevel;
    }
    else
    {
        zoomEffectSettings.initalZoomLevel = self.cameraControlView.pushedZoomLevel;
        zoomEffectSettings.finalZoomLevel = self.cameraControlView.pulledZoomLevel;
    }
    return [zoomEffectSettings copy];
}

- (void)_updateCameraControlView
{
    // maybe we put up a spinner if we are transitioning?
    self.cameraControlView.recording = (self.recordingState == VTRecordingStateRecording);
}

- (void)_updatePreviewZoomLevel
{
    VTZoomEffectSettings *zoomEffectSettings = [self _settingsForCurrentCameraControlViewState];
    [self.cameraController updatePreviewZoomLevel:zoomEffectSettings.initalZoomLevel];
}

@end
