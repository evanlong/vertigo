//
//  VTPushPullToggleControl.m
//  Vertigo
//
//  Created by Evan Long on 4/10/17.
//
//

#import "VTPushPullToggleControl.h"

#import "VTOverlayButton.h"

@interface VTPushPullToggleControl ()

@property (nonatomic, strong) VTOverlayButton *pushButton;
@property (nonatomic, strong) VTOverlayButton *pullButton;

@end

@implementation VTPushPullToggleControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _pushButton = [[VTOverlayButton alloc] initWithOverlayImageName:@"PushIcon"];
        VTAllowAutolayoutForView(_pushButton);
        [self addSubview:_pushButton];
        
        _pullButton = [[VTOverlayButton alloc] initWithOverlayImageName:@"PullIcon"];
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
            } completion:nil];
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
