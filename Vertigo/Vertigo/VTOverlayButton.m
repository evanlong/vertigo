//
//  VTArrowButton.m
//  Vertigo
//
//  Created by Evan Long on 6/21/17.
//
//

#import "VTOverlayButton.h"

@interface VTOverlayButton ()

@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIImageView *overlayImageView;
@property (nonatomic, strong) UIImageView *maskImageView;

@end

@implementation VTOverlayButton

- (instancetype)initWithOverlayImageName:(NSString *)imageName
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        _useBlurBackground = YES;

        _blurView = [[UIVisualEffectView alloc] init];
        _blurView.userInteractionEnabled = NO;
        VTAllowAutolayoutForView(_blurView);
        [self addSubview:_blurView];
        
        _overlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        _overlayImageView.userInteractionEnabled = NO;
        _overlayImageView.tintColor = [UIColor blackColor];
        VTAllowAutolayoutForView(_overlayImageView);
        [self addSubview:_overlayImageView];

        UIImage *maskImage = [[self class] _maskImageForSize:_overlayImageView.image.size];
        _maskImageView = [[UIImageView alloc] initWithImage:maskImage];
        if (VTOSAtLeast(10, 0, 0))
        {
            _blurView.maskView = _maskImageView;
        }
        else
        {
            _blurView.layer.mask = _maskImageView.layer;
        }

        [_blurView.heightAnchor constraintEqualToConstant:maskImage.size.height].active = YES;
        [_blurView.widthAnchor constraintEqualToConstant:maskImage.size.width].active = YES;
        
        [_blurView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [_blurView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_overlayImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [_overlayImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        
        [UIView performWithoutAnimation:^{
            [self _updateWithCurrentState];
        }];
        
        [self _updateBackground];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return self.overlayImageView.image.size;
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

#pragma mark - VTOverlayButton

- (void)setUseBlurBackground:(BOOL)useBlurBackground
{
    if (_useBlurBackground != useBlurBackground)
    {
        _useBlurBackground = useBlurBackground;
        [self _updateBackground];
    }
}

#pragma mark - Private

+ (UIImage *)_maskImageForSize:(CGSize)size
{
    static NSMutableDictionary<NSValue *, UIImage *> *maskImages;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        maskImages = [[NSMutableDictionary alloc] init];
    });
    
    size.width -= 2.0;
    size.height -= 2.0;
    
    NSValue *maskImageSizeValue = [NSValue valueWithCGSize:size];
    UIImage *maskImage = [maskImages objectForKey:maskImageSizeValue];
    if (!maskImage)
    {
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        {
            CGRect r = (CGRect){CGPointZero, size};
            UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:r];
            [[UIColor whiteColor] setFill];
            [path fill];
            maskImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
        
        if (maskImage)
        {
            [maskImages setObject:maskImage forKey:maskImageSizeValue];
        }
        else // fallback
        {
            maskImage = [UIImage imageNamed:@"CircleMask"];
        }
    }
    
    return maskImage;
}

- (void)_updateWithCurrentState
{
    CGAffineTransform transform;
    UIColor *tintColor;

    if (self.isSelected)
    {
        tintColor = [UIColor blackColor];
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        transform = CGAffineTransformMakeScale(1.35, 1.35);
    }
    else if (self.isHighlighted)
    {
        tintColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        transform = CGAffineTransformMakeScale(0.85, 0.85);
    }
    else
    {
        tintColor = [UIColor whiteColor];
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        transform = CGAffineTransformIdentity;
    }
    
    if (!self.useBlurBackground)
    {
        tintColor = [UIColor whiteColor];
    }

    [UIView animateWithDuration:0.2 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction) animations:^{
        self.overlayImageView.tintColor = tintColor;
        self.transform = transform;
    } completion:nil];
}

- (void)_updateBackground
{
    if (self.useBlurBackground)
    {
        self.blurView.hidden = NO;
        self.layer.shadowOpacity = 0.0;
    }
    else
    {
        self.blurView.hidden = YES;
        self.layer.shadowRadius = 2.0;
        self.layer.shadowOpacity = 0.75;
        self.layer.shadowOffset = CGSizeZero;
    }
}

@end
