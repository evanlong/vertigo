//
//  VTCameraControlView.m
//  Vertigo
//
//  Created by Evan Long on 3/22/17.
//
//

#import "VTCameraControlView.h"

#import "VTMath.h"
#import "VTToggleButton.h"

#define CONTROL_BACKDROP_COLOR          [UIColor colorWithWhite:0.1 alpha:0.70]
#define DURATION_MIN                    1.0
#define DURATION_MAX                    8.0

@interface VTCameraControlView ()

// Data
@property (nonatomic, readwrite, assign) NSTimeInterval duration;
@property (nonatomic, readonly, assign) NSTimeInterval rawDuration;

// Controls
@property (nonatomic, strong) UIView *pushPullControlBackdrop;
@property (nonatomic, strong) UISegmentedControl *pushPullControl;

@property (nonatomic, strong) UIView *pushedZoomLevelView;
@property (nonatomic, strong) UIView *pushPullIndicatorArrow;
@property (nonatomic, strong) UIView *pulledZoomLevelView;

@property (nonatomic, strong) UISlider *durationSlider;

@property (nonatomic, strong) UIView *bottomViewHost;
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIView *loopToggleView;

@end

@implementation VTCameraControlView
{
    struct {
        unsigned int delegateDidPressRecordButton:1;
        unsigned int delegateDidChangeDirection:1;
    } _flags;
}

