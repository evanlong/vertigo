//
//  VTRootViewController.m
//  Vertigo
//
//  Created by Evan Long on 3/16/17.
//
//

#import "VTRootViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>

#import "HFKVOBlocks.h"

#import "VTAnalytics.h"
#import "VTCameraPreviewView.h"
#import "VTCameraController.h"
#import "VTCameraControlView.h"
#import "VTCompositeZoomEffectOperation.h"
#import "VTCountDownView.h"
#import "VTHelpRootViewController.h"
#import "VTMath.h"
#import "VTPieProgressView.h"
#import "VTRequiresCameraPermissionView.h"
#import "VTSaveVideoView.h"
#import "VTZoomEffectSettings.h"

typedef void(^VTViewWillDisappear)(void);
@interface _VTDismissActivityViewController : UIActivityViewController
@property (nonatomic, copy) VTViewWillDisappear viewWillDisappear;
@end

@implementation _VTDismissActivityViewController

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.viewWillDisappear)
    {
        self.viewWillDisappear();
    }
}

@end

#define USE_MARKETING_IMAGE 0

typedef NS_ENUM(NSInteger, VTRecordingState) {
    VTRecordingStateWaiting,
    VTRecordingStateCountingDown,
    VTRecordingStateTransitionToRecording,
    VTRecordingStateRecording,
    VTRecordingStateTransitionToWaiting,
};

@interface VTRootViewController () <VTCameraControlViewDelegate, VTCameraControllerDelegate, VTSaveVideoViewDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@property (nonatomic, strong) VTCameraController *cameraController;
@property (nonatomic, assign) VTRecordingState recordingState;

// Compositing
@property (nonatomic, strong) NSOperationQueue *processingQueue;

// Recording Views
@property (nonatomic, strong) UIView *recordingParentView;
@property (nonatomic, strong) VTCameraPreviewView *previewView; // camera preview
@property (nonatomic, strong) VTCameraControlView *cameraControlView; // fixed controls are placed in here
@property (nonatomic, strong) VTCountDownView *countDownView;

// Save View
@property (nonatomic, strong) VTSaveVideoView *saveVideoView;
@property (nonatomic, assign) BOOL didTakeActionOnVideo;

// Marketing
@property (nonatomic, strong) UIImageView *marketingImageView;

@end

@implementation VTRootViewController

static id commonInit(VTRootViewController *self)
{
    if (self)
    {
        self->_processingQueue = [[NSOperationQueue alloc] init];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDeviceOrientationNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self = commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self = commonInit(self);
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self = commonInit(self);
    }
    return self;
}

- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

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
    
    VTHelpRootViewController *helpVC = [[VTHelpRootViewController alloc] init];
    [self presentViewController:helpVC animated:YES completion:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    BOOL isPresentingSaveFlow = self.saveVideoView != nil;
    if (!isPresentingSaveFlow)
    {
        [UIView setAnimationsEnabled:NO];
        [CATransaction setDisableActions:YES];
    }
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation))
    {
        self.previewView.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self _updateLayoutForCurrentOrientation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (!isPresentingSaveFlow)
        {
            [CATransaction setDisableActions:NO];
            [UIView setAnimationsEnabled:YES];
        }
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self _updateLayoutForCurrentOrientation];
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
        VTAnalyticsTrackEvent(VTAnalyticsDidPressRecordingWhileWaitingEvent);

        VTWeakifySelf(weakSelf);
        [self.countDownView startWithCompletion:^(BOOL finished) {
            VTStrongifySelf(strongSelf, weakSelf);
            if (finished && strongSelf)
            {
                AVCaptureVideoOrientation orientation = strongSelf.previewView.videoPreviewLayer.connection.videoOrientation;
                
                VTZoomEffectSettings *zoomEffectSettings = [strongSelf _settingsForCurrentCameraControlViewState];
                [strongSelf.cameraController startRecordingWithOrientation:orientation withZoomEffectSettings:zoomEffectSettings];
                strongSelf.recordingState = VTRecordingStateTransitionToRecording;
            }
        }];
        self.recordingState = VTRecordingStateCountingDown;
    }
    else if (recordingState == VTRecordingStateCountingDown)
    {
        VTAnalyticsTrackEvent(VTAnalyticsDidPressRecordingWhileCountingDownEvent);

        [self.countDownView stop];
        self.recordingState = VTRecordingStateWaiting;
    }
    else if (recordingState == VTRecordingStateRecording)
    {
        VTAnalyticsTrackEvent(VTAnalyticsDidPressRecordingWhileRecordingEvent);

        [self.cameraController stopRecording];
        self.recordingState = VTRecordingStateTransitionToWaiting;
    }
    // else: nop transitioning between recording <-> waiting states
}

