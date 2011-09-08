//
//  SVStackRootController.m
//  PSStackedView
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSStackedViewController.h"
#import "PSStackedViewGlobal.h"
#import "PSSVContainerView.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define kPSSVStackAnimationSpeedModifier 1.f // DEBUG!
#define kPSSVStackAnimationDuration kPSSVStackAnimationSpeedModifier * 0.25f
#define kPSSVStackAnimationBounceDuration kPSSVStackAnimationSpeedModifier * 0.20f
#define kPSSVStackAnimationPopDuration kPSSVStackAnimationSpeedModifier * 0.15f
#define kPSSVMaxSnapOverOffset 20
#define kPSSVAssociatedBaseViewControllerKey @"kPSSVAssociatedBaseViewController"
#define kPSSVAssociatedStackViewControllerKey @"kPSSVAssociatedStackViewController"

// reduces alpha over overlapped view controllers. 1.f would totally black-out on complete overlay
#define kAlphaReductRatio 1.7f

@implementation UIViewController (PSStackedViewAdditions)

// returns the containerView, where view controllers are embedded
- (PSSVContainerView *)containerView; { return ([self.view.superview isKindOfClass:[PSSVContainerView class]] ? (PSSVContainerView *)self.view.superview : nil); }

// returns the stack controller if the viewController is embedded
- (PSStackedViewController *)stackController; {
    PSStackedViewController *stackController = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerKey);
    return stackController;
}

// to maintain minimal changes for your app, we can do some clever swizzling here.
- (UINavigationController *)navigationControllerSwizzled {
    if (!self.navigationControllerSwizzled) {
        return (UINavigationController *)self.stackController;
    }else {
        return self.navigationController;
    }
}
@end

@interface PSStackedViewController() <UIGestureRecognizerDelegate> 
@property(nonatomic, retain) UIViewController *rootViewController;
@property(nonatomic, assign) NSMutableArray* viewControllers;
@property(nonatomic, assign) NSInteger firstVisibleIndex;
@property(nonatomic, assign, getter=isShowingFullMenu) BOOL showingFullMenu;
- (UIViewController *)overlappedViewController;
@end

@implementation PSStackedViewController

@synthesize leftInset = leftInset_;
@synthesize largeLeftInset = largeLeftInset_;
@synthesize viewControllers = viewControllers_;
@synthesize showingFullMenu  = showingFullMenu_;
@synthesize firstVisibleIndex = firstVisibleIndex_;
@synthesize rootViewController = rootViewController_;
@synthesize panRecognizer = panRecognizer_;
#ifdef ALLOW_SWIZZLING_NAVIGATIONCONTROLLER
@synthesize navigationBar;
#endif

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)initWithRootViewController:(UIViewController *)rootViewController; {
    if ((self = [super init])) {
        rootViewController_ = [rootViewController retain];
        viewControllers_ = [[NSMutableArray alloc] init];
        
        // set some reasonble defaults
        showingFullMenu_ = YES;
        leftInset_ = 60;
        largeLeftInset_ = 200;
        
        // add a gesture recognizer to detect dragging to the guest controllers
        UIPanGestureRecognizer *panRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)] autorelease];
        [panRecognizer setMaximumNumberOfTouches:1];
        [panRecognizer setDelaysTouchesBegan:NO];
        [panRecognizer setDelaysTouchesEnded:YES];
        [panRecognizer setCancelsTouchesInView:YES];
        panRecognizer.delegate = self;
        [self.view addGestureRecognizer:panRecognizer];
        self.panRecognizer = panRecognizer;
        
#ifdef ALLOW_SWIZZLING_NAVIGATIONCONTROLLER
        PSSVLog("Swizzling UIViewController.navigationController");
        Method origMethod = class_getInstanceMethod([UIViewController class], @selector(navigationController));
        Method overrideMethod = class_getInstanceMethod([UIViewController class], @selector(navigationControllerSwizzled));
        method_exchangeImplementations(origMethod, overrideMethod);
#endif
    }
    return self;
}

- (void)dealloc {
    panRecognizer_.delegate = nil;
    // remove all view controllers the hard way
    while ([self.viewControllers count]) {
        [self popViewControllerAnimated:NO];
    }
    
    [panRecognizer_ release];
    [rootViewController_ release];
    [viewControllers_ release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Helpers

// return screen width
- (NSUInteger)screenWidth {
    NSUInteger screenWidth = PSIsLandscape() ? self.view.height : self.view.width;
    return screenWidth;
}

// total stack width if completely expanded
- (NSUInteger)totalStackWidth {
    NSUInteger totalStackWidth = 0;
    for (UIViewController *controller in self.viewControllers) {
        totalStackWidth += controller.containerView.width;
    }
    return totalStackWidth;
}

// menu is only collapsable if stack is large enough
- (BOOL)isMenuCollapsable {
    BOOL isMenuCollapsable = [self totalStackWidth] + self.largeLeftInset > [self screenWidth];
    return isMenuCollapsable;
}

// return current left border (how it *should* be)
- (NSUInteger)currentLeftInset {
    return self.isShowingFullMenu ? self.largeLeftInset : self.leftInset;
}

// minimal left border is depending on amount of VCs
- (NSUInteger)minimalLeftInset {
    return [self isMenuCollapsable] ? self.leftInset : self.largeLeftInset;
}

- (CGFloat)maxControllerWidth {
    CGFloat maxWidth = (PSIsLandscape() ? self.view.height : self.view.width) - self.leftInset;
    return maxWidth;
}

// check if a view controller is visible or not
- (BOOL)isViewControllerVisible:(UIViewController *)viewController completely:(BOOL)completely {
    NSParameterAssert(viewController);
    NSUInteger screenWidth = [self screenWidth];
    
    BOOL isVCVisible = ((viewController.containerView.left < screenWidth && !completely) ||
                        (completely && viewController.containerView.right <= screenWidth));
    return isVCVisible;
}

// returns view controller that is displayed before viewController 
- (UIViewController *)previousViewController:(UIViewController *)viewController {
    NSParameterAssert(viewController);
    
    NSUInteger vcIndex = [self.viewControllers indexOfObject:viewController];
    UIViewController *prevVC = nil;
    if (vcIndex > 0) {
        prevVC = [self.viewControllers objectAtIndex:vcIndex-1];
    }
    
    return prevVC;
}

// returns view controller that is displayed after viewController 
- (UIViewController *)nextViewController:(UIViewController *)viewController {
    NSParameterAssert(viewController);
    
    NSUInteger vcIndex = [self.viewControllers indexOfObject:viewController];
    UIViewController *nextVC = nil;
    if (vcIndex + 1 < [self.viewControllers count]) {
        nextVC = [self.viewControllers objectAtIndex:vcIndex+1];
    }
    
    return nextVC;
}

// returns last visible view controller. this *can* be the last view controller in the stack, 
// but also one of the previous ones if the user navigates back in the stack
- (UIViewController *)lastVisibleViewControllerCompletelyVisible:(BOOL)completely {
    __block UIViewController *lastVisibleViewController = nil;
    
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *currentViewController = (UIViewController *)obj;
        if ([self isViewControllerVisible:currentViewController completely:completely]) {
            lastVisibleViewController = currentViewController;
            *stop = YES;
        }
    }];
    
    return lastVisibleViewController;
}


