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

CGFloat VTMapValueFromRangeToNewRange(CGFloat value, CGFloat minRange, CGFloat maxRange, CGFloat newMinRange, CGFloat newMaxRange)
{
    CGFloat percentage = (value - minRange) / (maxRange - minRange);
    CGFloat newValue = ((newMaxRange - newMinRange) * percentage) + newMinRange;
    return newValue;
}

#pragma mark - Push / Pull

static CGFloat _VTZoomRate(CGFloat minZoom, CGFloat maxZoom, NSTimeInterval duration)
{
    return log2(maxZoom / minZoom) / duration;
}

CGFloat VTPushEffectZoomPowerScale(CGFloat zoomLevel1, CGFloat zoomLevel2, NSTimeInterval currentTime, NSTimeInterval duration)
{
    CGFloat minZoom = MIN(zoomLevel1, zoomLevel2);
    CGFloat maxZoom = MAX(zoomLevel1, zoomLevel2);
    CGFloat rate = _VTZoomRate(minZoom, maxZoom, duration);
    return 1.0 / pow(2, rate * (currentTime - duration));
}

CGFloat VTPullEffectZoomPowerScale(CGFloat zoomLevel1, CGFloat zoomLevel2, NSTimeInterval currentTime, NSTimeInterval duration)
{
    CGFloat minZoom = MIN(zoomLevel1, zoomLevel2);
    CGFloat maxZoom = MAX(zoomLevel1, zoomLevel2);
    CGFloat rate = _VTZoomRate(minZoom, maxZoom, duration);
    return pow(2, rate * currentTime);
}

CGFloat VTVertigoEffectZoomPowerScale(CGFloat initialZoomLevel, CGFloat finalZoomLevel, NSTimeInterval currentTime, NSTimeInterval duration)
{
    if (initialZoomLevel < finalZoomLevel)
    {
        return VTPullEffectZoomPowerScale(initialZoomLevel, finalZoomLevel, currentTime, duration);
    }
    else
    {
        return VTPushEffectZoomPowerScale(initialZoomLevel, finalZoomLevel, currentTime, duration);
    }
}
