//
//  VTCameraControlView.m
//  Vertigo
//
//  Created by Evan Long on 3/22/17.
//
//

#import "VTCameraControlView.h"

#import "VTMath.h"
#import "VTOverlayButton.h"
#import "VTRecordButton.h"

#import "UIView+VTUtil.h"

#define DURATION_MIN                        1.0
#define DURATION_MAX                        5.0

#define DURATION_SLIDER_HEIGHT_MULTIPLIER   0.9

@interface VTCameraControlView ()

// Data
@property (nonatomic, readwrite, assign) NSTimeInterval duration;
@property (nonatomic, readonly, assign) NSTimeInterval rawDuration;

// Controls
@property (nonatomic, strong) UISlider *durationSlider;
@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) VTOverlayButton *helpButton;
@property (nonatomic, strong) VTRecordButton *recordButton;
@property (nonatomic, strong) UILabel *durationLabel;

@property (nonatomic, strong) UILayoutGuide *backdropSpaceGuide;

@property (nonatomic, assign, getter=isTouchingDurationSlider) BOOL touchingDurationSlider;

@property (nonatomic, strong) NSArray *portraitConstraints;
@property (nonatomic, strong) NSArray *landscapeLeftConstraints;
@property (nonatomic, strong) NSArray *landscapeRightConstraints;

@end

