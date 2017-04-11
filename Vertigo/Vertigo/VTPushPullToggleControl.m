//
//  VTPushPullToggleControl.m
//  Vertigo
//
//  Created by Evan Long on 4/10/17.
//
//

#import "VTPushPullToggleControl.h"

@interface _VTArrowButton : UIControl

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithArrowName:(NSString *)arrowName NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign) CGSize maskImageSize;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIImageView *arrowView;

@end

@implementation _VTArrowButton

- (instancetype)initWithArrowName:(NSString *)arrowName
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        _blurView = [[UIVisualEffectView alloc] init];
        _blurView.userInteractionEnabled = NO;
        VTAllowAutolayoutForView(_blurView);
        [self addSubview:_blurView];

        UIImage *maskImage = [UIImage imageNamed:@"CircleMask"];
        _blurView.maskView = [[UIImageView alloc] initWithImage:maskImage];
        _maskImageSize = maskImage.size;

        _arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:arrowName]];
        _arrowView.userInteractionEnabled = NO;
        _arrowView.tintColor = [UIColor blackColor];
        VTAllowAutolayoutForView(_arrowView);
        [self addSubview:_arrowView];
        
        [_blurView.heightAnchor constraintEqualToAnchor:_arrowView.heightAnchor].active = YES;
        [_blurView.widthAnchor constraintEqualToAnchor:_arrowView.widthAnchor].active = YES;
        
        [_blurView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [_blurView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_arrowView.centerXAnchor constraintEqualToAnchor:_blurView.centerXAnchor].active = YES;
        [_arrowView.centerYAnchor constraintEqualToAnchor:_blurView.centerYAnchor].active = YES;
        
        [self _updateWithCurrentState];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return self.maskImageSize;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self _updateWithCurrentState];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self _updateWithCurrentState];
}

#pragma mark - Private

- (void)_updateWithCurrentState
{
    if (self.isSelected)
    {
        self.arrowView.tintColor = [UIColor blackColor];
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        self.transform = CGAffineTransformMakeScale(1.35, 1.35);
    }
    else if (self.isHighlighted)
    {
        self.arrowView.tintColor = [UIColor whiteColor];
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.transform = CGAffineTransformIdentity;
    }
    else
    {
        self.arrowView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.75];
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.transform = CGAffineTransformIdentity;
    }
}

@end


@interface VTPushPullToggleControl ()

@property (nonatomic, strong) _VTArrowButton *pushButton;
@property (nonatomic, strong) _VTArrowButton *pullButton;

@end

@implementation VTPushPullToggleControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _pushButton = [[_VTArrowButton alloc] initWithArrowName:@"PushIcon"];
        VTAllowAutolayoutForView(_pushButton);
        [self addSubview:_pushButton];
        
        _pullButton = [[_VTArrowButton alloc] initWithArrowName:@"PullIcon"];
        VTAllowAutolayoutForView(_pullButton);
        [self addSubview:_pullButton];
        
        [_pushButton addTarget:self action:@selector(_handlePushPressed) forControlEvents:UIControlEventTouchUpInside];
        [_pullButton addTarget:self action:@selector(_handlePullPressed) forControlEvents:UIControlEventTouchUpInside];
        
        [_pushButton.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        [_pushButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        
        [_pullButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [_pullButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        
        [self _updateButtons];
    }
    return self;
}

- (void)setDirection:(VTVertigoDirection)direction
{
    [self setDirection:direction animated:NO];
}

- (void)setDirection:(VTVertigoDirection)direction animated:(BOOL)animated
{
    if (_direction != direction)
    {
        _direction = direction;
        
        void(^animationBlock)(void) = ^{
            [self _updateButtons];
        };

        if (animated)
        {
            [UIView animateWithDuration:0.1 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction) animations:^{
                animationBlock();
            } completion:NULL];
        }
        else
        {
            animationBlock();
        }
        
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (CGSize)intrinsicContentSize
{
    CGSize pushButtonSize = [self.pushButton systemLayoutSizeFittingSize:CGSizeZero];
    CGSize pullButtonSize = [self.pullButton systemLayoutSizeFittingSize:CGSizeZero];
    
    CGSize resultSize;
    resultSize.width = MAX(pushButtonSize.width, pullButtonSize.width);
    resultSize.height = pushButtonSize.height + pullButtonSize.height + 30.0;
    return resultSize;
}

#pragma mark - Event Handlers

- (void)_handlePushPressed
{
    [self setDirection:VTVertigoDirectionPush animated:YES];
}

- (void)_handlePullPressed
{
    [self setDirection:VTVertigoDirectionPull animated:YES];
}

#pragma mark - Private

- (void)_updateButtons
{
    if (self.direction == VTVertigoDirectionPull)
    {
        self.pushButton.selected = NO;
        self.pullButton.selected = YES;
    }
    else
    {
        self.pushButton.selected = YES;
        self.pullButton.selected = NO;
    }
}

@end
