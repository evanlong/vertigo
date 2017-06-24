//
//  VTPieProgressView.m
//  Vertigo
//
//  Created by Evan Long on 6/22/17.
//
//

#import "VTPieProgressView.h"

#import "VTMath.h"

#define INTRINSIC_MARGIN            24.0
#define PIE_DIMENSION               100.0

@interface _VTPieView : UIView
@property (nonatomic, assign) float progress;
@end

@implementation _VTPieView

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    const CGFloat pathWidth = 2.0;
    const CGRect pathRect = CGRectInset(rect, pathWidth, pathWidth);
    
    const CGRect fillRect = CGRectInset(pathRect, 4.0, 4.0);
    const CGPoint midPoint = VTRectMidPoint(fillRect);
    const CGFloat radius = CGRectGetWidth(fillRect) / 2.0;
    
    [[UIColor colorWithWhite:0.9 alpha:0.06] set];
    UIBezierPath *fillShade = [UIBezierPath bezierPathWithOvalInRect:fillRect];
    [fillShade fill];

    [[UIColor whiteColor] set];
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithOvalInRect:pathRect];
    borderPath.lineWidth = pathWidth;
    [borderPath stroke];
    
    const CGFloat startAngle = -M_PI_2;
    const CGFloat endAngle = (2.0 * M_PI * self.progress) - M_PI_2;
    UIBezierPath *fillSolid = [UIBezierPath bezierPath];
    [fillSolid moveToPoint:midPoint];
    [fillSolid addArcWithCenter:midPoint radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    [fillSolid closePath];
    [fillSolid fill];
}

#pragma mark - _VTPieView

- (void)setProgress:(float)progress
{
    if (_progress != progress)
    {
        _progress = progress;
        [self setNeedsDisplay];
    }
}

@end

@interface VTPieProgressView ()

@property (nonatomic, strong) _VTPieView *filling;

@end

@implementation VTPieProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.85];
        self.layer.cornerRadius = 8.0;
        VTSetBorder(self, colorWithWhite:1.0 alpha:1.0, 1.0);
        
        _filling = [[_VTPieView alloc] init];
        VTAllowAutolayoutForView(_filling);
        [self addSubview:_filling];

        [_filling.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [_filling.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_filling.widthAnchor constraintEqualToConstant:PIE_DIMENSION].active = YES;
        [_filling.heightAnchor constraintEqualToConstant:PIE_DIMENSION].active = YES;
    }
    return self;
}

#pragma mark - UIView

- (CGSize)intrinsicContentSize
{
    return [self _computedSize];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return [self _computedSize];
}

#pragma mark - VTPieProgressView

- (void)setProgress:(float)progress
{
    if (_progress != progress)
    {
        _progress = progress;
        [self _updatePieChart];
    }
}

#pragma mark - Private

- (CGSize)_computedSize
{
    CGFloat dimension = 2.0 * INTRINSIC_MARGIN + PIE_DIMENSION;
    return CGSizeMake(dimension, dimension);
}

- (void)_updatePieChart
{
    self.filling.progress = self.progress;
}

@end
