//
//  VTCameraController.h
//  Vertigo
//
//  Created by Evan Long on 3/24/17.
//
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VTCameraControllerDelegate;

@class VTZoomEffectSettings;

/**
 VTCameraController supports controlling camera for achieving the Vertigo effect

 This object itself is not thread safe. It should be used from either the main queue or another serial queue. It
 handles AV capture related code on a serial queue internally. VTCameraControllerDelegate methods may be called
 back on an arbitrary queue so it the responsibility of the delegate to dispatch any work to the appropriate queue
 */
@interface VTCameraController : NSObject

@property (nonatomic, weak, nullable) id<VTCameraControllerDelegate> delegate;

//! captureSession of the VTCameraController can be used to configure a AVCaptureVideoPreviewLayer
@property (nonatomic, readonly, strong) AVCaptureSession *captureSession;

// previewZoomLevel clamp to the range [minimumZoomLevel, maximumZoomLevel]
- (void)updatePreviewZoomLevel:(CGFloat)previewZoomLevel;

// EL NOTE: Note start/stop running called by things like viewDid(Dis)Appear
/*!
 The startRunning, stopRunning, startRecordingWithOrientation, stopRecording are all asynchronous in nature. Delegate callbacks will
 occur as the underlying AV objects make state transitions.
 */
- (void)startRunning;
- (void)stopRunning;
//@property (nonatomic, readonly, assign, getter=isRunning) BOOL running;

// Recording related calls are a nop if VTCameraController is not running
- (void)startRecordingWithOrientation:(AVCaptureVideoOrientation)orientation withZoomEffectSettings:(VTZoomEffectSettings *)zoomEffectSettings;
- (void)stopRecording;
//@property (nonatomic, readonly, assign, getter=isRecording) BOOL recording;

// EL TODO: Properties exposing the running, recording reflect underlying AV state from another queue which is a bit problamatic.
/*
 For example:
 1. Main Queue could read properties in a loop
 2. Background thread could be queue the delegate message of a state change
 3. Main Queue sees the property changed, before the message from the delegate is delivered to main queue
 - This won't strictly cause a bug, but ordering is inconsistent, the delegate, and state should be changing a bit more lock and step I think
    - Internally, commands are serialize to the serial queue for the AV objects so that's all OK

    - Bug in user code would occur if it relied only on publically exposed properties like so:
        - So delegate calls occurs noting didStart/StopRunning
        - client code dispatches to main queue, and reads public property and sees state A
        - Calls some other methods that also happen check public property, which now read state B, because in the background the state has changed!
            - Now the question is: does this matter, maybe and maybe not. But that sequence of code triggered by the "didStart" delegate call
              might expect isRecording not to suddenly change, and making that guarantee is impossible. Better to prevent that sort of thing I think
 
 Client code that would be problamatic:
        if (self.cameraController.isRecording) {
            A()
        }
 
        checkInToServer();
 
        if (self.cameraController.isRecording) {
            B();
        }
    isRecording state could have changed between call between A, and B callsites. In a function, you could capture the isRecording early on,
    but across multiple method calls calling out to self.cameraController.isRecording is quite possible. As a result, code might not being run
    as expected
 -
 */
// Fixing Would require initialization with queue that client of VTCameraController is using to serialize correctly or clients to track state

// Nop if not running
//- (void)previewEffectWithSettings;
//- (void)startRecordingEffectWithSettings;

@end

@protocol VTCameraControllerDelegate <NSObject>

@optional
- (void)cameraControllerDidStartRunning:(VTCameraController *)cameraController;
- (void)cameraControllerDidStopRunning:(VTCameraController *)cameraController;

- (void)cameraController:(VTCameraController *)cameraController didStartRecordingToOutputFileAtURL:(NSURL *)fileURL;
- (void)cameraController:(VTCameraController *)cameraController didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL;

- (void)cameraController:(VTCameraController *)cameraController didUpdateProgress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
