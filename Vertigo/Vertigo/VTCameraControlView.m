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

@property (nonatomic, strong) NSMutableDictionary<VTToggleButtonItem *, NSNumber *> *durationToggleItemToValue;

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
            self.pushPullControl.selectedSegmentIndex = 0;
            VTAllowAutolayoutForView(self.pushPullControl);
            [self.pushPullControlBackdrop addSubview:self.pushPullControl];
            
            [self.pushPullControl.centerXAnchor constraintEqualToAnchor:self.pushPullControlBackdrop.centerXAnchor].active = YES;
            [self.pushPullControl.centerYAnchor constraintEqualToAnchor:self.pushPullControlBackdrop.centerYAnchor].active = YES;
            [self.pushPullControlBackdrop.heightAnchor constraintEqualToAnchor:self.pushPullControl.heightAnchor constant:16.0].active = YES;
            [self.pushPullControlBackdrop.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
            
            [self.pushPullControlBackdrop.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            [self.pushPullControlBackdrop.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        }
    
        { // Bottom Controls
            _bottomViewHost = [[UIView alloc] init];
            VTAllowAutolayoutForView(self.bottomViewHost);
            self.bottomViewHost.backgroundColor = CONTROL_BACKDROP_COLOR;
            [self addSubview:self.bottomViewHost];
            
            [self.bottomViewHost.heightAnchor constraintEqualToConstant:70.0].active = YES;
            [self.bottomViewHost.widthAnchor constraintEqualToAnchor:self.pushPullControlBackdrop.widthAnchor].active = YES;
            [self.bottomViewHost.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            [self.bottomViewHost.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            
            // Record
            _recordButton = [[UIButton alloc] init];
            VTAllowAutolayoutForView(self.recordButton);
            self.recordButton.backgroundColor = [UIColor redColor];
            [self.bottomViewHost addSubview:self.recordButton];
            
            [self.recordButton addTarget:self action:@selector(_handleRecordButtonPress) forControlEvents:UIControlEventTouchUpInside];
            
            [self.recordButton.centerXAnchor constraintEqualToAnchor:self.bottomViewHost.centerXAnchor].active = YES;
            [self.recordButton.centerYAnchor constraintEqualToAnchor:self.bottomViewHost.centerYAnchor].active = YES;
            [self.recordButton.widthAnchor constraintEqualToConstant:50.0].active = YES;
            [self.recordButton.heightAnchor constraintEqualToConstant:50.0].active = YES;
            
            // Duration Toggle
            _durationToggleButton = [[VTToggleButton alloc] init];
            VTAllowAutolayoutForView(self.durationToggleButton);
            [self.bottomViewHost addSubview:self.durationToggleButton];
            
            [self.durationToggleButton.rightAnchor constraintEqualToAnchor:self.recordButton.leftAnchor constant:-40.0].active = YES;
            [self.durationToggleButton.centerYAnchor constraintEqualToAnchor:self.bottomViewHost.centerYAnchor].active = YES;
            [self.durationToggleButton.widthAnchor constraintEqualToConstant:30.0].active = YES;
            [self.durationToggleButton.heightAnchor constraintEqualToConstant:30.0].active = YES;
            
            // Loop Toggle
            _loopToggleView = [[UIView alloc] init];
            self.loopToggleView.hidden = YES; // EL TODO: add back when needed
            VTAllowAutolayoutForView(self.loopToggleView);
            self.loopToggleView.backgroundColor = [UIColor blueColor];
            [self.bottomViewHost addSubview:self.loopToggleView];
            
            [self.loopToggleView.leftAnchor constraintEqualToAnchor:self.recordButton.rightAnchor constant:40.0].active = YES;
            [self.loopToggleView.centerYAnchor constraintEqualToAnchor:self.bottomViewHost.centerYAnchor].active = YES;
            [self.loopToggleView.widthAnchor constraintEqualToConstant:30.0].active = YES;
            [self.loopToggleView.heightAnchor constraintEqualToConstant:30.0].active = YES;
        }
        
        { // Configure Default Property and View State
            _recording = NO;
            
            _durationToggleItemToValue = [[NSMutableDictionary alloc] init];
            NSMutableArray<VTToggleButtonItem *> *items = [NSMutableArray array];
            for (VTRecordDuration duration = VTRecordDuration1Second; duration < VTRecordDurationLast; duration++)
            {
                NSString *title = [NSString stringWithFormat:NSLocalizedString(@"DurationToggleSeconds", nil), duration];
                VTToggleButtonItem *toggleItem = [VTToggleButtonItem toggleButtonItemWithTitle:title];
                [items addObject:toggleItem];
                [self.durationToggleItemToValue setObject:@(duration) forKey:toggleItem];
            }
            self.durationToggleButton.items = items;
            
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
    VTToggleButtonItem *currentItem = self.durationToggleButton.currentItem;
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
