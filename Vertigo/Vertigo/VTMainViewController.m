//
//  VTMainViewController.m
//  Vertigo
//
//  Created by Evan Long on 1/6/17.
//
//

#import "VTMainViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface VTMainViewController ()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation VTMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
        // need permission? failure reasons?
    }
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.previewLayer];
    
    [self.captureSession startRunning];
    
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        self.videoCaptureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        self.videoCaptureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        [self.videoCaptureDevice unlockForConfiguration];
    }

    UIButton *zoomOutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    zoomOutButton.backgroundColor = [UIColor whiteColor];
    zoomOutButton.titleLabel.textColor = [UIColor blackColor];
    [zoomOutButton setTitle:@"Zoom Out" forState:UIControlStateNormal];
    [zoomOutButton sizeToFit];
    zoomOutButton.center = CGPointMake(50.0, 50.0);
    [zoomOutButton addTarget:self action:@selector(_zoomOut) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:zoomOutButton];
    
    UIButton *zoomInButton = [UIButton buttonWithType:UIButtonTypeSystem];
    zoomInButton.backgroundColor = [UIColor whiteColor];
    [zoomInButton setTitle:@"Zoom In" forState:UIControlStateNormal];
    [zoomInButton sizeToFit];
    zoomInButton.center = CGPointMake(50.0, 100.0);
    [zoomInButton addTarget:self action:@selector(_zoomIn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:zoomInButton];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        self.previewLayer.frame = (CGRect){CGPointZero, size};
        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

#pragma mark - Private

#if 0
- (void)_zoomOut
{
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        self.videoCaptureDevice.videoZoomFactor -= 0.1;
        [self.videoCaptureDevice unlockForConfiguration];
    }
}

- (void)_zoomIn
{
    if ([self.videoCaptureDevice lockForConfiguration:nil])
    {
        self.videoCaptureDevice.videoZoomFactor += 0.1;
        [self.videoCaptureDevice unlockForConfiguration];
    }
}
#else
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
#endif

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