@implementation VTCameraControlView
{
    struct {
        unsigned int delegateDidPressRecordButton:1;
        unsigned int delegateDidPressHelpButton:1;
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

        NSMutableArray *portraitConstraints = [NSMutableArray array];
        NSMutableArray *landscapeLeftConstraints = [NSMutableArray array];
        NSMutableArray *landscapeRightConstraints = [NSMutableArray array];
        
        { // Record
            _recordButton = [[VTRecordButton alloc] init];
            VTAllowAutolayoutForView(_recordButton);
            [self addSubview:_recordButton];
            
            [_recordButton addTarget:self action:@selector(_handleRecordButtonPress) forControlEvents:UIControlEventTouchUpInside];
            
            [portraitConstraints addObjectsFromArray:@[[_recordButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                                                       [_recordButton.centerYAnchor constraintEqualToAnchor:self.bottomAnchor constant:-54.0]]];

            [landscapeLeftConstraints addObjectsFromArray:@[[_recordButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                                                            [_recordButton.centerXAnchor constraintEqualToAnchor:self.rightAnchor constant:-54.0]]];
            
            [landscapeRightConstraints addObjectsFromArray:@[[_recordButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                                                             [_recordButton.centerXAnchor constraintEqualToAnchor:self.leftAnchor constant:54.0]]];
        }
        
        { // Help
            _helpButton = [[VTOverlayButton alloc] initWithOverlayImageName:@"HelpIcon"];
            VTAllowAutolayoutForView(_helpButton);
            [self addSubview:_helpButton];
            
            [_helpButton addTarget:self action:@selector(_handleHelpButtonPress) forControlEvents:UIControlEventTouchUpInside];
            
            [portraitConstraints addObjectsFromArray:@[[_helpButton.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:24.0],
                                                       [_helpButton.centerYAnchor constraintEqualToAnchor:_recordButton.centerYAnchor],
                                                       ]];
            
            [landscapeLeftConstraints addObjectsFromArray:@[[_helpButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-24.0],
                                                            [_helpButton.centerXAnchor constraintEqualToAnchor:_recordButton.centerXAnchor],
                                                            ]];
            
            [landscapeRightConstraints addObjectsFromArray:@[[_helpButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:24.0],
                                                             [_helpButton.centerXAnchor constraintEqualToAnchor:_recordButton.centerXAnchor],
                                                             ]];
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
            VTAllowAutolayoutForView(_durationSlider);
            _durationSlider.layer.shadowColor = [UIColor blackColor].CGColor;
            _durationSlider.layer.shadowRadius = 2.0;
            _durationSlider.layer.shadowOpacity = 0.75;
            _durationSlider.layer.shadowOffset = CGSizeZero;
            _durationSlider.minimumValue = DURATION_MIN;
            _durationSlider.maximumValue = DURATION_MAX;
            _durationSlider.minimumTrackTintColor = [UIColor whiteColor];
            _durationSlider.maximumTrackTintColor = [UIColor whiteColor];
            _durationSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
            [self addSubview:_durationSlider];
            
            [_durationSlider addTarget:self action:@selector(_handleDurationSliderChange) forControlEvents:UIControlEventValueChanged];
            [_durationSlider addTarget:self action:@selector(_handleDurationSliderTouchDown) forControlEvents:UIControlEventTouchDown];
            [_durationSlider addTarget:self action:@selector(_handleDurationSliderClear) forControlEvents:(UIControlEventTouchCancel | UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
            
            _backdropSpaceGuide = [[UILayoutGuide alloc] init];
            [self addLayoutGuide:_backdropSpaceGuide];

            // backdropSpaceGuide guide height and centerY represent the area between the backdrop and bottom host views
            [portraitConstraints addObjectsFromArray:@[[_backdropSpaceGuide.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                       [_backdropSpaceGuide.bottomAnchor constraintEqualToAnchor:_recordButton.topAnchor],
                                                       [_durationSlider.centerXAnchor constraintEqualToAnchor:self.rightAnchor constant:-40.0],
                                                       ]];

            [landscapeLeftConstraints addObjectsFromArray:@[[_backdropSpaceGuide.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                            [_backdropSpaceGuide.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                                            [_durationSlider.centerXAnchor constraintEqualToAnchor:self.leftAnchor constant:40.0],
                                                            ]];
            
            [landscapeRightConstraints addObjectsFromArray:@[[_backdropSpaceGuide.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                             [_backdropSpaceGuide.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                                             [_durationSlider.centerXAnchor constraintEqualToAnchor:self.rightAnchor constant:-40.0],
                                                             ]];

            [_backdropSpaceGuide.leftAnchor constraintEqualToAnchor:_durationSlider.centerXAnchor].active = YES;
            [_durationSlider.centerYAnchor constraintEqualToAnchor:_backdropSpaceGuide.centerYAnchor].active = YES;
            [_durationSlider.widthAnchor constraintEqualToAnchor:_backdropSpaceGuide.heightAnchor multiplier:DURATION_SLIDER_HEIGHT_MULTIPLIER].active = YES;

            // Duration Label
            _durationLabel = [[UILabel alloc] init];
            _durationLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            _durationLabel.layer.shadowRadius = 2.0;
            _durationLabel.layer.shadowOpacity = 1.0;
            _durationLabel.layer.shadowOffset = CGSizeZero;
            _durationLabel.textAlignment = NSTextAlignmentCenter;
            [self addSubview:_durationLabel];
        }

        self.portraitConstraints = portraitConstraints;
        self.landscapeLeftConstraints = landscapeLeftConstraints;
        self.landscapeRightConstraints = landscapeRightConstraints;
        
        { // Configure Default Property and View State
            _recording = NO;
            _pushedZoomLevel = 1.0;
            _pulledZoomLevel = 2.0;
            _percentComplete = 0.0;

            [UIView performWithoutAnimation:^{
                self.duration = 3.0;
                [self _updateViewRecordingState];
                [self _updateProgress];
                [self _updateLayoutForCurrentOrientation];
                [self _updateDurationLabelTransform];
            }];
        }
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self _updateLayoutForCurrentOrientation];
    [UIView performWithoutAnimation:^{
        [self _updateDurationLabelPosition];
    }];
    
#if 0
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIImage *i = [self renderedAsImage];
        NSString *f = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cam_control_view_screenshot.png"];
        [UIImagePNGRepresentation(i) writeToFile:f atomically:YES];
    });
#endif
}

#pragma mark - VTCameraControlView

- (void)setDelegate:(id<VTCameraControlViewDelegate>)delegate   
{
    if (_delegate != delegate)
    {
        _delegate = delegate;
        _flags.delegateDidPressRecordButton = [delegate respondsToSelector:@selector(cameraControlViewDidPressRecordButton:)];
        _flags.delegateDidPressHelpButton = [delegate respondsToSelector:@selector(cameraControlViewDidPressHelpButton:)];
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

- (void)setOrientation:(VTCameraControlViewOrientation)orientation
{
    if (_orientation != orientation)
    {
        _orientation = orientation;
        [self _updateLayoutForCurrentOrientation];
        [self _updateDurationLabelPosition];
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

- (void)_handleHelpButtonPress
{
    if (_flags.delegateDidPressHelpButton)
    {
        [self.delegate cameraControlViewDidPressHelpButton:self];
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
            self.durationLabel.alpha = 0.0;
            self.durationSlider.alpha = 0.0;
            self.helpButton.alpha = 0.0;
        }
        else
        {
            self.durationLabel.alpha = 1.0;
            self.durationSlider.alpha = 1.0;
            self.helpButton.alpha = 1.0;
        }
    } completion:nil];
    
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

    CGFloat xOffset = ((self.orientation == VTCameraControlViewOrientationLandscapeLeft) ? 1.0 : -1.0) * CGRectGetWidth(self.durationLabel.bounds);
    CGFloat positionX = CGRectGetMaxX(guideFrame) + xOffset;
    CGFloat positionY = VTMapValueFromRangeToNewRange(self.rawDuration, DURATION_MAX, DURATION_MIN, minY, maxY);
    
    [UIView animateWithDuration:0.1 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveLinear) animations:^{
        self.durationLabel.center = CGPointMake(positionX, positionY);
    } completion:nil];
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
    } completion:nil];
}

- (void)_updateLayoutForCurrentOrientation
{
    if (self.orientation == VTCameraControlViewOrientationPortrait)
    {
        [NSLayoutConstraint deactivateConstraints:self.landscapeLeftConstraints];
        [NSLayoutConstraint deactivateConstraints:self.landscapeRightConstraints];
        [NSLayoutConstraint activateConstraints:self.portraitConstraints];
    }
    else if (self.orientation == VTCameraControlViewOrientationLandscapeLeft)
    {
        [NSLayoutConstraint deactivateConstraints:self.landscapeRightConstraints];
        [NSLayoutConstraint deactivateConstraints:self.portraitConstraints];
        [NSLayoutConstraint activateConstraints:self.landscapeLeftConstraints];
    }
    else // VTCameraControlViewOrientationLandscapeRight
    {
        [NSLayoutConstraint deactivateConstraints:self.landscapeLeftConstraints];
        [NSLayoutConstraint deactivateConstraints:self.portraitConstraints];
        [NSLayoutConstraint activateConstraints:self.landscapeRightConstraints];
    }
}

@end