/// calculates all rects for current visibleIndex orientation
- (NSArray *)rectsForControllers {
    NSMutableArray *frames = [NSMutableArray array];
    
    // TODO: currently calculates *all* objects, should cache!
    __block CGFloat widthTotal = 0.f;
    [self.viewControllers enumerateObjectsWithOptions:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *currentVC = (UIViewController *)obj;
        CGFloat leftPos;
        CGRect leftRect = idx > 0 ? [[frames objectAtIndex:idx-1] CGRectValue] : CGRectZero;
        
        widthTotal += currentVC.containerView.width;
        if (idx <= self.firstVisibleIndex) {
            
            // collapsed = snap to menu, or to right border (if there's place)
            CGFloat freeWidthLeft = 0.f;
            if (widthTotal >= [self screenWidth]) {
                freeWidthLeft = [self screenWidth] - [self minimalLeftInset];
                for (int i = idx; i < [self.viewControllers count] && freeWidthLeft > 0.f; i++) {
                    UIViewController *nextVC = [self.viewControllers objectAtIndex:i];
                    freeWidthLeft -= nextVC.containerView.width;
                }
            }
            leftPos = [self currentLeftInset] + MAX(freeWidthLeft, 0.f);
        }else {
            // connect vc to left vc's right!
            leftPos = leftRect.origin.x + leftRect.size.width;
        }
        
        CGRect currentRect = CGRectMake(leftPos, currentVC.containerView.origin.y,
                                        currentVC.containerView.size.width, currentVC.containerView.size.height);
        [frames addObject:[NSValue valueWithCGRect:currentRect]];
    }];
    
    return frames;
}

/// calculates the specific rect
- (CGRect)rectForControllerAtIndex:(NSUInteger)index {
    NSArray *frames = [self rectsForControllers];
    return [[frames objectAtIndex:index] CGRectValue];
}


/// moves a rect around, recalculates following rects
- (NSArray *)modifiedRects:(NSArray *)frames newLeft:(CGFloat)newLeft index:(NSUInteger)index {
    NSMutableArray *modifiedFrames = [NSMutableArray arrayWithArray:frames];
    
    CGRect prevFrame;
    for (int i = index; i < [modifiedFrames count]; i++) {
        CGRect vcFrame = [[modifiedFrames objectAtIndex:i] CGRectValue];
        if (i == index) {
            vcFrame.origin.x = newLeft;
        }else {
            vcFrame.origin.x = prevFrame.origin.x + prevFrame.size.width;
        }
        [modifiedFrames replaceObjectAtIndex:i withObject:[NSValue valueWithCGRect:vcFrame]];
        prevFrame = vcFrame;
    }
    
    return modifiedFrames;
}

// at some point, dragging does not make any more sense
- (BOOL)snapPointAvailableAfterOffset:(NSInteger)offset {
    BOOL snapPointAvailableAfterOffset = YES;
    NSUInteger screenWidth = [self screenWidth];
    NSUInteger totalWidth = [self totalStackWidth];
    NSUInteger minCommonWidth = MIN(screenWidth, totalWidth);
//    NSArray *frames = [self rectsForControllers];
    
    // are we at the end?
    UIViewController *topViewController = [self topViewController];
    if (topViewController == [self lastVisibleViewControllerCompletelyVisible:YES]) {
        if (minCommonWidth + [self minimalLeftInset] <= topViewController.containerView.right) {
            snapPointAvailableAfterOffset = NO;
        }
    }
    
    // slow down first controller when dragged to the right
    if ([self canCollapseStack] == 0) {
        snapPointAvailableAfterOffset = NO;
    }
    
    // not using [self canExand] here, as firstVisibleIndex is set while scrolling (menu!)
    if ([self firstViewController].containerView.left > self.largeLeftInset) {
        snapPointAvailableAfterOffset = NO;
    }
    
    return snapPointAvailableAfterOffset;
}

- (void)displayViewControllerOnRightMost:(UIViewController *)vc animated:(BOOL)animated; {
    [self displayViewControllerIndexOnRightMost:[self.viewControllers indexOfObject:vc] animated:animated];
}