#pragma mark - VTCameraControllerDelegate

- (void)cameraControllerDidStartRunning:(VTCameraController *)cameraController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        VTAnalyticsTrackEvent(VTAnalyticsDidStartRecordingEvent);

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
#if 0
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
#endif

        self.recordingState = VTRecordingStateWaiting;
        self.cameraControlView.percentComplete = 0.0;
        
        // EL NOTE: The URL is passed to the share video, it might be better to hold this type of state in this view controller instead. And based
        // our decisions off the events coming from the view instead of the data we stick on there
        [self _startShareFlowWithVideoURL:outputFileURL];
    });

    // EL TODO: Check for errors as a result of the recording
}

- (void)cameraController:(VTCameraController *)cameraController didUpdateProgress:(CGFloat)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cameraControlView.percentComplete = progress;
    });
}

#pragma mark - VTSaveVideoViewDelegate

- (void)saveVideoViewDidPressShare:(VTSaveVideoView *)saveVideoView
{
    VTAnalyticsTrackEvent(VTAnalyticsDidPressShareEvent);

    [saveVideoView setHideControls:YES animated:YES];

    AVAsset *asset = [AVAsset assetWithURL:saveVideoView.videoURL];
    [self _composeAsset:asset withZoomEffectSettings:saveVideoView.settings completion:^(NSURL *composedAssetURL) {
        _VTDismissActivityViewController *activityViewController = [[_VTDismissActivityViewController alloc] initWithActivityItems:@[composedAssetURL] applicationActivities:@[]];
        activityViewController.viewWillDisappear = ^{
            [saveVideoView setHideControls:NO animated:YES];
        };
        activityViewController.completionWithItemsHandler = ^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            self.didTakeActionOnVideo = completed || self.didTakeActionOnVideo;
        };
        [self presentViewController:activityViewController animated:YES completion:nil];
    }];
}

- (void)saveVideoViewDidPressSave:(VTSaveVideoView *)saveVideoView
{
    VTAnalyticsTrackEvent(VTAnalyticsDidPressSaveEvent);
}

- (void)saveVideoViewDidPressDiscard:(VTSaveVideoView *)saveVideoView
{
    NSURL *videoURL = saveVideoView.videoURL;
    NSString *composedVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"composed.mov"];
    NSURL *composedVideoURL = [NSURL fileURLWithPath:composedVideoPath];
    if (self.didTakeActionOnVideo)
    {
        [self _endShareFlowWithVideoURLs:@[videoURL, composedVideoURL]];
    }
    else
    {
        UIAlertController *confirmDiscardAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SharePanelDiscardTitle", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        VTWeakifySelf(weakSelf);
        [confirmDiscardAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"SharePanelDiscard", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_Nonnull action) {
            [weakSelf _endShareFlowWithVideoURLs:@[videoURL, composedVideoURL]];
        }]];
        
        [confirmDiscardAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"SharePanelCancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
            // NOP
        }]];
        
        [self presentViewController:confirmDiscardAlert animated:YES completion:nil];
    }
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

    self.recordingParentView = [[UIView alloc] initWithFrame:viewBounds];
    self.recordingParentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:self.recordingParentView];

#if USE_MARKETING_IMAGE
    self.marketingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"patio11"]];
    self.marketingImageView.frame = viewBounds;
    self.marketingImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.marketingImageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.recordingParentView addSubview:self.marketingImageView];
#else
    self.previewView = [[VTCameraPreviewView alloc] initWithFrame:viewBounds];
    self.previewView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.previewView.clipsToBounds = NO;
    [self.recordingParentView addSubview:self.previewView];
    self.previewView.session = self.cameraController.captureSession;
#endif
    
    // 3. Control Host View
    self.cameraControlView = [[VTCameraControlView alloc] initWithFrame:viewBounds];
    self.cameraControlView.delegate = self;
    self.cameraControlView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.recordingParentView addSubview:self.cameraControlView];
    
    // 4. Countdown View
    self.countDownView = [[VTCountDownView alloc] init];
    VTAllowAutolayoutForView(self.countDownView);
    [self.recordingParentView addSubview:self.countDownView];
    [self.countDownView.centerXAnchor constraintEqualToAnchor:self.recordingParentView.centerXAnchor].active = YES;
    [self.countDownView.centerYAnchor constraintEqualToAnchor:self.recordingParentView.centerYAnchor].active = YES;

    [self.cameraController startRunning];
}

