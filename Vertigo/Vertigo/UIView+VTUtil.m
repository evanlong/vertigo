//
//  UIView+VTUtil.m
//  Vertigo
//
//  Created by Evan Long on 7/2/17.
//
//

#import "UIView+VTUtil.h"

@implementation UIView (VTUtil)

- (UIImage *)renderedAsImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *layerAsImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return layerAsImage;
}

@end
