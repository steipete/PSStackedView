//
//  UIImage+OverlayColor.m
//  PSStackedViewExample
//
//  Created by Gregory Combs on 7/28/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//
//  Adapted from Dave Batton's answer on StackOverflow: 
//  http://stackoverflow.com/questions/1223340/iphone-how-do-you-color-an-image

#import "UIImage+OverlayColor.h"


@implementation UIImage(OverlayColor)

// I'm not completely happy with this.  It looks like there's a little blurring on some images. (Greg)

- (UIImage *)imageWithOverlayColor:(UIColor *)color
{        
    CGRect rect = CGRectMake(0.0f, 0.0f, self.size.width, self.size.height);
    
    if (UIGraphicsBeginImageContextWithOptions) {
        CGFloat imageScale = 1.0f;
        if ([self respondsToSelector:@selector(scale)])
            imageScale = self.scale;
        UIGraphicsBeginImageContextWithOptions(self.size, NO, imageScale);
    }
    else {
        UIGraphicsBeginImageContext(self.size);
    }
    
    [self drawInRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *outImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outImage;
}

+ (UIImage *)invertImageNamed:(NSString *)name {
    
    UIColor *offWhite = [UIColor colorWithRed:(245.f/255.f) 
                                        green:(245.f/255.f) 
                                         blue:(245.f/255.f) 
                                        alpha:1.f];
    
    // offWhite looks nice on a scroll view background, however, 
    //  a suitable alternative is [UIColor whiteColor]
    return [[UIImage imageNamed:name] imageWithOverlayColor:offWhite];
}

@end
