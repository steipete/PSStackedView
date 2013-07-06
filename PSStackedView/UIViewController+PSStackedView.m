//
//  UIViewController+PSStackedView.m
//  3MobileTV
//
//  Created by Peter Steinberger on 9/16/11.
//  Copyright (c) 2011 Hutchison. All rights reserved.
//

#import "UIViewController+PSStackedView.h"
#import "PSSVContainerView.h"
#import "PSStackedViewController.h"
#import <objc/runtime.h>

#define kPSSVAssociatedStackViewControllerWidth @"kPSSVAssociatedStackViewControllerWidth"

#define kPSSVAssociatedStackViewControllerGesture @"kPSSVAssociatedStackViewControllerGesture"
#define kPSSVAssociatedStackViewControllerFrameWidth @"kPSSVAssociatedStackViewControllerFrameWidth"
#define kPSSVAssociatedStackViewControllerWantsFull @"kPSSVAssociatedStackViewControllerWantsFull"

#define kPSSVAssociatedStackViewControllerPanEnabled @"kPSSVAssociatedStackViewControllerPanEnabled"
#define kPSSVAssociatedStackViewControllerStretchable @"kPSSVAssociatedStackViewControllerStretchable" 

@implementation UIViewController (PSStackedView)

// returns the containerView, where view controllers are embedded
- (PSSVContainerView *)containerView; {
    return ([self.view.superview isKindOfClass:[PSSVContainerView class]] ? (PSSVContainerView *)self.view.superview : nil);
}

// returns the stack controller if the viewController is embedded
- (PSStackedViewController *)stackController; {
    PSStackedViewController *stackController = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerKey);
    return stackController;
}

#ifdef ALLOW_SWIZZLING_NAVIGATIONCONTROLLER
/// to maintain minimal changes for your app, we can do some clever swizzling here.
- (UINavigationController *)navigationControllerSwizzled {
    if (!self.navigationControllerSwizzled) {
        return (UINavigationController *)self.stackController;
    }else {
        return self.navigationControllerSwizzled;
    }
}
#endif

- (CGFloat)stackWidth {
    NSNumber *stackWidthNumber = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerWidth);
    CGFloat stackWidth = stackWidthNumber ? [stackWidthNumber floatValue] : 0.f;
    return stackWidth;
}

- (void)setStackWidth:(CGFloat)stackWidth {
    NSNumber *stackWidthNumber = [NSNumber numberWithFloat:stackWidth];
    objc_setAssociatedObject(self, kPSSVAssociatedStackViewControllerWidth, stackWidthNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//this method will expand the view to full size
//gesture are lost to prevent scrolling
- (void) maximizeStackViewAtIndex:(NSInteger)indexNumber {
    
    UIView *stacksRootView = self.view.window.subviews[0];
    __block UIView *stackAtIndexView = stacksRootView.subviews[indexNumber+1]; //Adds 1 for the menu view
    
    //Hides all views from the stack
    for (UIView *stackView  in stacksRootView.subviews) {
        stackView.hidden = YES;
    }
    //Display stackView that wants to be maximize
    stackAtIndexView.hidden = NO;
    
    CGRect frame = stackAtIndexView.frame;

    //This Controller Wants Full
    objc_setAssociatedObject(self, kPSSVAssociatedStackViewControllerWantsFull, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //In case gesture is nill then there is no need to store it. (its full size)
    if (stacksRootView.gestureRecognizers!=nil) {
        objc_setAssociatedObject(self, kPSSVAssociatedStackViewControllerGesture, stacksRootView.gestureRecognizers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        stacksRootView.gestureRecognizers = nil; //remove gesture.
    }
    
    //Just store the frame width onces. (rotation changes width)
    NSNumber *numFrameWidth = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerFrameWidth);
    if (numFrameWidth==nil) {
        numFrameWidth = [NSNumber numberWithFloat:frame.size.width];
        objc_setAssociatedObject(self, kPSSVAssociatedStackViewControllerFrameWidth, numFrameWidth, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [UIView animateWithDuration:0.25 delay:0.f
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGRect frameAnim = stackAtIndexView.frame;
                         //Moves stackView to the border and changes width
                         frameAnim.origin.x = 0; //move it to left
                         frameAnim.size.width = stacksRootView.bounds.size.width; //fullscreen
                         stackAtIndexView.frame = frameAnim;
                         
                     } completion:^(BOOL finished) {
                         
                     }];
                         

}


//this method will move the view back to the stack
//in case of rotation we jump to the indexNumber
//rotation are restured
- (void) minimizeStackViewAtIndex:(NSInteger)indexNumber {
    
    UIView *stacksRootView = self.view.window.subviews[0];    
    __block UIView *controllerView = stacksRootView.subviews[indexNumber+1];
    
    //Make all controllersView visibles
    for (UIView *stackView  in stacksRootView.subviews) {
         stackView.hidden = NO;
    }

    //This controller does not wants full size any more
    objc_setAssociatedObject(self, kPSSVAssociatedStackViewControllerWantsFull, [NSNumber numberWithBool:NO], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //Restore original size for the controller view
    NSNumber *numFrameWidth = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerFrameWidth);
    
    
    [UIView animateWithDuration:0.25 delay:0.f
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         CGRect frame = controllerView.frame;
                         frame.size.width = [numFrameWidth floatValue];
                         controllerView.frame = frame;
                         
                         //position view to the correct stack
                         [self.stackController displayViewControllerIndexOnRightMost:indexNumber animated:YES];
                         
                         // ensure we're correctly aligned (may be messed up in willAnimate, if panRecognizer is still active)
                         [self.stackController alignStackAnimated:self.stackController.isReducingAnimations];
                         
                     } completion:^(BOOL finished) {
                         //Restore gesture array
                         stacksRootView.gestureRecognizers = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerGesture);
                         
                     }];
    

    
}



- (BOOL)panEnabled
{
    NSNumber *panEnabledNumber = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerPanEnabled);
    BOOL panEnabled = panEnabledNumber ? [panEnabledNumber boolValue] : YES;
    return panEnabled;
}

- (void)setPanEnabled:(BOOL)panEnabled
{
    NSNumber *panEnabledNumber = [NSNumber numberWithBool:panEnabled];
    objc_setAssociatedObject(self, kPSSVAssociatedStackViewControllerPanEnabled, panEnabledNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)stretchable
{
    NSNumber *stretchabledNumber = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerStretchable);
    BOOL stretchable = stretchabledNumber ? [stretchabledNumber boolValue] : NO;
    return stretchable;
}

- (void)setStretchable:(BOOL)stretchable
{
    NSNumber *stretchableNumber = [NSNumber numberWithBool:stretchable];
    objc_setAssociatedObject(self, kPSSVAssociatedStackViewControllerStretchable, stretchableNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
