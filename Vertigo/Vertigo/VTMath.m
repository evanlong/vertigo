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

CGFloat VTFloatFloor(CGFloat value)
{
#if CGFLOAT_IS_DOUBLE
    return floor(value);
#else
    return floorf(value);
#endif
}

CGFloat VTFloatCeil(CGFloat value)
{
#if CGFLOAT_IS_DOUBLE
    return ceil(value);
#else
    return ceilf(value);
#endif
}

CGFloat VTFloatRound(CGFloat value)
{
#if CGFLOAT_IS_DOUBLE
    return round(value);
#else
    return roundf(value);
#endif
}

CGFloat VTRoundToNearestFactor(CGFloat value, CGFloat factor)
{
#if 0
    // Alternate way to do the same thing. This snippet is nicer for a function that is a SnapToDeviceScale where the function
    // hardcodes the device's scale such as 2 or 3 instead of of providing a factor (1 / deviceScale) as value to factor.
    CGFloat scale = 1.0 / factor;
    return VTFloatRound(value * scale) / scale;
#else
    return VTFloatRound(value / factor) * factor;
#endif
}
