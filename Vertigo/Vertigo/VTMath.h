//
//  VTMath.h
//  Vertigo
//
//  Created by Evan Long on 3/21/17.
//
//


CGPoint VTRectMidPoint(CGRect rect);

CGFloat VTClamp(CGFloat value, CGFloat min, CGFloat max);

BOOL VTFloatIsZero(CGFloat a);
BOOL VTFloatIsEqual(CGFloat a, CGFloat b);
CGFloat VTFloatFloor(CGFloat value);
CGFloat VTFloatCeil(CGFloat value);
CGFloat VTFloatRound(CGFloat value);

/**
 VTRoundToNearestFactor Rounds value to the nearest factor. The factor can be fractional, or whole number.
 
 @example
 In Core Graphics or view alignment code it may be desired to align to the nearest pixel boundry instead of point boundry. This can be useful
 when rendering or aligning 1 pixel lines. Rounding to nearest whole number point can result in jumpy animation (think CADisplayLink driven)
 and unintended gaps in alignment. Note that on a 2x device 1pt == 2px and on a 3x device: 1.0pt == 3px.
 
 
 This is an example of how this function can be used with the device's scale:
     CGFloat deviceScale = [[UIScreen mainScreen] scale];
     // assume deviceScale = 2.0
     CGFloat result = VTRoundToNearestFactor(2.65, 1.0 / deviceScale)
     result == 2.65 
 
 It also works for values greater than 1.0:
     VTRoundToNearestFactor(24.0, 50.0) => 0.0
     VTRoundToNearestFactor(25.0, 50.0) => 50.0
     VTRoundToNearestFactor(26.0, 50.0) => 50.0

 @param value The value to round to nearest factor
 @param factor The factor the value will be rounded too
 @return value rounded to nearest factor
 */
CGFloat VTRoundToNearestFactor(CGFloat value, CGFloat factor);
