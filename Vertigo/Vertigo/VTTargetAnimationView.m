//
//  VTTargetAnimationView.m
//
//  Code generated using QuartzCode 1.56.0 on 6/28/17.
//  www.quartzcodeapp.com
//

#import "VTTargetAnimationView.h"
#import "QCMethod.h"

@interface VTTargetAnimationView () <CAAnimationDelegate>

@property (nonatomic, strong) NSMutableDictionary * layers;
@property (nonatomic, strong) NSMapTable * completionBlocks;
@property (nonatomic, assign) BOOL  updateLayerValueForCompletedAnimation;


@end

@implementation VTTargetAnimationView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupProperties];
        [self setupLayers];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupProperties];
        [self setupLayers];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(36.0, 36.0);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(36.0, 36.0);
}

- (void)setupProperties{
    self.completionBlocks = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaqueMemory valueOptions:NSPointerFunctionsStrongMemory];;
    self.layers = [NSMutableDictionary dictionary];
    
}

- (void)setupLayers{
    self.backgroundColor = [UIColor colorWithRed:1 green: 0 blue:1 alpha:0];
    
    CAShapeLayer * vertigoObject = [CAShapeLayer layer];
    vertigoObject.frame = CGRectMake(3, 3, 30, 30);
    vertigoObject.path = [self vertigoObjectPath].CGPath;
    [self.layer addSublayer:vertigoObject];
    self.layers[@"vertigoObject"] = vertigoObject;
    
    [self resetLayerPropertiesForLayerIdentifiers:nil];
}

- (void)resetLayerPropertiesForLayerIdentifiers:(NSArray *)layerIds{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if(!layerIds || [layerIds containsObject:@"vertigoObject"]){
        CAShapeLayer * vertigoObject = self.layers[@"vertigoObject"];
        vertigoObject.lineCap         = kCALineCapRound;
        vertigoObject.fillColor       = [UIColor colorWithRed:0.839 green: 0.839 blue:0.839 alpha:1].CGColor;
        vertigoObject.strokeColor     = [UIColor whiteColor].CGColor;
        vertigoObject.lineWidth       = 2;
        vertigoObject.lineDashPattern = @[@1, @5];
        vertigoObject.shadowColor     = [UIColor blackColor].CGColor;
        vertigoObject.shadowOpacity = 1;
        vertigoObject.shadowOffset  = CGSizeMake(0, -0);
        vertigoObject.shadowRadius  = 2;
    }
    
    [CATransaction commit];
}

#pragma mark - Animation Setup

- (void)addBorderAnimation{
    NSString * fillMode = kCAFillModeForwards;
    
    ////An infinity animation
    
    ////VertigoObject animation
    CABasicAnimation * vertigoObjectLineDashPhaseAnim = [CABasicAnimation animationWithKeyPath:@"lineDashPhase"];
    vertigoObjectLineDashPhaseAnim.fromValue = @0;
    vertigoObjectLineDashPhaseAnim.toValue = @6;
    vertigoObjectLineDashPhaseAnim.duration = 2;
    vertigoObjectLineDashPhaseAnim.repeatCount = INFINITY;
    
    CAAnimationGroup * vertigoObjectBorderAnim = [QCMethod groupAnimations:@[vertigoObjectLineDashPhaseAnim] fillMode:fillMode];
    [self.layers[@"vertigoObject"] addAnimation:vertigoObjectBorderAnim forKey:@"vertigoObjectBorderAnim"];
}

#pragma mark - Animation Cleanup

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    void (^completionBlock)(BOOL) = [self.completionBlocks objectForKey:anim];;
    if (completionBlock){
        [self.completionBlocks removeObjectForKey:anim];
        if ((flag && self.updateLayerValueForCompletedAnimation) || [[anim valueForKey:@"needEndAnim"] boolValue]){
            [self updateLayerValuesForAnimationId:[anim valueForKey:@"animId"]];
            [self removeAnimationsForAnimationId:[anim valueForKey:@"animId"]];
        }
        completionBlock(flag);
    }
}

- (void)updateLayerValuesForAnimationId:(NSString *)identifier{
    if([identifier isEqualToString:@"border"]){
        [QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"vertigoObject"] animationForKey:@"vertigoObjectBorderAnim"] theLayer:self.layers[@"vertigoObject"]];
    }
}

- (void)removeAnimationsForAnimationId:(NSString *)identifier{
    if([identifier isEqualToString:@"border"]){
        [self.layers[@"vertigoObject"] removeAnimationForKey:@"vertigoObjectBorderAnim"];
    }
}

- (void)removeAllAnimations{
    [self.layers enumerateKeysAndObjectsUsingBlock:^(id key, CALayer *layer, BOOL *stop) {
        [layer removeAllAnimations];
    }];
}

#pragma mark - Bezier Path

- (UIBezierPath*)vertigoObjectPath{
    UIBezierPath *vertigoObjectPath = [UIBezierPath bezierPath];
    [vertigoObjectPath moveToPoint:CGPointMake(15, 0)];
    [vertigoObjectPath addLineToPoint:CGPointMake(0, 11.459)];
    [vertigoObjectPath addLineToPoint:CGPointMake(5.729, 30)];
    [vertigoObjectPath addLineToPoint:CGPointMake(24.271, 30)];
    [vertigoObjectPath addLineToPoint:CGPointMake(30, 11.459)];
    [vertigoObjectPath closePath];
    [vertigoObjectPath moveToPoint:CGPointMake(15, 0)];
    
    return vertigoObjectPath;
}


@end
