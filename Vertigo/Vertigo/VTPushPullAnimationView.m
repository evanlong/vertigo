//
//  VTPushPullAnimationView.m
//
//  Code generated using QuartzCode 1.56.0 on 6/26/17.
//  www.quartzcodeapp.com
//

#import "VTPushPullAnimationView.h"
#import "QCMethod.h"

@interface VTPushPullAnimationView () <CAAnimationDelegate>

@property (nonatomic, strong) NSMutableDictionary * layers;
@property (nonatomic, strong) NSMapTable * completionBlocks;
@property (nonatomic, assign) BOOL  updateLayerValueForCompletedAnimation;


@end

@implementation VTPushPullAnimationView

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
    return CGSizeMake(100.0, 300.0);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(100.0, 300.0);
}

- (void)setupProperties{
    self.completionBlocks = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaqueMemory valueOptions:NSPointerFunctionsStrongMemory];;
    self.layers = [NSMutableDictionary dictionary];
    
}

- (void)setupLayers{
    self.backgroundColor = [UIColor colorWithRed:1 green: 1 blue:1 alpha:0];
    
    CALayer * camera = [CALayer layer];
    camera.frame = CGRectMake(5, 4, 90, 108);
    [self.layer addSublayer:camera];
    self.layers[@"camera"] = camera;
    {
        CALayer * cameraZoom = [CALayer layer];
        cameraZoom.frame = CGRectMake(0, 0, 90, 60);
        [camera addSublayer:cameraZoom];
        self.layers[@"cameraZoom"] = cameraZoom;
        {
            CAShapeLayer * left = [CAShapeLayer layer];
            left.frame = CGRectMake(0, 0, 40, 60);
            left.path = [self leftPath].CGPath;
            [cameraZoom addSublayer:left];
            self.layers[@"left"] = left;
            CAShapeLayer * right = [CAShapeLayer layer];
            right.frame = CGRectMake(50, 0, 40, 60);
            right.path = [self rightPath].CGPath;
            [cameraZoom addSublayer:right];
            self.layers[@"right"] = right;
        }
        
        CALayer * cameraBody = [CALayer layer];
        cameraBody.frame = CGRectMake(15, 63, 60, 45);
        [camera addSublayer:cameraBody];
        self.layers[@"cameraBody"] = cameraBody;
        {
            CAShapeLayer * cameraFrame = [CAShapeLayer layer];
            cameraFrame.frame = CGRectMake(0, 15, 60, 30);
            cameraFrame.path = [self cameraFramePath].CGPath;
            [cameraBody addSublayer:cameraFrame];
            self.layers[@"cameraFrame"] = cameraFrame;
            CAShapeLayer * cameraLens = [CAShapeLayer layer];
            cameraLens.frame = CGRectMake(15, 0, 30, 15);
            cameraLens.path = [self cameraLensPath].CGPath;
            [cameraBody addSublayer:cameraLens];
            self.layers[@"cameraLens"] = cameraLens;
        }
        
        CALayer * cameraRecording = [CALayer layer];
        cameraRecording.frame = CGRectMake(24, 86, 43, 14);
        [camera addSublayer:cameraRecording];
        self.layers[@"cameraRecording"] = cameraRecording;
        {
            CATextLayer * recordingText = [CATextLayer layer];
            recordingText.frame = CGRectMake(21, 1, 22, 13);
            [cameraRecording addSublayer:recordingText];
            self.layers[@"recordingText"] = recordingText;
            CAShapeLayer * recordingLight = [CAShapeLayer layer];
            recordingLight.frame = CGRectMake(0, 0, 14, 14);
            recordingLight.path = [self recordingLightPath].CGPath;
            [cameraRecording addSublayer:recordingLight];
            self.layers[@"recordingLight"] = recordingLight;
        }
        
    }
    
    
    [self resetLayerPropertiesForLayerIdentifiers:nil];
}

