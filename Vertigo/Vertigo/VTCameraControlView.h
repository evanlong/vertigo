//
//  VTCameraControlView.h
//  Vertigo
//
//  Created by Evan Long on 3/22/17.
//
//

#import "VTCaptureTypes.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VTCameraControlViewOrientation) {
    VTCameraControlViewOrientationPortrait,
    VTCameraControlViewOrientationLandscapeLeft, // Device turned left, home button on the right
    VTCameraControlViewOrientationLandscapeRight, // Device turned right, home button on the left
};

@protocol VTCameraControlViewDelegate;

@interface VTCameraControlView : UIView

@property (nonatomic, nullable, weak) id<VTCameraControlViewDelegate> delegate;

// VTCameraControlView will disable certain controls while recording
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, assign) CGFloat percentComplete;

@property (nonatomic, readonly, assign) NSTimeInterval duration;

// EL NOTE: The pulled zoom level should always be greater than the pushed... how to enforce this
// When these can be adjusted by the UI, the model can adjust these automatically and view can remain dumb
// For the view, any zoom setting is OK, or the view can ask delegate "is zoom OK" or for the "limits" it should be rendering...
@property (nonatomic, readonly, assign) CGFloat pushedZoomLevel; // default 1.0x
@property (nonatomic, readonly, assign) CGFloat pulledZoomLevel; // default 2.0x

@property (nonatomic, assign) VTCameraControlViewOrientation orientation;

@end

@protocol VTCameraControlViewDelegate <NSObject>

@optional
- (void)cameraControlViewDidPressRecordButton:(VTCameraControlView *)cameraControlView;
- (void)cameraControlViewDidPressHelpButton:(VTCameraControlView *)cameraControlView;
- (void)cameraControlViewDidChangeDirection:(VTCameraControlView *)cameraControlView;

/**
 EL TODO:

 Ways to notify of the changes that UI is making here:
    - NSNotification
    - KVO on readonly properties
    - Delegate

 These could all sync at one spot, produce a new VTZoomEffectSettings, which is then passed on to the camera controller, it reads the
 settings as provided, and reconfigures itself for the various duration and zoom levels.
 
 Then actions like "loop" and "record" are simply called, and will run with the last set of settings that were provided.
    - The benefit to this approach is when I add "loop" and while it's "looping" the duration changes, this can adjust for that change now
      more easily, without the need to pass in some seperate state
 
 Currently, pieces of state are passed in (desired preview zoom level), and then entire settings package is passed in when action is started
 
 Also, are there things the camera controller could change, that need to flow back here? "CurrentZoomLevel" is obvious example
 */

@end

NS_ASSUME_NONNULL_END
