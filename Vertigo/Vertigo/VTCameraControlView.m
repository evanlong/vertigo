//
//  VTCameraControlView.m
//  Vertigo
//
//  Created by Evan Long on 3/22/17.
//
//

#import "VTCameraControlView.h"

#import "VTMath.h"
#import "VTPushPullToggleControl.h"

#define CONTROL_BACKDROP_COLOR              [UIColor colorWithWhite:0.1 alpha:0.70]
#define DURATION_MIN                        1.0
#define DURATION_MAX                        8.0

#define DURATION_SLIDER_HEIGHT_MULTIPLIER   0.8

@interface VTCameraControlView ()

// Data
@property (nonatomic, readwrite, assign) NSTimeInterval duration;
@property (nonatomic, readonly, assign) NSTimeInterval rawDuration;

// Controls
@property (nonatomic, strong) VTPushPullToggleControl *pushPullToggleControl;
@property (nonatomic, strong) UISlider *durationSlider;
@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) UIView *bottomViewHost;
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UILabel *durationLabel;

@property (nonatomic, strong) UILayoutGuide *backdropSpaceGuide;

@property (nonatomic, assign, getter=isTouchingDurationSlider) BOOL touchingDurationSlider;

@end

@implementation VTCameraControlView
{
    struct {
        unsigned int delegateDidPressRecordButton:1;
        unsigned int delegateDidChangeDirection:1;
    } _flags;
}