// ensures index is on rightmost position
- (void)displayViewControllerIndexOnRightMost:(NSInteger)index animated:(BOOL)animated; {
    NSInteger indexOffset = index - self.lastVisibleIndex;
    if (indexOffset > 0 || (indexOffset == 0 && [self isMenuCollapsable])) {
        if (self.isShowingFullMenu && [self isMenuCollapsable]) {
            indexOffset--;
        }
        [self collapseStack:indexOffset animated:animated];
    }else if(indexOffset <= 0) {
        [self expandStack:indexOffset animated:animated];
    }
}

// try to fit in as many VCs as possible
- (void)checkAndDecreaseFirstVisibleIndexIfPossible {
    
    // sanity check
    if (self.firstVisibleIndex > [self.viewControllers count] - 1) {
        self.firstVisibleIndex = [self.viewControllers count] - 1;
    }
    
    // calculate if firstVisibleIndex is reasonable, adjust if not
    // we don't allow collapsing indefinitely! (only upon available screen space)
    NSInteger screenSpaceLeft = [self screenWidth] - [self currentLeftInset];
    while (screenSpaceLeft > 0 && self.firstVisibleIndex > 0 && [self.viewControllers count]) {
        NSInteger lastVisibleIndex = [self lastVisibleIndex];
        
        // only try to decrease the firstVisibleIndex if we're at the end.
        if (lastVisibleIndex != [self.viewControllers count]-1) {
            return;
        }
        
        for (NSUInteger firstIndex = self.firstVisibleIndex; firstIndex <= lastVisibleIndex; firstIndex++) {
            UIViewController *vc = [self.viewControllers objectAtIndex:firstIndex];
            screenSpaceLeft -= vc.containerView.width;
        }
        
        if (self.firstVisibleIndex > 0 && screenSpaceLeft >= ((UIViewController *)[self.viewControllers objectAtIndex:self.firstVisibleIndex-1]).containerView.width) {
            self.firstVisibleIndex -= 1;
        }
    }
}

// iterates controllers and sets width (also, enlarges if requested width is larger than current width)
- (void)updateViewControllerSizes {
    CGFloat maxControllerView = [self maxControllerWidth];
    for (UIViewController *controller in self.viewControllers) {
        [controller.containerView limitToMaxWidth:maxControllerView];
    }
}

// updates view containers
- (void)updateViewControllerMasksAndShadow {
    // ensure no controller is larger than the screen width
    NSUInteger maxWidth = [self screenWidth] - [self minimalLeftInset];
    for (UIViewController *controller in self.viewControllers) {
        if(controller.view.width > maxWidth) {
            PSSVLog(@"Resizing controller %@ (rect:%@) to fit max screen width of %d", controller, NSStringFromCGRect(controller.view.frame), maxWidth);
            controller.view.width = maxWidth;
        }
    }
    
    // only one!
    if ([self.viewControllers count] == 1) {
        //    [[self firstViewController].containerView addMaskToCorners:UIRectCornerAllCorners];
        [[self firstViewController].containerView addShadowToSides:PSSVSideLeft | PSSVSideRight];
    }else {
        // rounded corners on first and last controller
        [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIViewController *vc = (UIViewController *)obj;
            if (idx == 0) {
                //          [vc.containerView addShadowToSides:PSSVSideLeft];
                [vc.containerView addMaskToCorners:UIRectCornerBottomLeft | UIRectCornerTopLeft];
            }else if(idx == [self.viewControllers count]-1) {
                //        [vc.containerView addMaskToCorners:UIRectCornerBottomRight | UIRectCornerTopRight];
                [vc.containerView addShadowToSides:PSSVSideLeft | PSSVSideRight];
            }else {
                //      [vc.containerView removeMask];
                [vc.containerView addShadowToSides:PSSVSideLeft | PSSVSideRight];
            }
        }];
    }
        
    // update alpha mask
    UIViewController *overlappedVC = [self overlappedViewController];
    if (overlappedVC) {
        UIViewController *rightVC = [self nextViewController:overlappedVC];
        PSSVLog(@"overlapping %@ with %@", NSStringFromCGRect(overlappedVC.containerView.frame), NSStringFromCGRect(rightVC.containerView.frame));

        CGFloat overlapRatio = abs(overlappedVC.containerView.right - rightVC.containerView.left)/(CGFloat)overlappedVC.containerView.width;
        overlappedVC.containerView.darkRatio = overlapRatio/kAlphaReductRatio;
    }
    // reset alpha ratio everywhere else
    for (UIViewController *vc in self.viewControllers) {
        if (vc != overlappedVC) {
            vc.containerView.darkRatio = 0.0f;
        }
    }
}

- (NSArray *)visibleViewControllersSetFullyVisible:(BOOL)fullyVisible; {
    NSMutableArray *array = [NSMutableArray array];    
    [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([self isViewControllerVisible:obj completely:fullyVisible]) {
            [array addObject:obj];
        }
    }];
    
    return [[array copy] autorelease];
}


// check if there is any overlapping going on between VCs
- (BOOL)isViewController:(UIViewController *)leftViewController overlappingWith:(UIViewController *)rightViewController {
    NSParameterAssert(leftViewController);
    NSParameterAssert(rightViewController);
    
    // figure out which controller is the top one
    if ([self.viewControllers indexOfObject:rightViewController] < [self.viewControllers indexOfObject:leftViewController]) {
        PSSVLog(@"overlapping check flipped! fixing that...");
        UIViewController *tmp = rightViewController;
        rightViewController = leftViewController;
        leftViewController = tmp;
    }
    
    BOOL overlapping = leftViewController.containerView.right > rightViewController.containerView.left;
    if (overlapping) {
        PSSVLog(@"overlap detected: %@ (%@) with %@ (%@)", leftViewController, NSStringFromCGRect(leftViewController.containerView.frame), rightViewController, NSStringFromCGRect(rightViewController.containerView.frame));
    }
    return overlapping;
}

