//
//  VTCameraControlView.m
//  Vertigo
//
//  Created by Evan Long on 3/22/17.
//
//

#import "VTCameraControlView.h"

#import "VTToggleButton.h"

#define CONTROL_BACKDROP_COLOR          [UIColor colorWithWhite:0.1 alpha:0.70]

@interface VTCameraControlView ()

@property (nonatomic, strong) UIView *pushPullControlBackdrop;
@property (nonatomic, strong) UISegmentedControl *pushPullControl;

@property (nonatomic, strong) UIView *pushedZoomLevelView;
@property (nonatomic, strong) UIView *pushPullIndicatorArrow;
@property (nonatomic, strong) UIView *pulledZoomLevelView;

@property (nonatomic, strong) UIView *bottomViewHost;
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) VTToggleButton *durationToggleButton;
@property (nonatomic, strong) UIView *loopToggleView;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *durationToggleItemToValue;

@end

@implementation VTCameraControlView
{
    struct {
        unsigned int delegateDidPressRecordButton:1;
    } _flags;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.tintColor = [UIColor whiteColor];

        { // Top Controls
            _pushPullControlBackdrop = [[UIView alloc] init];
            VTAllowAutolayoutForView(self.pushPullControlBackdrop);
            self.pushPullControlBackdrop.backgroundColor = CONTROL_BACKDROP_COLOR;
            [self addSubview:self.pushPullControlBackdrop];
            
            NSArray *pushPullItems = @[NSLocalizedString(@"SegmentPush", nil), NSLocalizedString(@"SegmentPull", nil)];
            _pushPullControl = [[UISegmentedControl alloc] initWithItems:pushPullItems];
            _pushPullControl.selectedSegmentIndex = 0;
            VTAllowAutolayoutForView(_pushPullControl);
            [_pushPullControlBackdrop addSubview:_pushPullControl];
            
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
            _durationToggleButton = [[VTToggleButton alloc] init];
            VTAllowAutolayoutForView(_durationToggleButton);
            [_bottomViewHost addSubview:_durationToggleButton];
            
            [_durationToggleButton.rightAnchor constraintEqualToAnchor:_recordButton.leftAnchor constant:-40.0].active = YES;
            [_durationToggleButton.centerYAnchor constraintEqualToAnchor:_bottomViewHost.centerYAnchor].active = YES;
            [_durationToggleButton.widthAnchor constraintEqualToConstant:30.0].active = YES;
            [_durationToggleButton.heightAnchor constraintEqualToConstant:30.0].active = YES;
            
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
        
        { // Configure Default Property and View State
            _recording = NO;
            
            _durationToggleItemToValue = [[NSMutableDictionary alloc] init];
            NSMutableArray<NSString *> *items = [NSMutableArray array];
            for (VTRecordDuration duration = VTRecordDuration1Second; duration < VTRecordDurationLast; duration++)
            {
                NSString *title = [NSString stringWithFormat:NSLocalizedString(@"DurationToggleSeconds", nil), duration];
                [items addObject:title];
                [_durationToggleItemToValue setObject:@(duration) forKey:title];
            }
            _durationToggleButton.items = items;

            _shouldLoop = NO;
            _pushedZoomLevel = 1.0;
            _pulledZoomLevel = 2.0;

            // EL TODO: A better pattern is to "update" our controls for our property values. That way it's the same code when
            // or if the properties become readwrite. And various properties will influence various controls
        }
    }
    return self;
}

- (void)setDelegate:(id<VTCameraControlViewDelegate>)delegate
{
    if (_delegate != delegate)
    {
        _delegate = delegate;
        _flags.delegateDidPressRecordButton = [delegate respondsToSelector:@selector(didPressRecordButton:)];
    }
}

- (void)setRecording:(BOOL)recording
{
    if (_recording != recording)
    {
        _recording = recording;
        [self _updateRecordButton];
    }
}

- (VTRecordDirection)direction
{
    return (VTRecordDirection)self.pushPullControl.selectedSegmentIndex;
}

- (VTRecordDuration)duration
{
    VTRecordDuration duration = VTRecordDuration1Second;
    NSString *currentItem = self.durationToggleButton.currentItem;
    if (currentItem)
    {
        duration = (VTRecordDuration)[[self.durationToggleItemToValue objectForKey:currentItem] integerValue];
    }
    return duration;
}

#pragma mark - Events

- (void)_handleRecordButtonPress
{
    if (_flags.delegateDidPressRecordButton)
    {
        [self.delegate didPressRecordButton:self];
    }
}

#pragma mark - Private

- (void)_updateRecordButton
{
    if (self.isRecording)
    {
        [self.recordButton setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else
    {
        [self.recordButton setTitle:@"" forState:UIControlStateNormal];
    }
}

@end
