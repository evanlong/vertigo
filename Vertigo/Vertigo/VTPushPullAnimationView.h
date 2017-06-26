//
//  VTPushPullAnimationView.h
//
//  Code generated using QuartzCode 1.56.0 on 6/25/17.
//  www.quartzcodeapp.com
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface VTPushPullAnimationView : UIView



- (void)addPullAnimation;
- (void)addPullAnimationCompletionBlock:(void (^)(BOOL finished))completionBlock;
- (void)addPullAnimationReverse:(BOOL)reverseAnimation totalDuration:(CFTimeInterval)totalDuration completionBlock:(void (^)(BOOL finished))completionBlock;
- (void)removeAnimationsForAnimationId:(NSString *)identifier;
- (void)removeAllAnimations;

@end
