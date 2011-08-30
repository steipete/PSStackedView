//
//  PSContainerView.m
//  PSStackedView
//
//  Created by Peter Steinberger on 7/17/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSSVContainerView.h"
#import "PSStackedViewGlobal.h"
#import "UIView+PSSizes.h"

#define kPSSVCornerRadius 6.f
#define kPSSVShadowWidth 80.f

@interface PSSVContainerView ()
@property(nonatomic, assign) CGFloat originalWidth;
@property(nonatomic, retain) CAGradientLayer *leftShadowLayer;
@property(nonatomic, retain) CAGradientLayer *innerShadowLayer;
@property(nonatomic, retain) CAGradientLayer *rightShadowLayer;
@end

@implementation PSSVContainerView

@synthesize originalWidth = originalWidth_;
@synthesize controller = controller_;
@synthesize leftShadowLayer = leftShadowLayer_;
@synthesize innerShadowLayer = innerShadowLayer_;
@synthesize rightShadowLayer = rightShadowLayer_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark private

// creates vertical shadow
- (CAGradientLayer *)shadowAsInverse:(BOOL)inverse {
	CAGradientLayer *newShadow = [[[CAGradientLayer alloc] init] autorelease];
    newShadow.startPoint = CGPointMake(0, 0.5);
    newShadow.endPoint = CGPointMake(1.0, 0.5);
	CGColorRef darkColor  = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3].CGColor;
	CGColorRef lightColor = [UIColor clearColor].CGColor;
	newShadow.colors = [NSArray arrayWithObjects:
                        (id)(inverse ? lightColor : darkColor),
                        (id)(inverse ? darkColor : lightColor),
                        nil];
	return newShadow;
}

// return available shadows as set, for easy enumeration
- (NSSet *)shadowSet {
    NSMutableSet *set = [NSMutableSet set];
    if (self.leftShadowLayer) {
        [set addObject:self.leftShadowLayer];
    }
    if (self.innerShadowLayer) {
        [set addObject:self.innerShadowLayer];
    }
    if (self.rightShadowLayer) {
        [set addObject:self.rightShadowLayer];
    }
    return [[set copy] autorelease];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

+ (PSSVContainerView *)containerViewWithController:(UIViewController *)controller; {
    PSSVContainerView *view = [[[PSSVContainerView alloc] initWithFrame:controller.view.frame] autorelease];
    view.controller = controller;    
    return view;
}

- (void)dealloc {
    //PSLog(@"removing mask/shadow from %@", self.controller);
    [self removeMask];
    [self removeShadow];
    [leftShadowLayer_ release];
    [innerShadowLayer_ release];
    [rightShadowLayer_ release];
    [controller_ release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIView

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    // adapt layer heights
    for (CALayer *layer in [self shadowSet]) {
        CGRect aFrame = layer.frame;
        aFrame.size.height = frame.size.height;
        layer.frame = aFrame;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (CGFloat)limitToMaxWidth:(CGFloat)maxWidth; {

    if (maxWidth && self.width > maxWidth) {
        self.width = maxWidth;
    }else if(self.originalWidth && self.width < self.originalWidth) {
        self.width = MIN(maxWidth, self.originalWidth);
    }
    self.controller.view.width = self.width;
    return self.width;
}

- (void)setController:(UIViewController *)aController {
    if (controller_ != aController) {
        if (controller_) {
            [controller_.view removeFromSuperview];
            [controller_ release];
        }        
        controller_ = [aController retain];
        
        // properly embed view
        self.originalWidth = self.controller.view.width;
        controller_.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth; 
        controller_.view.frame = CGRectMake(0, 0, controller_.view.width, controller_.view.height);
        [self addSubview:controller_.view];
    }
}

- (void)addMaskToCorners:(UIRectCorner)corners; {
    // Re-calculate the size of the mask to account for adding/removing rows.
    CGRect frame = self.controller.view.bounds;
    if([self.controller.view isKindOfClass:[UIScrollView class]] && ((UIScrollView *)self.controller.view).contentSize.height > self.controller.view.frame.size.height) {
    	frame.size = ((UIScrollView *)self.controller.view).contentSize;
    } else {
        frame.size = self.controller.view.frame.size;
    }
    
    // Create the path (with only the top-left corner rounded)
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:frame 
                                                   byRoundingCorners:corners
                                                         cornerRadii:CGSizeMake(kPSSVCornerRadius, kPSSVCornerRadius)];
    
    // Create the shape layer and set its path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = frame;
    maskLayer.path = maskPath.CGPath;
    
    // Set the newly created shape layer as the mask for the image view's layer
    self.controller.view.layer.mask = maskLayer;
}

- (void)removeMask; {
    self.controller.view.layer.mask = nil;
}

- (void)addShadowToSides:(PSSVSide)sides; {
    if (sides & PSSVSideLeft) {
        if (!self.leftShadowLayer) {
            CAGradientLayer *leftShadow = [self shadowAsInverse:YES];
            CGRect newShadowFrame = CGRectMake(-kPSSVShadowWidth, 0, kPSSVShadowWidth+kPSSVCornerRadius, self.controller.view.height);
            leftShadow.frame = newShadowFrame;
            self.leftShadowLayer = leftShadow;
        }
        if ([self.layer.sublayers indexOfObjectIdenticalTo:self.leftShadowLayer] != 0) {
            [self.layer insertSublayer:self.leftShadowLayer atIndex:0];
        }
    }else {
        [self.leftShadowLayer removeFromSuperlayer];
    }
    
    if (sides & PSSVSideRight) {
        if (!self.rightShadowLayer) {
            CAGradientLayer *rightShadow = [self shadowAsInverse:NO];
            CGRect newShadowFrame = CGRectMake(self.width-kPSSVCornerRadius, 0, kPSSVShadowWidth, self.controller.view.height);
            rightShadow.frame = newShadowFrame;
            self.rightShadowLayer = rightShadow;
        }
        if ([self.layer.sublayers indexOfObjectIdenticalTo:self.rightShadowLayer] != 0) {
            [self.layer insertSublayer:self.rightShadowLayer atIndex:0];
        }
    }else {
        [self.rightShadowLayer removeFromSuperlayer];
    }
    
    if (sides) {
        if (!self.innerShadowLayer) {
            
            CAGradientLayer *innerShadow = [[[CAGradientLayer alloc] init] autorelease];
            CGRect newShadowFrame = CGRectMake(kPSSVCornerRadius, 0, self.width-kPSSVCornerRadius*2, self.controller.view.height);
            innerShadow.frame = newShadowFrame;
            CGColorRef darkColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5].CGColor;
            innerShadow.colors = [NSArray arrayWithObjects:(id)darkColor, (id)darkColor, nil];
            self.innerShadowLayer = innerShadow;
        }
        if ([self.layer.sublayers indexOfObjectIdenticalTo:self.innerShadowLayer] != 0) {
            [self.layer insertSublayer:self.innerShadowLayer atIndex:0];
        }
    }else {
        [self.innerShadowLayer removeFromSuperlayer];
    }
}

- (void)removeShadow; {
    [self.leftShadowLayer removeFromSuperlayer];
    [self.rightShadowLayer removeFromSuperlayer];
}

@end