// find the rightmost overlapping controller
- (UIViewController *)overlappedViewController {
    __block UIViewController *overlappedViewController = nil;
    
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *currentViewController = (UIViewController *)obj;
        UIViewController *leftViewController = [self previousViewController:currentViewController];
        
        BOOL overlapping = NO;
        if (leftViewController && currentViewController) {
            overlapping = [self isViewController:leftViewController overlappingWith:currentViewController];
        }
        
        if (overlapping) {
            overlappedViewController = leftViewController;
            *stop = YES;
        }
    }];
    
    return overlappedViewController;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Touch Handling

- (void)stopStackAnimation {
    // remove all current animations
    //[self.view.layer removeAllAnimations];
    [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *vc = (UIViewController *)obj;
        //CGRect currentPos = [[vc.containerView.layer presentationLayer] frame];
        [vc.containerView.layer removeAllAnimations];
        //PSSVLog(@"Old: %@ New: %@", NSStringFromCGRect(vc.containerView.frame), NSStringFromCGRect(currentPos));
        //        vc.containerView.frame = currentPos;
        
        /*
         CFTimeInterval pausedTime = [vc.containerView.layer convertTime:CACurrentMediaTime() fromLayer:nil];
         vc.containerView.layer.speed = 0.0;
         vc.containerView.layer.timeOffset = pausedTime;
         */
    }];
}

// moves the stack to a specific offset. 
- (void)moveStackWithOffset:(NSInteger)offset animated:(BOOL)animated userDragging:(BOOL)userDragging {
    PSSVLog(@"moving stack on %d pixels (animated:%d, decellerating:%d)", offset, animated, userDragging);
    
    [self stopStackAnimation];
    if (animated) {
        [UIView beginAnimations:@"stackAnim" context:nil];
        [UIView setAnimationDuration:kPSSVStackAnimationDuration];
        [UIView setAnimationBeginsFromCurrentState:YES];
    }
    
    // enumerate controllers from right to left
    // scroll each controller until we begin to overlap!
    __block BOOL isTopViewController = YES;
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *currentViewController = (UIViewController *)obj;
        UIViewController *leftViewController = [self previousViewController:currentViewController];
        UIViewController *rightViewController = [self nextViewController:currentViewController];        
        NSInteger minimalLeftInset = [self minimalLeftInset];
        
        // we just move the top view controller
        NSInteger currentVCLeftPosition = currentViewController.containerView.left;
        if (isTopViewController) {
            currentVCLeftPosition += offset;
        }else {
            // make sure we're connected to the next controller!
            currentVCLeftPosition = rightViewController.containerView.left - currentViewController.containerView.width;
        }
        
        // prevent scrolling < minimal width (except for the top view controller - allow stupidness!)
        if (currentVCLeftPosition < minimalLeftInset && (!userDragging || (userDragging && !isTopViewController))) {
            currentVCLeftPosition = minimalLeftInset;
        }
        
        // a previous view controller is not allowed to overlap the next view controller.
        if (leftViewController && leftViewController.containerView.right > currentVCLeftPosition) {
            NSInteger leftVCLeftPosition = currentVCLeftPosition - leftViewController.containerView.width;
            if (leftVCLeftPosition < minimalLeftInset) {
                leftVCLeftPosition = minimalLeftInset;
            }
            leftViewController.containerView.left = leftVCLeftPosition;
        }
        
        currentViewController.containerView.left = currentVCLeftPosition;
        
        isTopViewController = NO; // there can only be one.
    }];
    
    [self updateViewControllerMasksAndShadow];
    
    // update firstVisibleIndex
#ifdef kPSSVStackedViewKitDebugEnabled
    NSUInteger oldFirstVisibleIndex = self.firstVisibleIndex;
#endif
    
    NSUInteger newFirstVisibleIndex;
    NSInteger minLeft = [self firstViewController].containerView.left;
    for (UIViewController *vc in self.viewControllers) {
        NSInteger vcLeft = vc.containerView.left;
        if (minLeft < vcLeft) {
            newFirstVisibleIndex = [self.viewControllers indexOfObject:vc] - 1;
            break;
        }
    }
    // special case, if we have overlapping controllers!
    // in this case underlying controllers are visible, but they are overlapped by another controller
    UIViewController *lastViewController = [self lastVisibleViewControllerCompletelyVisible:YES];
    if (lastViewController.containerView.right <= [self screenWidth]) {
        newFirstVisibleIndex = [self.viewControllers indexOfObject:lastViewController];
    }    
    self.firstVisibleIndex = newFirstVisibleIndex;
    
    // don't get all too excited about the new index - it may be wrong! (e.g. too high stacking)
    [self checkAndDecreaseFirstVisibleIndexIfPossible];
    
#ifdef kPSSVStackedViewKitDebugEnabled
    if (oldFirstVisibleIndex != self.firstVisibleIndex) {
        PSSVLog(@"updating firstVisibleIndex from %d to %d", oldFirstVisibleIndex, self.firstVisibleIndex);
    }
#endif
    
    if (animated) {
        [UIView commitAnimations];
    }
}

- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    CGPoint translatedPoint = [recognizer translationInView:self.view];
    
    // reset last offset if gesture just started
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        lastDragOffset_ = 0;
    }
    
    NSInteger offset = translatedPoint.x - lastDragOffset_;
    UIGestureRecognizerState state = recognizer.state;
    
    // if the move does not make sense (no snapping region), only use 1/2 offset
    BOOL snapPointAvailable = [self snapPointAvailableAfterOffset:offset];
    if (!snapPointAvailable) {
        PSSVLog(@"offset dividing/2 in effect");
        
        // we only want to move full pixels - but if we drag slowly, 1 get divided to zero.
        // so only omit every second event
        if (abs(offset) == 1) {
            if(!lastDragDividedOne_) {
                lastDragDividedOne_ = YES;
                offset = 0;
            }else {
                lastDragDividedOne_ = NO;
            }
        }else {
            offset = roundf(offset/2.f);
        }
    }
    [self moveStackWithOffset:offset animated:NO userDragging:YES];
    
    // set up designated drag destination
    if (state == UIGestureRecognizerStateBegan) {
        if (offset > 0) {
            lastDragOption_ = SVSnapOptionRight;
        }else {
            lastDragOption_ = SVSnapOptionLeft;
        }
    }else {
        // if there's a continuous drag in one direction, keep designation - else use nearest to snap.
        if ((lastDragOption_ == SVSnapOptionLeft && offset > 0) || (lastDragOption_ == SVSnapOptionRight && offset < 0)) {
            lastDragOption_ = SVSnapOptionNearest;
        }
    }
    
    // save last point to calculate new offset
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
        lastDragOffset_ = translatedPoint.x;
    }
    
    // perform snapping after gesture ended
    BOOL gestureEnded = state == UIGestureRecognizerStateEnded;
    if (gestureEnded) {
        
        if (lastDragOption_ == SVSnapOptionRight) {
            
            // with manually snapping right, the index gets changed. revert that.
            if (self.firstVisibleIndex+1 < [self.viewControllers count]) {
                self.firstVisibleIndex++;
                
                // special condition: we dragged menu to border
                if ([self firstViewController].containerView.left > [self minimalLeftInset]) {
                    self.firstVisibleIndex--;
                }
            }
            
            [self expandStack:1 animated:YES];
        }else if(lastDragOption_ == SVSnapOptionLeft) {
            [self collapseStack:1 animated:YES];
        }else {
            [self alignStackAnimated:YES];
        }
    }
}

/*
 - (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
 UITouch *touch = [touches anyObject];
 CGPoint touchPoint = [touch locationInView:self.view];
 //   [self stopStackAnimation];
 [self handlePanFrom:touchPoint state:UIGestureRecognizerStateBegan];
 }
 
 - (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
 UITouch *touch = [touches anyObject];
 CGPoint touchPoint = [touch locationInView:self.view];
 [self handlePanFrom:touchPoint state:UIGestureRecognizerStateChanged];
 }
 
 - (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
 UITouch *touch = [touches anyObject];
 CGPoint touchPoint = [touch locationInView:self.view];
 [self handlePanFrom:touchPoint state:UIGestureRecognizerStateEnded];
 }
 
 - (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
 UITouch *touch = [touches anyObject];
 CGPoint touchPoint = [touch locationInView:self.view];
 [self handlePanFrom:touchPoint state:UIGestureRecognizerStateCancelled];
 }*/

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - SVStackRootController (Public)

- (UIViewController *)topViewController {
    return [self.viewControllers lastObject];
}

- (UIViewController *)firstViewController {
    return [self.viewControllers count] ? [self.viewControllers objectAtIndex:0] : nil;
}

- (NSArray *)visibleViewControllers {
    return [self visibleViewControllersSetFullyVisible:NO];
}

