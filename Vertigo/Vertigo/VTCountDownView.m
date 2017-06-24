//
//  VTCountDownView.m
//  Vertigo
//
//  Created by Evan Long on 4/11/17.
//
//

#import "VTCountDownView.h"

#import "VTMath.h"

@interface VTCountDownView ()

@property (nonatomic, assign) NSInteger startCount;
@property (nonatomic, assign) NSInteger currentCount;
@property (nonatomic, strong) NSTimer *countdownTimer;

@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, copy) VTCountDownCompletion completion;

@property (nonatomic, copy) NSString *labelText;

@end

@implementation VTCountDownView

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.userInteractionEnabled = NO;
        
        _startCount = 3;

        _numberLabel = [[UILabel alloc] init];
        _numberLabel.textColor = [UIColor whiteColor];
        _numberLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _numberLabel.layer.shadowRadius = 2.0;
        _numberLabel.layer.shadowOpacity = 0.75;
        _numberLabel.layer.shadowOffset = CGSizeZero;
        [self addSubview:_numberLabel];

        self.numberLabel.hidden = YES;
        self.labelText = @"0";
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.numberLabel sizeToFit];
    self.numberLabel.center = VTRectMidPoint(self.bounds);
}

- (CGSize)intrinsicContentSize
{
    [self.numberLabel sizeToFit];
    return self.numberLabel.bounds.size;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    [self.numberLabel sizeToFit];
    return self.numberLabel.bounds.size;
}

#pragma mark - VTCountDownView

- (void)startWithCompletion:(VTCountDownCompletion)completion
{
    if (self.countdownTimer)
    {
        [self stop];
    }
    
    self.completion = completion;
    self.numberLabel.hidden = NO;
    self.currentCount = self.startCount;

    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:0.83 target:self selector:@selector(_update) userInfo:nil repeats:YES];
    [self _update];
}

- (void)stop
{
    BOOL finished = (self.countdownTimer == nil);

    self.numberLabel.hidden = YES;
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
    
    if (self.completion)
    {
        self.completion(finished);
        self.completion = NULL;
    }
}

#pragma mark - Private

- (NSString *)labelText
{
    return self.numberLabel.attributedText.string;
}

- (void)setLabelText:(NSString *)labelText
{
    NSDictionary *attributes = @{NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSStrokeColorAttributeName : [UIColor colorWithWhite:0.0 alpha:0.5],
                                 NSStrokeWidthAttributeName : @(-1.0),
                                 NSFontAttributeName : [UIFont monospacedDigitSystemFontOfSize:64.0 weight:UIFontWeightBold]};
    self.numberLabel.attributedText = [[NSAttributedString alloc] initWithString:labelText attributes:attributes];

    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)_update
{
    if (self.currentCount == 0)
    {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
        [self stop];
    }
    else
    {
        self.labelText = [NSNumberFormatter localizedStringFromNumber:@(self.currentCount) numberStyle:NSNumberFormatterNoStyle];
        self.currentCount -= 1;
    }
}

@end
