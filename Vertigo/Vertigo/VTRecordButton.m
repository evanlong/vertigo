//
//  VTRecordButton.m
//  Vertigo
//
//  Created by Evan Long on 4/21/17.
//
//

#import "VTRecordButton.h"

#import "VTMath.h"

#define RECORD_BUTTON_DIMENSION     78.0
#define RECORD_BUTTON_INSET         8.0

@interface VTRecordButton ()

@property (nonatomic, strong) CAShapeLayer *recordLayer1;
@property (nonatomic, strong) CAShapeLayer *recordLayer2;

@end

@implementation VTRecordButton

#pragma mark - UIVIew

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowRadius = 2.0;
        self.layer.shadowOpacity = 0.75;
        self.layer.shadowOffset = CGSizeZero;

        _recordLayer1 = [CAShapeLayer layer];
        [self.layer addSublayer:_recordLayer1];
        
        _recordLayer2 = [CAShapeLayer layer];
        [self.layer addSublayer:_recordLayer2];
        
        [UIView performWithoutAnimation:^{
            [self _updateScale];
            [self _updateRecordingColors];
        }];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(RECORD_BUTTON_DIMENSION, RECORD_BUTTON_DIMENSION);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(RECORD_BUTTON_DIMENSION, RECORD_BUTTON_DIMENSION);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.recordLayer1.bounds = self.bounds;
    self.recordLayer1.position = VTRectMidPoint(self.bounds);
    self.recordLayer2.bounds = CGRectInset(self.bounds, RECORD_BUTTON_INSET, RECORD_BUTTON_INSET);
    self.recordLayer2.position = VTRectMidPoint(self.bounds);
    
    [self _updateRecordingShapePath];
}

#pragma mark - UIControl

- (void)setHighlighted:(BOOL)highlighted
{
    BOOL wasHighlighted = self.highlighted;
    
    [super setHighlighted:highlighted];
    
    if (wasHighlighted != highlighted)
    {
        [self _updateScale];
        [self _updateRecordingColors];
    }
}

#pragma mark - VTRecordButton

- (void)setRecording:(BOOL)recording
{
    if (_recording != recording)
    {
        _recording = recording;
        [self _updateRecordingShapePath];
    }
}

#pragma mark - Private

- (void)_updateRecordingColors
{
    if (self.isHighlighted)
    {
        self.recordLayer1.fillColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
        self.recordLayer2.fillColor = [UIColor redColor].CGColor;
    }
    else
    {
        self.recordLayer1.fillColor = [UIColor whiteColor].CGColor;
        self.recordLayer2.fillColor = [UIColor redColor].CGColor;
    }
}

- (void)_updateScale
{
    CGAffineTransform t = self.isHighlighted ? CGAffineTransformMakeScale(0.85, 0.85) : CGAffineTransformIdentity;
    [UIView animateWithDuration:0.2 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction) animations:^{
        self.transform = t;
    } completion:nil];
}

- (void)_updateRecordingShapePath
{
    UIBezierPath *path1 = nil;
    UIBezierPath *path2 = nil;
    CGRect bounds1 = self.recordLayer1.bounds;
    CGRect bounds2 = self.recordLayer2.bounds;
    if (self.isRecording)
    {
        path1 = [UIBezierPath bezierPathWithRoundedRect:bounds1 cornerRadius:6.0];
        path2 = [UIBezierPath bezierPathWithRoundedRect:bounds2 cornerRadius:6.0];
    }
    else
    {
        path1 = [UIBezierPath bezierPathWithRoundedRect:bounds1 cornerRadius:CGRectGetWidth(bounds1) / 2.0];
        path2 = [UIBezierPath bezierPathWithRoundedRect:bounds2 cornerRadius:CGRectGetWidth(bounds2) / 2.0];
    }

    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:VTKeyPath(self.recordLayer1, path)];
    animation1.duration = 0.1;
    [self.recordLayer1 addAnimation:animation1 forKey:@"VT-RecordButtonPath"];
    animation1.fromValue = (__bridge id _Nullable)(self.recordLayer1.path);
    self.recordLayer1.path = path1.CGPath;
    
    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:VTKeyPath(self.recordLayer2, path)];
    animation2.duration = 0.1;
    [self.recordLayer2 addAnimation:animation2 forKey:@"VT-RecordButtonPath"];
    animation2.fromValue = (__bridge id _Nullable)(self.recordLayer2.path);
    self.recordLayer2.path = path2.CGPath;
}

@end
