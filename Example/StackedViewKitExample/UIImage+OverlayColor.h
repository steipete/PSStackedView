//
//  UIImage+OverlayColor.h
//  PSStackedViewExample
//
//  Created by Gregory Combs on 7/28/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//
//  Adapted from Dave Batton's answer on StackOverflow: 
//  http://stackoverflow.com/questions/1223340/iphone-how-do-you-color-an-image

#import <UIKit/UIKit.h>


@interface UIImage(OverlayColor)

+ (UIImage *)invertImageNamed:(NSString *)name;

- (UIImage *)imageWithOverlayColor:(UIColor *)color;

@end
