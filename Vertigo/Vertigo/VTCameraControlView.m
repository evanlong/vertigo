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
#import "VTRecordButton.h"

#define DURATION_MIN                        1.0
#define DURATION_MAX                        8.0

#define DURATION_SLIDER_HEIGHT_MULTIPLIER   0.9

@interface VTCameraControlView ()

// Data
@property (nonatomic, readwrite, assign) NSTimeInterval duration;
@property (nonatomic, readonly, assign) NSTimeInterval rawDuration;

// Controls
@property (nonatomic, strong) VTPushPullToggleControl *pushPullToggleControl;
@property (nonatomic, strong) UISlider *durationSlider;
@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) VTRecordButton *recordButton;
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
        
        { // Record
            _recordButton = [[VTRecordButton alloc] init];
            VTAllowAutolayoutForView(_recordButton);
            [self addSubview:_recordButton];
            
            [_recordButton addTarget:self action:@selector(_handleRecordButtonPress) forControlEvents:UIControlEventTouchUpInside];
            
            [_recordButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            [_recordButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-20.0].active = YES;
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
            _durationSlider.layer.shadowOffset = CGSizeZero;
            _durationSlider.minimumValue = DURATION_MIN;
            _durationSlider.maximumValue = DURATION_MAX;
            _durationSlider.minimumTrackTintColor = [UIColor whiteColor];
            _durationSlider.maximumTrackTintColor = [UIColor whiteColor];
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
            [_backdropSpaceGuide.bottomAnchor constraintEqualToAnchor:_recordButton.topAnchor].active = YES;
            [_backdropSpaceGuide.leftAnchor constraintEqualToAnchor:_durationSlider.centerXAnchor].active = YES;

            [_durationSlider.centerXAnchor constraintEqualToAnchor:self.rightAnchor constant:-40.0].active = YES;
            [_durationSlider.centerYAnchor constraintEqualToAnchor:_backdropSpaceGuide.centerYAnchor].active = YES;
            [_durationSlider.widthAnchor constraintEqualToAnchor:_backdropSpaceGuide.heightAnchor multiplier:DURATION_SLIDER_HEIGHT_MULTIPLIER].active = YES;
            _durationSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
            
            // Duration Label
            _durationLabel = [[UILabel alloc] init];
            _durationLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            _durationLabel.layer.shadowRadius = 2.0;
            _durationLabel.layer.shadowOpacity = 1.0;
            _durationLabel.layer.shadowOffset = CGSizeZero;
            _durationLabel.textAlignment = NSTextAlignmentCenter;
            [self addSubview:_durationLabel];
        }
        
        { // Push/Pull Buttons
            _pushPullToggleControl = [[VTPushPullToggleControl alloc] init];
            _pushPullToggleControl.hidden = YES;
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
    [UIView animateWithDuration:0.2 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction) animations:^{
        if (self.isRecording)
        {
            self.pushPullToggleControl.alpha = 0.0;
            self.durationLabel.alpha = 0.0;
            self.durationSlider.alpha = 0.0;
        }
        else
        {
            self.pushPullToggleControl.alpha = 1.0;
            self.durationLabel.alpha = 1.0;
            self.durationSlider.alpha = 1.0;
        }
    } completion:NULL];
    
    if (self.isRecording)
    {
        self.progressView.hidden = NO;
    }
    else
    {
        self.progressView.hidden = YES;
    }
    
    self.recordButton.recording = self.isRecording;
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
        self.durationLabel.center = CGPointMake(CGRectGetMaxX(guideFrame) - CGRectGetWidth(self.durationLabel.bounds), positionY);
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