- (void)_setupForPermissionRequired
{
    VTRequiresCameraPermissionView *requirePermissionView = [[VTRequiresCameraPermissionView alloc] initWithFrame:self.view.bounds];
    requirePermissionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:requirePermissionView];
}

#pragma mark - Notifications

- (void)_handleDeviceOrientationNotification:(NSNotification *)notification
{
    // not sure if i need to update on orientation notification if -[UIVC viewDidLayoutSubviews] and -[UIVC viewWillTransitionToSize:withTransitionCoordinator:]
    // are called for the size changes and rotations as a result
//    [self _updateLayoutForCurrentOrientation];
}

#pragma mark - Private

- (void)_updateLayoutForCurrentOrientation
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (deviceOrientation == UIDeviceOrientationPortrait)
    {
        self.cameraControlView.orientation = VTCameraControlViewOrientationPortrait;
    }
    else if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
    {
        self.cameraControlView.orientation = VTCameraControlViewOrientationLandscapeLeft;
    }
    else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
    {
        self.cameraControlView.orientation = VTCameraControlViewOrientationLandscapeRight;
    }
}

- (VTZoomEffectSettings *)_settingsForCurrentCameraControlViewState
{
    VTMutableZoomEffectSettings *zoomEffectSettings = [[VTMutableZoomEffectSettings alloc] init];
    zoomEffectSettings.duration = self.cameraControlView.duration;
    return [zoomEffectSettings copy];
}

- (void)_updateCameraControlView
{
    // EL NOTE: maybe we put up a spinner if we are in a transitioning or count down state
    // EL NOTE: Should cameraControlView know more about intermediate state? "recording" basically disables all controls except the recording button...
    // EL NOTE: Instead of of "recording" perhaps we simply rename from "recording" to "disableControlsForRecording"
    self.cameraControlView.recording = (self.recordingState == VTRecordingStateRecording ||
                                        self.recordingState == VTRecordingStateCountingDown ||
                                        self.recordingState == VTRecordingStateTransitionToRecording);
}

- (void)_startShareFlowWithVideoURL:(NSURL *)url
{
    self.saveVideoView = [[VTSaveVideoView alloc] initWithVideoURL:url];
    self.saveVideoView.delegate = self;
    self.saveVideoView.frame = self.view.bounds;
    self.saveVideoView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:self.saveVideoView];
    self.recordingParentView.hidden = YES;
}

- (void)_endShareFlowWithVideoURLs:(NSArray<NSURL *> *)urls
{
    [self.saveVideoView removeFromSuperview];
    self.saveVideoView = nil;
    self.recordingParentView.hidden = NO;
    self.didTakeActionOnVideo = NO;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        for (NSURL *url in urls)
        {
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
    });
}

- (void)_composeAsset:(AVAsset *)asset withZoomEffectSettings:(VTZoomEffectSettings *)zoomEffectSettings completion:(void(^)(NSURL *composedAssetURL))completion
{
    VTCompositeZoomEffectOperation *compositeOperation = [[VTCompositeZoomEffectOperation alloc] initWithAsset:asset zoomEffectSettings:zoomEffectSettings];
    [self.processingQueue addOperation:compositeOperation];

    UIView *overlayHost = [[UIView alloc] init];
    VTAllowAutolayoutForView(overlayHost);
    overlayHost.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.4];
    [self.view addSubview:overlayHost];

    [overlayHost.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [overlayHost.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    [overlayHost.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [overlayHost.heightAnchor constraintEqualToAnchor:self.view.heightAnchor].active = YES;

    VTPieProgressView *progressView = [[VTPieProgressView alloc] init];
    VTAllowAutolayoutForView(progressView);
    [self.view addSubview:progressView];
    
    progressView.alpha = 0.0;
    progressView.transform = CGAffineTransformMakeScale(0.80, 0.80);
    [UIView animateWithDuration:0.33 animations:^{
        progressView.alpha = 1.0;
        progressView.transform = CGAffineTransformIdentity;
    }];
    
    [progressView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [progressView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;

    id token = [compositeOperation hf_addBlockObserver:^(VTCompositeZoomEffectOperation *compositeOperation, NSDictionary *change) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressView.progress = compositeOperation.progress;
        });
    } forKeyPath:VTKeyPath(compositeOperation, progress)];

    VTWeakifyVar(weakCompositeOperation, compositeOperation);
    compositeOperation.completionBlock = ^{
        VTStrongifySelf(strongOperation, weakCompositeOperation);
        [strongOperation hf_removeBlockObserverWithToken:token];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView removeFromSuperview];
            [overlayHost removeFromSuperview];
            completion(strongOperation.composedVideoURL);
        });
    };
}

@end