@synthesize duration = _duration;

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.tintColor = [UIColor whiteColor];
        
        { // Bottom Controls
            _bottomViewHost = [[UIView alloc] init];
            VTAllowAutolayoutForView(_bottomViewHost);
            _bottomViewHost.backgroundColor = CONTROL_BACKDROP_COLOR;
            [self addSubview:_bottomViewHost];
            
            [_bottomViewHost.heightAnchor constraintEqualToConstant:70.0].active = YES;
            [_bottomViewHost.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
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
        }
        
        { // Progress View
            _progressView = [[UIProgressView alloc] init];
            _progressView.progressTintColor = [UIColor redColor];
            _progressView.trackTintColor = [UIColor clearColor];
            VTAllowAutolayoutForView(_progressView);
            [self addSubview:_progressView];

            [_progressView.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
            [_progressView.heightAnchor constraintEqualToConstant:4.0].active = YES;
            [_progressView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            [_progressView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        }
        
        { // Slider Adjustment Controls
            _durationSlider = [[UISlider alloc] init];
            _durationSlider.layer.shadowColor = [UIColor blackColor].CGColor;
            _durationSlider.layer.shadowRadius = 2.0;
            _durationSlider.layer.shadowOpacity = 0.75;
            _durationSlider.layer.shadowOffset = CGSizeMake(0.0, 0.0);
            _durationSlider.minimumValue = DURATION_MIN;
            _durationSlider.maximumValue = DURATION_MAX;
            VTAllowAutolayoutForView(_durationSlider);
            [self addSubview:_durationSlider];
            
            [_durationSlider addTarget:self action:@selector(_handleDurationSliderChange) forControlEvents:UIControlEventValueChanged];
            
            [_durationSlider addTarget:self action:@selector(_handleDurationSliderTouchDown) forControlEvents:UIControlEventTouchDown];
            [_durationSlider addTarget:self action:@selector(_handleDurationSliderClear) forControlEvents:UIControlEventTouchCancel];
            [_durationSlider addTarget:self action:@selector(_handleDurationSliderClear) forControlEvents:UIControlEventTouchUpInside];
            [_durationSlider addTarget:self action:@selector(_handleDurationSliderClear) forControlEvents:UIControlEventTouchUpOutside];
            
            _backdropSpaceGuide = [[UILayoutGuide alloc] init];
            [self addLayoutGuide:_backdropSpaceGuide];

            // backdropSpaceGuide guide height and centerY represent the area between the backdrop and bottom host views
            [_backdropSpaceGuide.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
            [_backdropSpaceGuide.bottomAnchor constraintEqualToAnchor:_bottomViewHost.topAnchor].active = YES;
            [_backdropSpaceGuide.leftAnchor constraintEqualToAnchor:_durationSlider.centerXAnchor].active = YES;

            [_durationSlider.centerXAnchor constraintEqualToAnchor:self.leftAnchor constant:40.0].active = YES;
            [_durationSlider.centerYAnchor constraintEqualToAnchor:_backdropSpaceGuide.centerYAnchor].active = YES;
            [_durationSlider.widthAnchor constraintEqualToAnchor:_backdropSpaceGuide.heightAnchor multiplier:DURATION_SLIDER_HEIGHT_MULTIPLIER].active = YES;
            _durationSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
            
            // Duration Label
            _durationLabel = [[UILabel alloc] init];
            _durationLabel.font = [UIFont monospacedDigitSystemFontOfSize:24.0 weight:UIFontWeightRegular];
            _durationLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            _durationLabel.layer.shadowRadius = 2.0;
            _durationLabel.layer.shadowOpacity = 1.0;
            _durationLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
            _durationLabel.textColor = self.tintColor;
            _durationLabel.textAlignment = NSTextAlignmentCenter;
            [self addSubview:_durationLabel];
        }
        
        { // Push/Pull Buttons
            _pushPullToggleControl = [[VTPushPullToggleControl alloc] init];
            VTAllowAutolayoutForView(_pushPullToggleControl);
            [self addSubview:_pushPullToggleControl];
            
            [_pushPullToggleControl addTarget:self action:@selector(_handleDirectionChange) forControlEvents:UIControlEventValueChanged];
            
            [_pushPullToggleControl.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-40.0].active = YES;
            [_pushPullToggleControl.centerYAnchor constraintEqualToAnchor:_backdropSpaceGuide.centerYAnchor].active = YES;
        }
        
        { // Configure Default Property and View State
            _recording = NO;
            _pushedZoomLevel = 1.0;
            _pulledZoomLevel = 2.0;
            _percentComplete = 0.0;

            [UIView performWithoutAnimation:^{
                self.duration = 2.0;
                [self _updateViewRecordingState];
                [self _updateProgress];
                [self _updateDurationLabelTransform];
            }];
        }
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [UIView performWithoutAnimation:^{
        [self _updateDurationLabelPosition];
    }];
}

#pragma mark - VTCameraControlView

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

- (void)setPercentComplete:(CGFloat)percentComplete
{
    if (_percentComplete != percentComplete)
    {
        _percentComplete = percentComplete;
        [self _updateProgress];
    }
}

- (VTVertigoDirection)direction
{
    return (VTVertigoDirection)self.pushPullToggleControl.direction;
}

- (void)setDuration:(NSTimeInterval)duration
{
    // EL NOTE: To reduce number of _update* calls we could round in this setter intead of getter. Doing so would require
    // resetting the slider's value back to its original value after it updates this property (this avoids a jittery effect as sliders is dragged)
    // As a result the rawDuration property would no longer have any meaning

    duration = VTClamp(duration, DURATION_MIN, DURATION_MAX);
    if (_duration != duration)
    {
        _duration = duration;
        [self _updateDurationSlider];
        [self _updateDurationLabelText];
        [self _updateDurationLabelPosition];
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

- (void)setTouchingDurationSlider:(BOOL)touchingDurationSlider
{
    if (_touchingDurationSlider != touchingDurationSlider)
    {
        _touchingDurationSlider = touchingDurationSlider;
        [self _updateDurationLabelTransform];
    }
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

- (void)_handleDurationSliderTouchDown
{
    self.touchingDurationSlider = YES;
}

- (void)_handleDurationSliderClear
{
    self.touchingDurationSlider = NO;
}

#pragma mark - Private

- (void)_updateViewRecordingState
{
    if (self.isRecording)
    {
        [self.recordButton setTitle:NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
        self.pushPullToggleControl.userInteractionEnabled = NO;
        self.durationSlider.userInteractionEnabled = NO;
        self.progressView.hidden = NO;
    }
    else
    {
        [self.recordButton setTitle:@"" forState:UIControlStateNormal];
        self.pushPullToggleControl.userInteractionEnabled = YES;
        self.durationSlider.userInteractionEnabled = YES;
        self.progressView.hidden = YES;
    }
}

- (void)_updateProgress
{
    self.progressView.progress = self.percentComplete;
}

- (void)_updateDurationSlider
{
    self.durationSlider.value = self.rawDuration;
}

- (void)_updateDurationLabelText
{
    NSDictionary *attributes = @{NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSStrokeColorAttributeName : [UIColor colorWithWhite:0.0 alpha:0.5],
                                 NSStrokeWidthAttributeName : @(-2.0),
                                 NSFontAttributeName : [UIFont monospacedDigitSystemFontOfSize:22.0 weight:UIFontWeightBold]};
    NSString *durationText = [NSString stringWithFormat:NSLocalizedString(@"DurationToggleSeconds", nil), self.duration];
    self.durationLabel.attributedText = [[NSAttributedString alloc] initWithString:durationText attributes:attributes];
}

- (void)_updateDurationLabelPosition
{
    [self.durationLabel sizeToFit];

    CGFloat durationLabelHeight = CGRectGetHeight(self.durationLabel.bounds);
    CGRect guideFrame = self.backdropSpaceGuide.layoutFrame;
    CGFloat sliderHeight = CGRectGetWidth(self.durationSlider.bounds) - durationLabelHeight; // width -> height since slider is rotated 90 degrees
    CGFloat guideCenterY = CGRectGetMidY(guideFrame);
    CGFloat minY = guideCenterY - sliderHeight * 0.5;
    CGFloat maxY = guideCenterY + sliderHeight * 0.5;

    CGFloat positionY = VTMapValueFromRangeToNewRange(self.rawDuration, DURATION_MAX, DURATION_MIN, minY, maxY);
    
    [UIView animateWithDuration:0.1 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveLinear) animations:^{
        self.durationLabel.center = CGPointMake(CGRectGetMaxX(guideFrame) + CGRectGetWidth(self.durationLabel.bounds), positionY);
    } completion:NULL];
}

- (void)_updateDurationLabelTransform
{
    CGAffineTransform t = CGAffineTransformIdentity;
    if (self.isTouchingDurationSlider)
    {
        t = CGAffineTransformScale(t, 1.15, 1.15);
        t = CGAffineTransformTranslate(t, 5.0, 0.0);
    }
    
    [UIView animateWithDuration:0.18 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseOut) animations:^{
        self.durationLabel.transform = t;
    } completion:NULL];
}

@end
