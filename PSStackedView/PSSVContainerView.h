//
//  PSContainerView.h
//  PSStackedView
//
//  Created by Peter Steinberger on 7/17/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSStackedViewDelegate.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

enum {
    PSSVSideRight = 0x01,
    PSSVSideLeft = 0x02
}typedef PSSVSide;


@interface PSSVContainerView : UIView {
    CGFloat originalWidth_;
    UIViewController *controller_;
    CAGradientLayer *leftShadowLayer_;
    CAGradientLayer *innerShadowLayer_;
	CAGradientLayer *rightShadowLayer_;
}

+ (PSSVContainerView *)containerViewWithController:(UIViewController *)controller;

/// limit to max width
- (CGFloat)limitToMaxWidth;

- (void)addMaskToCorners:(UIRectCorner)corners;
- (void)removeMask;

- (void)addShadowToSides:(PSSVSide)sides;
- (void)removeShadow;

@property(nonatomic, retain) UIViewController *controller;

@end