- (void)resetLayerPropertiesForLayerIdentifiers:(NSArray *)layerIds{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if(!layerIds || [layerIds containsObject:@"camera"]){
        CALayer * camera = self.layers[@"camera"];
        camera.shadowColor   = [UIColor blackColor].CGColor;
        camera.shadowOpacity = 1;
        camera.shadowOffset  = CGSizeMake(0, -0);
        camera.shadowRadius  = 2;
    }
    if(!layerIds || [layerIds containsObject:@"left"]){
        CAShapeLayer * left = self.layers[@"left"];
        left.anchorPoint     = CGPointMake(1, 1);
        left.frame           = CGRectMake(0, 0, 40, 60);
        left.lineCap         = kCALineCapRound;
        left.fillColor       = nil;
        left.strokeColor     = [UIColor colorWithRed:0 green: 0.502 blue:1 alpha:1].CGColor;
        left.lineWidth       = 3;
        left.lineDashPattern = @[@8, @8];
    }
    if(!layerIds || [layerIds containsObject:@"right"]){
        CAShapeLayer * right = self.layers[@"right"];
        right.anchorPoint     = CGPointMake(0, 1);
        right.frame           = CGRectMake(50, 0, 40, 60);
        right.lineCap         = kCALineCapRound;
        right.fillColor       = nil;
        right.strokeColor     = [UIColor colorWithRed:0 green: 0.502 blue:1 alpha:1].CGColor;
        right.lineWidth       = 3;
        right.lineDashPattern = @[@8, @8];
    }
    if(!layerIds || [layerIds containsObject:@"cameraFrame"]){
        CAShapeLayer * cameraFrame = self.layers[@"cameraFrame"];
        cameraFrame.fillColor   = [UIColor blackColor].CGColor;
        cameraFrame.strokeColor = [UIColor colorWithRed:0.298 green: 0.298 blue:0.298 alpha:1].CGColor;
        cameraFrame.lineWidth   = 3;
    }
    if(!layerIds || [layerIds containsObject:@"cameraLens"]){
        CAShapeLayer * cameraLens = self.layers[@"cameraLens"];
        cameraLens.fillColor   = [UIColor blackColor].CGColor;
        cameraLens.strokeColor = [UIColor colorWithRed:0.298 green: 0.298 blue:0.298 alpha:1].CGColor;
        cameraLens.lineWidth   = 3;
    }
    if(!layerIds || [layerIds containsObject:@"recordingText"]){
        CATextLayer * recordingText = self.layers[@"recordingText"];
        recordingText.contentsScale   = [[UIScreen mainScreen] scale];
        recordingText.string          = @"REC";
        recordingText.font            = (__bridge CFTypeRef)@"Helvetica-Bold";
        recordingText.fontSize        = 10;
        recordingText.alignmentMode   = kCAAlignmentCenter;
        recordingText.foregroundColor = [UIColor redColor].CGColor;
    }
    if(!layerIds || [layerIds containsObject:@"recordingLight"]){
        CAShapeLayer * recordingLight = self.layers[@"recordingLight"];
        recordingLight.fillColor   = [UIColor redColor].CGColor;
        recordingLight.strokeColor = [UIColor whiteColor].CGColor;
        recordingLight.lineWidth   = 0;
    }
    
    [CATransaction commit];
}

#pragma mark - Animation Setup

- (void)addPullAnimation{
    [self addPullAnimationCompletionBlock:nil];
}

- (void)addPullAnimationCompletionBlock:(void (^)(BOOL finished))completionBlock{
    [self addPullAnimationReverse:NO totalDuration:2 completionBlock:completionBlock];
}

