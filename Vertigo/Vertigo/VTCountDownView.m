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
        _numberLabel.font = [UIFont monospacedDigitSystemFontOfSize:64.0 weight:UIFontWeightBold];
        _numberLabel.text = @"1";
        _numberLabel.textColor = [UIColor whiteColor];
        [self addSubview:_numberLabel];
        [_numberLabel sizeToFit];
        // EL NOTE: I've effectively hardcoded the size of this view to be a single digit by sizing it all to the _numberLabel
        // Keeps things simple for now
        self.numberLabel.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.numberLabel.center = VTRectMidPoint(self.bounds);
}

- (CGSize)intrinsicContentSize
{
    return self.numberLabel.bounds.size;
}

- (CGSize)sizeThatFits:(CGSize)size
{
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

    __weak typeof(self) weakSelf = self;
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:0.83 repeats:YES block:^(NSTimer *_Nonnull timer) {
        [weakSelf _update];
    }];
    [self _update];
}

- (void)stop
{
    BOOL finished = (self.countdownTimer == nil);

    self.numberLabel.hidden = YES;
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
    
    [self _notifyCompletion:finished];
}

#pragma mark - Private

- (void)_notifyCompletion:(BOOL)finished
{
    if (self.completion)
    {
        self.completion(finished);
        self.completion = NULL;
    }
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
        self.numberLabel.text = [NSNumberFormatter localizedStringFromNumber:@(self.currentCount) numberStyle:NSNumberFormatterNoStyle];
        self.currentCount -= 1;
    }
}

@end
