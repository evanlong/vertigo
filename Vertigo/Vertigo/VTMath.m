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

