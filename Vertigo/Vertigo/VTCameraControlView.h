//
//  VTCameraControlView.h
//  Vertigo
//
//  Created by Evan Long on 3/22/17.
//
//

#import "VTCaptureTypes.h"

NS_ASSUME_NONNULL_BEGIN

// EL NOTE: The possible duration, directions and zoom limits are sorts of information that could come from VC or whatever is setting
// up the view. The app is pretty specific so setting information hardcoded into a view seems OK for now
// EL NOTE: Also possible to have a dataSource to retrieve possible values, limits, valid sets for

typedef NS_ENUM(NSInteger, VTRecordDuration) {
    VTRecordDuration1Second = 1,
    VTRecordDuration2Second = 2,
    VTRecordDuration3Second = 3,
    VTRecordDuration4Second = 4,
    VTRecordDuration5Second = 5,
    VTRecordDurationLast,
};

@protocol VTCameraControlViewDelegate;

@interface VTCameraControlView : UIView

@property (nonatomic, nullable, weak) id<VTCameraControlViewDelegate> delegate;

@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, readonly, assign) VTRecordDirection direction;
@property (nonatomic, readonly, assign) VTRecordDuration duration;
@property (nonatomic, readonly, assign) BOOL shouldLoop;

// EL NOTE: The pulled zoom level should always be greater than the pushed... how to enforce this
// When these can be adjusted by the UI, the model can adjust these automatically and view can remain dumb
// For the view, any zoom setting is OK, or the view can ask delegate "is zoom OK" or for the "limits" it should be rendering...
@property (nonatomic, readonly, assign) CGFloat pushedZoomLevel; // default 1.0x
@property (nonatomic, readonly, assign) CGFloat pulledZoomLevel; // default 2.0x

@end

@protocol VTCameraControlViewDelegate <NSObject>

@optional
- (void)cameraControlViewDidPressRecordButton:(VTCameraControlView *)cameraControlView;
- (void)cameraControlViewDidChangeDirection:(VTCameraControlView *)cameraControlView;

@end

NS_ASSUME_NONNULL_END