- (NSArray *)fullyVisibleViewControllers {
    return [self visibleViewControllersSetFullyVisible:YES];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated; {
    [self pushViewController:viewController fromViewController:self.topViewController animated:animated];
}

- (void)pushViewController:(UIViewController *)viewController fromViewController:(UIViewController *)baseViewController animated:(BOOL)animated; {    
    
    // figure out where to push, and if we need to get rid of some viewControllers
    if (baseViewController) {
        [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIViewController *baseVC = objc_getAssociatedObject(obj, kPSSVAssociatedBaseViewControllerKey);
            if (baseVC == baseViewController) {
                PSSVLog(@"BaseViewController found on index: %d", idx);
                [self popToViewController:(UIViewController *)obj animated:animated];
                *stop = YES;
            }
        }];
        
        objc_setAssociatedObject(viewController, kPSSVAssociatedBaseViewControllerKey, baseViewController, OBJC_ASSOCIATION_ASSIGN); // associate weak
    }
    
    PSSVLog(@"pushing with index %d on stack: %@ (animated: %d)", [self.viewControllers count], viewController, animated);    
    viewController.view.height = PSIsLandscape() ? self.view.width : self.view.height;
    
    // Starting out in portrait, right side up, we see a 20 pixel gap (for status bar???)
    viewController.view.top = 0.f;
    
    // controller view is embedded into a container
    PSSVContainerView *container = [PSSVContainerView containerViewWithController:viewController];
    NSUInteger leftGap = [self totalStackWidth] + [self minimalLeftInset];    
    container.left = leftGap;
    container.width = viewController.view.width;
    container.autoresizingMask = UIViewAutoresizingFlexibleHeight; // width is not flexible!
    [container limitToMaxWidth:[self maxControllerWidth]];
    PSSVLog(@"container frame: %@", NSStringFromCGRect(container.frame));
    
    // relay willAppear and add to subview
    [viewController viewWillAppear:animated];
    [self.view addSubview:container];
    
    // properly sizes the scroll view contents (for table view scrolling)
    [container layoutIfNeeded];
    
    [viewController viewDidAppear:animated];    
    [viewControllers_ addObject:viewController];
    
    // register stack controller
    objc_setAssociatedObject(viewController, kPSSVAssociatedStackViewControllerKey, self, OBJC_ASSOCIATION_ASSIGN);
    
    [self updateViewControllerMasksAndShadow];
    [self displayViewControllerIndexOnRightMost:[self.viewControllers count]-1 animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated; {
    PSSVLog(@"popping controller: %@ (#%d total, animated:%d)", [self topViewController], [self.viewControllers count], animated);
    
    UIViewController *lastController = [self topViewController];
    if (lastController) {        
        
        PSSVContainerView *container = lastController.containerView;
        
        // remove from view stack!
        [lastController viewWillDisappear:animated];
        
        if (animated) {
            [UIView animateWithDuration:kPSSVStackAnimationDuration delay:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
                lastController.containerView.alpha = 0.f;
            } completion:^(BOOL finished) {
                if (finished) {
                    [container removeFromSuperview];
                    [lastController viewDidDisappear:animated];
                }
            }];
        }else {
            [container removeFromSuperview];
            [lastController viewDidDisappear:animated];
        }
        
        [viewControllers_ removeLastObject];
        
        // save current stack controller as an associated object.
        objc_setAssociatedObject(lastController, kPSSVAssociatedStackViewControllerKey, nil, OBJC_ASSOCIATION_ASSIGN);
        
        [self updateViewControllerMasksAndShadow];
        
        // realign view controllers
        [self alignStackAnimated:animated];
    }
    
    return lastController;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated; {
    NSMutableArray *array = [NSMutableArray array];
    while ([self.viewControllers count] > 0) {
        UIViewController *vc = [self popViewControllerAnimated:animated];
        [array addObject:vc];
    }
    return array;
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated; {
    NSParameterAssert(viewController);
    
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    if (NSNotFound == index) {
        return nil;
    }
    PSSVLog(@"popping to index %d, from %d", index, [self.viewControllers count]);
    
    NSMutableArray *array = [NSMutableArray array];
    while ([self.viewControllers count] > index) {
        UIViewController *vc = [self popViewControllerAnimated:animated];
        [array addObject:vc];
    }
    
    return array;
}

// last visible index is calculated dynamically, depending on width of VCs
- (NSInteger)lastVisibleIndex {
    NSInteger lastVisibleIndex = self.firstVisibleIndex;
    
    NSUInteger currentLeftInset = [self currentLeftInset];
    NSInteger screenSpaceLeft = [self screenWidth] - currentLeftInset;
    while (screenSpaceLeft > 0 && lastVisibleIndex < [self.viewControllers count]) {
        UIViewController *vc = [self.viewControllers objectAtIndex:lastVisibleIndex];
        screenSpaceLeft -= vc.containerView.width;
        
        if (screenSpaceLeft >= 0) {
            lastVisibleIndex++;
        }        
    }
    
    if (lastVisibleIndex > 0) {
        lastVisibleIndex--; // compensate for last failure
    }
    
    return lastVisibleIndex;
}

/*
 #define kPSSVAnimationBlockerViewTag 832242
 - (void)removeAnimationBlockerView {
 UIView *animationBlockView = [self.view viewWithTag:kPSSVAnimationBlockerViewTag];
 [animationBlockView removeFromSuperview];
 }
 
 - (void)removeAnimationBlockerViewAndStopAnimation {
 [self removeAnimationBlockerView];
 [self stopStackAnimation];
 }
 
 - (void)addAnimationBlockerView {
 return;
 
 if (![self.view viewWithTag:kPSSVAnimationBlockerViewTag]) {
 UIControl *control = [[[UIControl alloc] initWithFrame:self.view.bounds] autorelease];
 control.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];//clearColor];
 [control addTarget:self action:@selector(removeAnimationBlockerViewAndStopAnimation) forControlEvents:UIControlEventTouchDown];
 control.tag = kPSSVAnimationBlockerViewTag;
 [self.view addSubview:control];
 }
 }*/

// returns +/- amount if grid is not aligned correctly
// + if view is too far on the right, - if too far on the left
- (CGFloat)gridOffsetByPixels {
    CGFloat gridOffset = 0;
    
    CGFloat firstVCLeft = self.firstViewController.containerView.left;
    
    // easiest case, controller is > then wide menu
    if (firstVCLeft > [self currentLeftInset] || firstVCLeft < [self currentLeftInset]) {
        gridOffset = firstVCLeft - [self currentLeftInset];
    }else {
        NSUInteger targetIndex = self.firstVisibleIndex; // default, abs(gridOffset) < 1
        
        UIViewController *overlappedVC = [self overlappedViewController];
        if (overlappedVC) {
            UIViewController *rightVC = [self nextViewController:overlappedVC];
            targetIndex = [self.viewControllers indexOfObject:rightVC];
            PSSVLog(@"overlapping %@ with %@", NSStringFromCGRect(overlappedVC.containerView.frame), NSStringFromCGRect(rightVC.containerView.frame));
        }
        
        UIViewController *targetVCController = [self.viewControllers objectAtIndex:targetIndex];
        CGRect targetVCFrame = [self rectForControllerAtIndex:targetIndex];
        gridOffset = targetVCController.containerView.left - targetVCFrame.origin.x;
    }
    
    PSSVLog(@"gridOffset: %f", gridOffset);
    return gridOffset;
}

/// detect if last drag offset is large enough that we should make a snap animation
- (BOOL)shouldSnapAnimate {
    BOOL shouldSnapAnimate = abs(lastDragOffset_) > 10;
    return shouldSnapAnimate;
}

// bouncing is a three-way operation
enum {
    PSSVBounceNone,
    PSSVBounceMoveToInitial,
    PSSVBounceBleedOver,
    PSSVBounceBack,    
}typedef PSSVBounceOption;

- (void)alignStackAnimated:(BOOL)animated duration:(CGFloat)duration bounceType:(PSSVBounceOption)bounce; {
    if (animated) {
        [UIView beginAnimations:@"kPSSVStackAnimation" context:[[NSNumber numberWithInt:bounce] retain]];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
        
        CGFloat gridOffset = [self gridOffsetByPixels];
        [UIView setAnimationDuration:duration];
        
        if (bounce == PSSVBounceMoveToInitial) {
            if (![self shouldSnapAnimate]) {
                [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            }else {
                [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            }
            snapBackFromLeft_ = gridOffset < 0;
            
            // some magic numbers to better reflect movement time
            duration = abs(gridOffset)/200.f * duration * 0.4f + duration * 0.6f;
            [UIView setAnimationDuration:duration];
            
        }else if(bounce == PSSVBounceBleedOver) {
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        }
    }
    
    PSSVLog(@"Begin aliging VCs. Last drag offset:%d direction:%d bounce:%d.", lastDragOffset_, lastDragOption_, bounce);
    
    // calculate offset used only when we're bleeding over
    NSInteger snapOverOffset = 0; // > 0 = <--- ; we scrolled from right to left.
    NSUInteger firstVisibleIndex = [self firstVisibleIndex];
    NSUInteger lastFullyVCIndex = [self.viewControllers indexOfObject:[self lastVisibleViewControllerCompletelyVisible:YES]];
    BOOL bounceAtVeryEnd = NO;
    
    if ([self shouldSnapAnimate] && bounce == PSSVBounceBleedOver) {
        snapOverOffset = abs(lastDragOffset_ / 5.f);
        if (snapOverOffset > kPSSVMaxSnapOverOffset) {
            snapOverOffset = kPSSVMaxSnapOverOffset;
        }
        
        // positive/negative snap offset depending on snap back direction
        snapOverOffset *= snapBackFromLeft_ ? 1 : -1;
        
        
        // if we're dragging menu all the way out, bounce back in
        PSSVLog(@"%@", NSStringFromCGRect(self.firstViewController.containerView.frame));
        CGFloat firstVCLeft = self.firstViewController.containerView.left;
        if (firstVisibleIndex == 0 && !snapBackFromLeft_ && firstVCLeft >= self.largeLeftInset) {
            bounceAtVeryEnd = YES;
        }else if(lastFullyVCIndex == [self.viewControllers count]-1 && lastFullyVCIndex > 0) { //&& snapBackFromLeft_ 
            
            bounceAtVeryEnd = YES;
        }
        
        PSSVLog(@"bouncing with offset: %d, firstIndex:%d, snapToLeft:%d veryEnd:%d", snapOverOffset, firstVisibleIndex, snapOverOffset<0, bounceAtVeryEnd);
    }
    
    // iterate over all view controllers and snap them to their correct positions
    __block NSArray *frames = [self rectsForControllers];
    [self.viewControllers enumerateObjectsWithOptions:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *currentVC = (UIViewController *)obj;
        
        CGRect currentFrame = [[frames objectAtIndex:idx] CGRectValue];
        currentVC.containerView.left = currentFrame.origin.x;

        // menu drag to right case or swiping last vc towards menu
        if (bounceAtVeryEnd) {
            if (idx == firstVisibleIndex) {
                frames = [self modifiedRects:frames newLeft:currentVC.containerView.left + snapOverOffset index:idx];
            }
        }
        // snap the leftmost view controller
        else if ((snapOverOffset > 0 && idx == firstVisibleIndex) || (snapOverOffset < 0 && (idx == firstVisibleIndex+1))
                 || [self.viewControllers count] == 1) {
            frames = [self modifiedRects:frames newLeft:currentVC.containerView.left + snapOverOffset index:idx];
        }
        
        // set again (maybe changed)
        currentFrame = [[frames objectAtIndex:idx] CGRectValue];
        currentVC.containerView.left = currentFrame.origin.x;
    }];
    
    [self updateViewControllerMasksAndShadow];
    
    if (animated) {
        [UIView commitAnimations];
        //[self addAnimationBlockerView];
    }    
}

- (void)alignStackAnimated:(BOOL)animated; {
    [self checkAndDecreaseFirstVisibleIndexIfPossible];
    [self alignStackAnimated:animated duration:kPSSVStackAnimationDuration bounceType:PSSVBounceMoveToInitial];
}


/*  Scroll physics are applied here. Drag speed is saved in lastDragOffset. (direction with +/-, speed)
 *  If we are above a certain speed, we "shoot over the target", then snap back. 
 *  This is of course dependent on the direction we scrolled.
 *
 *  Right swiping (collapsing) makes the next vc overlapping the current vc a few pixels.
 *  Left swiping (expanding) takes the parent controller a few pixels with, then snapping back.
 *
 *  We have 3 animations total
 *   1) scroll to correct position
 *   2) bleed over
 *   3) snap back to correct position
 */
- (void)bounceBack:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {	
    PSSVBounceOption bounceOption = [(NSNumber *)context integerValue];
    
    // animation was stopped
    if (![finished boolValue]) {
        PSSVLog(@"animation didn't finish, stopping here at bounce option: %d", bounceOption);
        //[self removeAnimationBlockerView];
        return;
    }
    
    if ([self shouldSnapAnimate]) {
        CGFloat animationDuration = kPSSVStackAnimationBounceDuration/2.f;
        switch (bounceOption) {
            case PSSVBounceMoveToInitial: {
                // bleed over now!
                [self alignStackAnimated:YES duration:animationDuration bounceType:PSSVBounceBleedOver];
            }break;
            case PSSVBounceBleedOver: {
                // now bounce back to origin
                [self alignStackAnimated:YES duration:animationDuration bounceType:PSSVBounceBack];
            }break;
                
                // we're done here
            case PSSVBounceNone:
            case PSSVBounceBack:
            default: {
                lastDragOffset_ = 0; // clear last drag offset for the animation
                //[self removeAnimationBlockerView];
            }break;
        }
    }
}

- (NSUInteger)canCollapseStack; {
    NSUInteger steps = [self.viewControllers count] - self.firstVisibleIndex - 1;
    
    if (self.lastVisibleIndex == [self.viewControllers count]-1) {
        //PSSVLog(@"complete stack is displayed - aborting.");
        steps = 0;
    }else if (self.firstVisibleIndex + steps > [self.viewControllers count]-1) {
        steps = [self.viewControllers count] - self.firstVisibleIndex - 1;
        //PSSVLog(@"too much steps, adjusting to %d", steps);
    }
    
    return steps;
}


- (NSUInteger)collapseStack:(NSUInteger)steps animated:(BOOL)animated; { // (<--- increases firstVisibleIndex)
    PSSVLog(@"collapsing stack with %d steps [%d-%d]", steps, self.firstVisibleIndex, self.lastVisibleIndex);
    
    // sliding menu is it's own step
    if([self isMenuCollapsable] && self.isShowingFullMenu) {
        self.showingFullMenu = NO;
        steps--;
    }
    
    NSUInteger maxCollapseStackCount = [self canCollapseStack];
    if (steps > maxCollapseStackCount) {
        steps = maxCollapseStackCount;
    }
    
    // hide older VCs, show newer ones
    self.firstVisibleIndex += steps;
    
    [self alignStackAnimated:animated];
    return steps;
}

- (NSUInteger)canExpandStack; {
    NSUInteger steps = self.firstVisibleIndex;
    
    // sanity check
    if (steps >= [self.viewControllers count]-1) {
        PSSVLog(@"Warning: firstVisibleIndex is higher than viewController count!");
        steps = [self.viewControllers count]-1;
    }
    
    return steps;
}

- (NSUInteger)expandStack:(NSUInteger)steps animated:(BOOL)animated; { // (---> decreases firstVisibleIndex)
    PSSVLog(@"expanding stack with %d steps [%d-%d]", steps, self.firstVisibleIndex, self.lastVisibleIndex);
    
    if (self.firstVisibleIndex < steps) {
        steps = self.firstVisibleIndex;
        PSSVLog(@"Warn! steps are too high! adjusting to %d", steps);
    }
    
    NSUInteger maxExpandStackCount = [self canExpandStack];
    if (steps > maxExpandStackCount) {
        steps = maxExpandStackCount;
    }
    
    if (steps == 0 && self.firstVisibleIndex == 0) {
        self.showingFullMenu = YES;
    }else {
        // show older VCs!
        self.firstVisibleIndex -= steps;
    }
    
    [self alignStackAnimated:animated];
    return steps; 
}

- (void)setLeftInset:(NSUInteger)leftInset {
    [self setLeftInset:leftInset animated:NO];
}

- (void)setLeftInset:(NSUInteger)leftInset animated:(BOOL)animated; {
    leftInset_ = leftInset;
    [self alignStackAnimated:animated];
}

- (void)setLargeLeftInset:(NSUInteger)leftInset {
    [self setLargeLeftInset:leftInset animated:NO];
}

- (void)setLargeLeftInset:(NSUInteger)leftInset animated:(BOOL)animated; {
    largeLeftInset_ = leftInset;
    [self alignStackAnimated:animated];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // embedding rootViewController
    if (self.rootViewController) {
        [self.view addSubview:self.rootViewController.view];
        self.rootViewController.view.frame = self.view.bounds;
        self.rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    for (UIViewController *controller in self.viewControllers) {
        // forces view loading, calls viewDidLoad via system
        UIView *controllerView = controller.view;
#pragma unused(controllerView)
        //        [controller viewDidLoad];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.rootViewController viewWillAppear:animated];
    for (UIViewController *controller in self.viewControllers) {
        [controller viewWillAppear:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.rootViewController viewDidAppear:animated];
    for (UIViewController *controller in self.viewControllers) {
        [controller viewDidAppear:animated];
    }   
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.rootViewController viewWillDisappear:animated];
    for (UIViewController *controller in self.viewControllers) {
        [controller viewWillDisappear:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.rootViewController viewDidDisappear:animated];
    for (UIViewController *controller in self.viewControllers) {
        [controller viewDidDisappear:animated];
    }   
}

- (void)viewDidUnload {
    [self.rootViewController.view removeFromSuperview];
    self.rootViewController.view = nil;
    [self.rootViewController viewDidUnload];
    
    for (UIViewController *controller in self.viewControllers) {
        [controller.view removeFromSuperview];
        controller.view = nil;
        [controller viewDidUnload];
    }
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (PSIsIpad()) {
        return YES;
    }else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}

// event relay
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration; {
    lastVisibleIndexBeforeRotation_ = self.lastVisibleIndex;
    
    [rootViewController_ willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    for (UIViewController *controller in self.viewControllers) {
        [controller willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }    
}

// event relay
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation; {
    [rootViewController_ didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    for (UIViewController *controller in self.viewControllers) {
        [controller didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }        
    
    [self updateViewControllerMasksAndShadow];
}

// event relay
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration; {
    [rootViewController_ willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self updateViewControllerSizes];
    [self updateViewControllerMasksAndShadow];    
    
    // enlarge/shrinken stack
    [self displayViewControllerIndexOnRightMost:lastVisibleIndexBeforeRotation_ animated:YES];
    
    // finally relay rotation events
    for (UIViewController *controller in self.viewControllers) {
        [controller willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) {
        // prevent recognizing touches on the slider
        return NO;
    }
    return YES;
}

@end