@synthesize duration = _duration;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.tintColor = [UIColor whiteColor];

        { // Top Controls
            _pushPullControlBackdrop = [[UIView alloc] init];
            VTAllowAutolayoutForView(_pushPullControlBackdrop);
            _pushPullControlBackdrop.backgroundColor = CONTROL_BACKDROP_COLOR;
            [self addSubview:_pushPullControlBackdrop];
            
            NSArray *pushPullItems = @[NSLocalizedString(@"SegmentPull", nil), NSLocalizedString(@"SegmentPush", nil)];
            _pushPullControl = [[UISegmentedControl alloc] initWithItems:pushPullItems];
            _pushPullControl.selectedSegmentIndex = 0;
            VTAllowAutolayoutForView(_pushPullControl);
            [_pushPullControlBackdrop addSubview:_pushPullControl];
            
            [_pushPullControl addTarget:self action:@selector(_handleDirectionChange) forControlEvents:UIControlEventValueChanged];
            
            [_pushPullControl.centerXAnchor constraintEqualToAnchor:_pushPullControlBackdrop.centerXAnchor].active = YES;
            [_pushPullControl.centerYAnchor constraintEqualToAnchor:_pushPullControlBackdrop.centerYAnchor].active = YES;
            [_pushPullControlBackdrop.heightAnchor constraintEqualToAnchor:_pushPullControl.heightAnchor constant:16.0].active = YES;
            [_pushPullControlBackdrop.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
            
            [_pushPullControlBackdrop.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            [_pushPullControlBackdrop.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        }
        
        { // Bottom Controls
            _bottomViewHost = [[UIView alloc] init];
            VTAllowAutolayoutForView(_bottomViewHost);
            _bottomViewHost.backgroundColor = CONTROL_BACKDROP_COLOR;
            [self addSubview:_bottomViewHost];
            
            [_bottomViewHost.heightAnchor constraintEqualToConstant:70.0].active = YES;
            [_bottomViewHost.widthAnchor constraintEqualToAnchor:_pushPullControlBackdrop.widthAnchor].active = YES;
            [_bottomViewHost.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            [_bottomViewHost.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            
            // Record
            _recordButton = [[UIButton alloc] init];
            VTAllowAutolayoutForView(_recordButton);
            _recordButton.backgroundColor = [UIColor redColor];
            [_bottomViewHost addSubview:_recordButton];
            
            [_recordButton addTarget:self action:@selector(_handleRecordButtonPress) forControlEvents:UIControlEventTouchUpInside];
            
            [_recordButton.centerXAnchor constraintEqualToAnchor:_bottomViewHost.centerXAnchor].active = YES;
            [_recordButton.centerYAnchor constraintEqualToAnchor:_bottomViewHost.centerYAnchor].active = YES;
            [_recordButton.widthAnchor constraintEqualToConstant:50.0].active = YES;
            [_recordButton.heightAnchor constraintEqualToConstant:50.0].active = YES;
            
            // Duration Toggle
            _durationLabel = [[UILabel alloc] init];
            _durationLabel.font = [UIFont monospacedDigitSystemFontOfSize:16.0 weight:UIFontWeightRegular];
            VTAllowAutolayoutForView(_durationLabel);
            _durationLabel.textColor = self.tintColor;
            _durationLabel.textAlignment = NSTextAlignmentCenter;
            [_bottomViewHost addSubview:_durationLabel];
            
            [_durationLabel.rightAnchor constraintEqualToAnchor:_recordButton.leftAnchor].active = YES;
            [_durationLabel.leftAnchor constraintEqualToAnchor:_bottomViewHost.leftAnchor].active = YES;
            [_durationLabel.centerYAnchor constraintEqualToAnchor:_recordButton.centerYAnchor].active = YES;
            [_durationLabel.heightAnchor constraintEqualToConstant:30.0].active = YES;
            
            // Loop Toggle
            _loopToggleView = [[UIView alloc] init];
            _loopToggleView.hidden = YES; // EL TODO: add back when needed
            VTAllowAutolayoutForView(_loopToggleView);
            _loopToggleView.backgroundColor = [UIColor blueColor];
            [_bottomViewHost addSubview:_loopToggleView];
            
            [_loopToggleView.leftAnchor constraintEqualToAnchor:_recordButton.rightAnchor constant:40.0].active = YES;
            [_loopToggleView.centerYAnchor constraintEqualToAnchor:_bottomViewHost.centerYAnchor].active = YES;
            [_loopToggleView.widthAnchor constraintEqualToConstant:30.0].active = YES;
            [_loopToggleView.heightAnchor constraintEqualToConstant:30.0].active = YES;
        }
        
        { // Slider Adjustment Controls
            _durationSlider = [[UISlider alloc] init];
            _durationSlider.minimumValue = DURATION_MIN;
            _durationSlider.maximumValue = DURATION_MAX;
            VTAllowAutolayoutForView(_durationSlider);
            [self addSubview:_durationSlider];
            
            [_durationSlider addTarget:self action:@selector(_handleDurationSliderChange) forControlEvents:UIControlEventValueChanged];
            
            [_durationSlider.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            [_durationSlider.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
            [_durationSlider.bottomAnchor constraintEqualToAnchor:_bottomViewHost.topAnchor constant:-10.0].active = YES;
        }
        
        { // Configure Default Property and View State
            _recording = NO;
            _shouldLoop = NO;
            _pushedZoomLevel = 1.0;
            _pulledZoomLevel = 2.0;

            // EL TODO: A better pattern is to "update" our controls for our property values. That way it's the same code when
            // or if the properties become readwrite. And various properties will influence various controls
            self.duration = 2.0;
        }
    }
    return self;
}

- (void)setDelegate:(id<VTCameraControlViewDelegate>)delegate
{
    if (_delegate != delegate)
    {
        _delegate = delegate;
        _flags.delegateDidPressRecordButton = [delegate respondsToSelector:@selector(cameraControlViewDidPressRecordButton:)];
        _flags.delegateDidChangeDirection = [delegate respondsToSelector:@selector(cameraControlViewDidChangeDirection:)];
    }
}

- (void)setRecording:(BOOL)recording
{
    if (_recording != recording)
    {
        _recording = recording;
        [self _updateViewRecordingState];
    }
}

- (VTRecordDirection)direction
{
    return (VTRecordDirection)self.pushPullControl.selectedSegmentIndex;
}

- (void)setDuration:(NSTimeInterval)duration
{
    // EL NOTE: To reduce number of _update* calls we could round in this setter intead of getter. Doing so would require
    // resetting the slider's value back to its original value after it updates this property. As a result the rawDuration
    // property would no longer have any meaning

    duration = VTClamp(duration, DURATION_MIN, DURATION_MAX);
    if (_duration != duration)
    {
        _duration = duration;
        [self _updateDurationSlider];
        [self _updateDurationLabelText];
    }
}

- (NSTimeInterval)duration
{
    return VTRoundToNearestFactor(_duration, 0.25);
}

- (NSTimeInterval)rawDuration
{
    return _duration;
}

#pragma mark - Events

- (void)_handleRecordButtonPress
{
    if (_flags.delegateDidPressRecordButton)
    {
        [self.delegate cameraControlViewDidPressRecordButton:self];
    }
}

- (void)_handleDirectionChange
{
    if (_flags.delegateDidChangeDirection)
    {
        [self.delegate cameraControlViewDidChangeDirection:self];
    }
}

- (void)_handleDurationSliderChange
{
    self.duration = self.durationSlider.value;
}

#pragma mark - Private

- (void)_updateViewRecordingState
{
    if (self.isRecording)
    {
        [self.recordButton setTitle:NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
        self.pushPullControl.userInteractionEnabled = NO;
        self.durationSlider.userInteractionEnabled = NO;
    }
    else
    {
        [self.recordButton setTitle:@"" forState:UIControlStateNormal];
        self.pushPullControl.userInteractionEnabled = YES;
        self.durationSlider.userInteractionEnabled = YES;
    }
}

- (void)_updateDurationSlider
{
    self.durationSlider.value = self.rawDuration;
}

- (void)_updateDurationLabelText
{
    self.durationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DurationToggleSeconds", nil), self.duration];
}

@end