- (void)addPullAnimationReverse:(BOOL)reverseAnimation totalDuration:(CFTimeInterval)totalDuration completionBlock:(void (^)(BOOL finished))completionBlock{
    if (completionBlock){
        CABasicAnimation * completionAnim = [CABasicAnimation animationWithKeyPath:@"completionAnim"];;
        completionAnim.duration = totalDuration;
        completionAnim.delegate = self;
        [completionAnim setValue:@"pull" forKey:@"animId"];
        [completionAnim setValue:@(NO) forKey:@"needEndAnim"];
        [self.layer addAnimation:completionAnim forKey:@"pull"];
        [self.completionBlocks setObject:completionBlock forKey:[self.layer animationForKey:@"pull"]];
    }
    
    NSString * fillMode = reverseAnimation ? kCAFillModeBoth : kCAFillModeForwards;
    
    ////Camera animation
    CABasicAnimation * cameraPositionAnim = [CABasicAnimation animationWithKeyPath:@"position"];
    cameraPositionAnim.fromValue          = [NSValue valueWithCGPoint:CGPointMake(50, 58.25)];
    cameraPositionAnim.toValue            = [NSValue valueWithCGPoint:CGPointMake(50, 240)];
    cameraPositionAnim.duration           = totalDuration;
    cameraPositionAnim.timingFunction     = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CAAnimationGroup * cameraPullAnim = [QCMethod groupAnimations:@[cameraPositionAnim] fillMode:fillMode];
    if (reverseAnimation) cameraPullAnim = (CAAnimationGroup *)[QCMethod reverseAnimation:cameraPullAnim totalDuration:totalDuration];
    [self.layers[@"camera"] addAnimation:cameraPullAnim forKey:@"cameraPullAnim"];
    
    ////Left animation
    CABasicAnimation * leftAnchorPointAnim = [CABasicAnimation animationWithKeyPath:@"anchorPoint"];
    leftAnchorPointAnim.fromValue          = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
    leftAnchorPointAnim.toValue            = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
    leftAnchorPointAnim.duration           = totalDuration;
    leftAnchorPointAnim.timingFunction     = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation * leftTransformAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    leftTransformAnim.fromValue          = @(0);
    leftTransformAnim.toValue            = @(26 * M_PI/180);
    leftTransformAnim.duration           = totalDuration;
    leftTransformAnim.timingFunction     = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation * leftLineDashPhaseAnim = [CABasicAnimation animationWithKeyPath:@"lineDashPhase"];
    leftLineDashPhaseAnim.fromValue      = @0;
    leftLineDashPhaseAnim.toValue        = @-40;
    leftLineDashPhaseAnim.duration       = totalDuration;
    leftLineDashPhaseAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CAAnimationGroup * leftPullAnim = [QCMethod groupAnimations:@[leftAnchorPointAnim, leftTransformAnim, leftLineDashPhaseAnim] fillMode:fillMode];
    if (reverseAnimation) leftPullAnim = (CAAnimationGroup *)[QCMethod reverseAnimation:leftPullAnim totalDuration:totalDuration];
    [self.layers[@"left"] addAnimation:leftPullAnim forKey:@"leftPullAnim"];
    
    ////Right animation
    CABasicAnimation * rightAnchorPointAnim = [CABasicAnimation animationWithKeyPath:@"anchorPoint"];
    rightAnchorPointAnim.fromValue      = [NSValue valueWithCGPoint:CGPointMake(0, 1)];
    rightAnchorPointAnim.toValue        = [NSValue valueWithCGPoint:CGPointMake(0, 1)];
    rightAnchorPointAnim.duration       = totalDuration;
    rightAnchorPointAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation * rightTransformAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rightTransformAnim.fromValue          = @(0);
    rightTransformAnim.toValue            = @(-26 * M_PI/180);
    rightTransformAnim.duration           = totalDuration;
    rightTransformAnim.timingFunction     = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation * rightLineDashPhaseAnim = [CABasicAnimation animationWithKeyPath:@"lineDashPhase"];
    rightLineDashPhaseAnim.fromValue      = @0;
    rightLineDashPhaseAnim.toValue        = @-40;
    rightLineDashPhaseAnim.duration       = totalDuration;
    rightLineDashPhaseAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CAAnimationGroup * rightPullAnim = [QCMethod groupAnimations:@[rightAnchorPointAnim, rightTransformAnim, rightLineDashPhaseAnim] fillMode:fillMode];
    if (reverseAnimation) rightPullAnim = (CAAnimationGroup *)[QCMethod reverseAnimation:rightPullAnim totalDuration:totalDuration];
    [self.layers[@"right"] addAnimation:rightPullAnim forKey:@"rightPullAnim"];
    
    ////RecordingLight animation
    CAKeyframeAnimation * recordingLightOpacityAnim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    recordingLightOpacityAnim.values   = @[@1, @0.2, @1, @0.2, @1];
    recordingLightOpacityAnim.keyTimes = @[@0, @0.25, @0.5, @0.75, @1];
    recordingLightOpacityAnim.duration = totalDuration;
    
    CAAnimationGroup * recordingLightPullAnim = [QCMethod groupAnimations:@[recordingLightOpacityAnim] fillMode:fillMode];
    if (reverseAnimation) recordingLightPullAnim = (CAAnimationGroup *)[QCMethod reverseAnimation:recordingLightPullAnim totalDuration:totalDuration];
    [self.layers[@"recordingLight"] addAnimation:recordingLightPullAnim forKey:@"recordingLightPullAnim"];
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
    if([identifier isEqualToString:@"pull"]){
        [QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"camera"] animationForKey:@"cameraPullAnim"] theLayer:self.layers[@"camera"]];
        [QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"left"] animationForKey:@"leftPullAnim"] theLayer:self.layers[@"left"]];
        [QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"right"] animationForKey:@"rightPullAnim"] theLayer:self.layers[@"right"]];
        [QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"recordingLight"] animationForKey:@"recordingLightPullAnim"] theLayer:self.layers[@"recordingLight"]];
    }
}

- (void)removeAnimationsForAnimationId:(NSString *)identifier{
    if([identifier isEqualToString:@"pull"]){
        [self.layers[@"camera"] removeAnimationForKey:@"cameraPullAnim"];
        [self.layers[@"left"] removeAnimationForKey:@"leftPullAnim"];
        [self.layers[@"right"] removeAnimationForKey:@"rightPullAnim"];
        [self.layers[@"recordingLight"] removeAnimationForKey:@"recordingLightPullAnim"];
    }
}

- (void)removeAllAnimations{
    [self.layers enumerateKeysAndObjectsUsingBlock:^(id key, CALayer *layer, BOOL *stop) {
        [layer removeAllAnimations];
    }];
}

#pragma mark - Bezier Path

- (UIBezierPath*)leftPath{
    UIBezierPath *leftPath = [UIBezierPath bezierPath];
    [leftPath moveToPoint:CGPointMake(0, 0)];
    [leftPath addLineToPoint:CGPointMake(40, 60)];
    
    return leftPath;
}

- (UIBezierPath*)rightPath{
    UIBezierPath *rightPath = [UIBezierPath bezierPath];
    [rightPath moveToPoint:CGPointMake(40, -0)];
    [rightPath addLineToPoint:CGPointMake(0, 60)];
    
    return rightPath;
}

- (UIBezierPath*)cameraFramePath{
    UIBezierPath * cameraFramePath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 60, 30)];
    return cameraFramePath;
}

- (UIBezierPath*)cameraLensPath{
    UIBezierPath * cameraLensPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 30, 15)];
    return cameraLensPath;
}

- (UIBezierPath*)recordingLightPath{
    UIBezierPath * recordingLightPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 14, 14)];
    return recordingLightPath;
}


@end
