//
//  VTMath.m
//  Vertigo
//
//  Created by Evan Long on 3/21/17.
//
//

#import "VTMath.h"

CGPoint VTRectMidPoint(CGRect rect)
{
    CGPoint p;
    p.x = CGRectGetMidX(rect);
    p.y = CGRectGetMidY(rect);
    return p;
}

CGFloat VTClamp(CGFloat value, CGFloat min, CGFloat max)
{
    return MAX(min, MIN(max, value));
}

BOOL VTFloatIsZero(CGFloat a)
{
    return VTFloatIsEqual(a, 0.0);
}

BOOL VTFloatIsEqual(CGFloat a, CGFloat b)
{
#if CGFLOAT_IS_DOUBLE
    return fabs(a - b) < DBL_EPSILON;
#else
    return fabsf(a - b) < FLT_EPSILON;
#endif
}
