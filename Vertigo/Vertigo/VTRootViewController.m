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

#import "AVCamPreviewView.h"

@interface VTRootViewController () // <AVCaptureFileOutputRecordingDelegate>

// AV capture and session
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

// Views
@property (nonatomic, strong) UIView *previewView;

@end

@implementation VTRootViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect viewBounds = self.view.bounds;
    
    // Setup Default UI Pieces
    self.previewView = [[UIView alloc] init];
    self.previewView.frame = viewBounds;
    self.previewView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.previewView.clipsToBounds = NO;
    self.previewView.backgroundColor = [UIColor magentaColor];
    [self.view addSubview:self.previewView];
    
    // Request permission if needed but otherwise configure rest of UI given video permission state
    [self _setupViewsFromUnknownVideoPermissionState];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Private

- (void)_setupViewsFromUnknownVideoPermissionState
{
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

- (void)_setupViewsWithVideoPermissionState:(BOOL)granted
{
    if (granted)
    {
        self.previewView.backgroundColor = [UIColor greenColor];
    }
    else
    {
        self.previewView.backgroundColor = [UIColor redColor];
    }
}

- (void)_handleTapToSettings
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:NULL];
}

@end
