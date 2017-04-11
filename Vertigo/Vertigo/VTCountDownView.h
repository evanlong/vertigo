//
//  VTCountDownView.h
//  Vertigo
//
//  Created by Evan Long on 4/11/17.
//
//

#import "VTCaptureTypes.h"

typedef void (^VTCountDownCompletion)(BOOL finished);

@interface VTCountDownView : UIView

@property (nonatomic, assign) VTVertigoDirection direction;

/**
 Calling starts the countdown calling completion with YES if it successfully counted down to zero. If the startWithCompletion
 is called while VTCountDownView is in the middle of another countdown, it is effectively the same as calling stop followed
 by a startWithCompletion

 @param completion block called when countdown completes or is interrupted
 */
- (void)startWithCompletion:(VTCountDownCompletion)completion;


/**
 Stops an existing countdown that is in progress. If a completion block was provided, it will be called back with NO for the finished parameter
 */
- (void)stop;

@end
