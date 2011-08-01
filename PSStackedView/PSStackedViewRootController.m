//
//  SVStackRootController.m
//  PSStackedView
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSStackedViewRootController.h"
#import "PSStackedViewGlobal.h"
#import "PSSVContainerView.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define kPSSVStackAnimationDuration 0.3f
#define kPSSVStackAnimationBounceDuration 0.4f
#define kPSSVMaxSnapOverOffset 40
#define kPSSVStackAnimationPopDuration 0.15f
#define kPSSVAssociatedBaseViewControllerKey @"kPSSVAssociatedBaseViewController"
#define kPSSVAssociatedStackViewControllerKey @"kPSSVAssociatedStackViewController"

@implementation UIViewController (PSStackedViewAdditions)

// returns the containerView, where view controllers are embedded
- (PSSVContainerView *)containerView; { return ([self.view.superview isKindOfClass:[PSSVContainerView class]] ? (PSSVContainerView *)self.view.superview : nil); }

// returns the stack controller if the viewController is embedded
- (PSStackedViewRootController *)stackController; {
    PSStackedViewRootController *stackController = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerKey);
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

@interface PSStackedViewRootController() <UIGestureRecognizerDelegate> 

@property (nonatomic, retain) UIViewController *rootViewController;
@property(nonatomic, assign) NSMutableArray* viewControllers;
@property(nonatomic, assign) NSInteger firstVisibleIndex;
@property(nonatomic, assign, getter=isShowingFullMenu) BOOL showingFullMenu;

@end

@implementation PSStackedViewRootController

@synthesize leftInset = leftInset_;
@synthesize largeLeftInset = largeLeftInset_;
@synthesize viewControllers = viewControllers_;
@synthesize showingFullMenu  = showingFullMenu_;
@synthesize firstVisibleIndex = firstVisibleIndex_;
@synthesize rootViewController = rootViewController_;
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
        [panRecognizer setDelaysTouchesBegan:YES];
        [panRecognizer setDelaysTouchesEnded:YES];
        [panRecognizer setCancelsTouchesInView:YES];
        [self.view addGestureRecognizer:panRecognizer];

        
#ifdef ALLOW_SWIZZLING_NAVIGATIONCONTROLLER
        PSLog("Swizzling UIViewController.navigationController");
        Method origMethod = class_getInstanceMethod([UIViewController class], @selector(navigationController));
        Method overrideMethod = class_getInstanceMethod([UIViewController class], @selector(navigationControllerSwizzled));
        method_exchangeImplementations(origMethod, overrideMethod);
#endif
    }
    return self;
}

- (void)dealloc {
    // remove all view controllers the hard way
    while ([self.viewControllers count]) {
        [self popViewControllerAnimated:NO];
    }
    
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


// at some point, dragging does not make any more sense
- (BOOL)snapPointAvailableAfterOffset:(NSInteger)offset {
    BOOL snapPointAvailableAfterOffset = YES;
    NSUInteger screenWidth = [self screenWidth];
    NSUInteger totalWidth = [self totalStackWidth];
    NSUInteger minCommonWidth = MIN(screenWidth, totalWidth);
    
    // are we at the end?
    UIViewController *topViewController = [self topViewController];
    if (topViewController == [self lastVisibleViewControllerCompletelyVisible:YES]) {
        if (minCommonWidth+[self minimalLeftInset] <= topViewController.containerView.right) {
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

// ensures index is on rightmost position
- (void)displayViewControllerIndexOnRightMost:(NSUInteger)index animated:(BOOL)animated; {
    NSInteger indexOffset = index - self.lastVisibleIndex;
    if (indexOffset > 0) {
        [self collapseStack:indexOffset animated:animated];
    }else if(indexOffset >= 0) {
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

// updates view containers
- (void)updateViewControllerMasksAndShadow {
    // ensure no controller is larger than the screen width
    NSUInteger maxWidth = [self screenWidth] - [self minimalLeftInset];
    for (UIViewController *controller in self.viewControllers) {
        if(controller.view.width > maxWidth) {
            PSLog(@"Warning! Resizing controller %@ (rect:%@)to fit max screen width of %d", controller, NSStringFromCGRect(controller.view.frame), maxWidth);
            controller.view.width = maxWidth;
        }
    }
    
    // only one!
    if ([self.viewControllers count] == 1) {
        [[self firstViewController].containerView addMaskToCorners:UIRectCornerAllCorners];
        [[self firstViewController].containerView addShadowToSides:PSSVSideLeft | PSSVSideRight];
    }else {
        // rounded corners on first and last controller
        [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIViewController *vc = (UIViewController *)obj;
            if (idx == 0) {
                [vc.containerView addShadowToSides:PSSVSideLeft];
                [vc.containerView addMaskToCorners:UIRectCornerBottomLeft | UIRectCornerTopLeft];
            }else if(idx == [self.viewControllers count]-1) {
                [vc.containerView addMaskToCorners:UIRectCornerBottomRight | UIRectCornerTopRight];
                [vc.containerView addShadowToSides:PSSVSideLeft | PSSVSideRight];
            }else {
                [vc.containerView removeMask];
                [vc.containerView addShadowToSides:PSSVSideLeft | PSSVSideRight];
            }
        }];
    }
}

- (NSSet *)visibleViewControllersSetFullyVisible:(BOOL)fullyVisible; {
    NSMutableSet *set = [NSMutableSet set];    
    [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([self isViewControllerVisible:obj completely:fullyVisible]) {
            [set addObject:obj];
        }
    }];
    
    return [[set copy] autorelease];
}


// check if there is any overlapping going on between VCs
- (BOOL)isViewController:(UIViewController *)leftViewController overlappingWith:(UIViewController *)rightViewController {
    NSParameterAssert(leftViewController);
    NSParameterAssert(rightViewController);
    
    // figure out which controller is the top one
    if ([self.viewControllers indexOfObject:rightViewController] < [self.viewControllers indexOfObject:leftViewController]) {
        PSLog(@"overlapping check flipped! fixing that...");
        UIViewController *tmp = rightViewController;
        rightViewController = leftViewController;
        leftViewController = tmp;
    }
    
    BOOL overlapping = leftViewController.containerView.right > rightViewController.containerView.left;
    if (overlapping) {
        PSLog(@"overlap detected: %@ (%@) with %@ (%@)", leftViewController, NSStringFromCGRect(leftViewController.containerView.frame), rightViewController, NSStringFromCGRect(rightViewController.containerView.frame));
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
#pragma mark - SVStackRootController (Public)

- (UIViewController *)topViewController {
    return [self.viewControllers lastObject];
}

- (UIViewController *)firstViewController {
    return [self.viewControllers count] ? [self.viewControllers objectAtIndex:0] : nil;
}

- (NSSet *)visibleViewControllers {
    return [self visibleViewControllersSetFullyVisible:NO];
}

- (NSSet *)fullyVisibleViewControllers {
    return [self visibleViewControllersSetFullyVisible:YES];
}

- (void)pushViewController:(UIViewController *)viewController fromViewController:(UIViewController *)baseViewController animated:(BOOL)animated; {    
    
    // figure out where to push, and if we need to get rid of some viewControllers
    if (baseViewController) {
        [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIViewController *baseVC = objc_getAssociatedObject(obj, kPSSVAssociatedBaseViewControllerKey);
            if (baseVC == baseViewController) {
                PSLog(@"BaseViewController found on index: %d", idx);
                [self popToViewController:(UIViewController *)obj animated:animated];
                *stop = YES;
            }
        }];
        
        objc_setAssociatedObject(viewController, kPSSVAssociatedBaseViewControllerKey, baseViewController, OBJC_ASSOCIATION_ASSIGN); // associate weak
    }
    
    PSLog(@"pushing with index %d on stack: %@ (animated: %d)", [self.viewControllers count], viewController, animated);
    
    if ([viewController respondsToSelector:@selector(stackableMaxWidth)]) {
        viewController.view.width = [(UIViewController<PSStackedViewDelegate> *)viewController stackableMaxWidth];
    }
    viewController.view.height = PSIsLandscape() ? self.view.width : self.view.height;
    
    // Starting out in portrait, right side up, we see a 20 pixel gap (for status bar???)
    viewController.view.top = 0.f;
    
    // add to view stack!
    [viewController viewWillAppear:animated];
    
    // controller view is embedded into a container
    PSSVContainerView *container = [PSSVContainerView containerViewWithController:viewController];
    NSUInteger leftGap = [self totalStackWidth] + [self minimalLeftInset];    
    container.left = leftGap;
    container.width = viewController.view.width;
    container.autoresizingMask = UIViewAutoresizingFlexibleHeight; // width is not flexible!
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
    PSLog(@"popping controller: %@ (#%d total, animated:%d)", [self topViewController], [self.viewControllers count], animated);
    
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

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated; {
    NSParameterAssert(viewController);
    
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    if (NSNotFound == index) {
        return nil;
    }
    PSLog(@"popping to index %d, from %d", index, [self.viewControllers count]);
    
    NSMutableArray *array = [NSMutableArray array];
    while ([self.viewControllers count] > index) {
        [self popViewControllerAnimated:animated];
    }
    
    return array;
}

- (void)stopStackAnimation {
    // remove all current animations
    //[self.view.layer removeAllAnimations];
    [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *vc = (UIViewController *)obj;
        CGRect currentPos = [[vc.containerView.layer presentationLayer] frame];
        [vc.containerView.layer removeAllAnimations];
        vc.containerView.frame = currentPos;
    }];
}

// moves the stack to a specific offset. 
- (void)moveStackWithOffset:(NSInteger)offset animated:(BOOL)animated userDragging:(BOOL)userDragging {
    PSLog(@"moving stack on %d pixels (animated:%d, decellerating:%d)", offset, animated, userDragging);
    
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
    
    // update firstVisibleIndex
#ifdef kPSSVStackedViewKitDebugEnabled
    NSUInteger oldFirstVisibleIndex = self.firstVisibleIndex;
#endif
    
    NSInteger minLeft = [self firstViewController].containerView.left;
    for (UIViewController *vc in self.viewControllers) {
        NSInteger vcLeft = vc.containerView.left;
        if (minLeft < vcLeft) {
            self.firstVisibleIndex = [self.viewControllers indexOfObject:vc]-1;
            break;
        }
    }
    
    // don't get all too excited about the new index - it may be wrong! (e.g. too high stacking)
    [self checkAndDecreaseFirstVisibleIndexIfPossible];
    
#ifdef kPSSVStackedViewKitDebugEnabled
    if (oldFirstVisibleIndex != self.firstVisibleIndex) {
        PSLog(@"updating firstVisibleIndex from %d to %d", oldFirstVisibleIndex, self.firstVisibleIndex);
    }
#endif
    
    if (animated) {
        [UIView commitAnimations];
    }
}

// last visible index is calculated dynamically, depending on width of VCs
- (NSInteger)lastVisibleIndex {
    NSInteger lastVisibleIndex = self.firstVisibleIndex;
    
    NSInteger screenSpaceLeft = [self screenWidth] - [self currentLeftInset];
    while (screenSpaceLeft > 0 && lastVisibleIndex < [self.viewControllers count]) {
        UIViewController *vc = [self.viewControllers objectAtIndex:lastVisibleIndex];
        screenSpaceLeft -= vc.containerView.width;
        
        if (screenSpaceLeft >= 0) {
            lastVisibleIndex++;
        }        
    }
    
    lastVisibleIndex--; // compensate for last failure
    
    return lastVisibleIndex;
}

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

        // calculate remaining duration based on distance of overlapping
        UIViewController *overlappedVC = [self overlappedViewController];
        if (overlappedVC) {
            UIViewController *rightVC = [self nextViewController:overlappedVC];
            PSLog(@"overlapping %@ with %@", NSStringFromCGRect(overlappedVC.containerView.frame), NSStringFromCGRect(rightVC.containerView.frame));
            CGFloat overlappingRatio = (overlappedVC.containerView.right - rightVC.containerView.left)/(CGFloat)overlappedVC.containerView.width;
            
            // now we need to know in what direct we're snapping too
            if (lastDragOption_ == SVSnapOptionLeft) {
                overlappingRatio = 1-overlappingRatio;
            }
            duration = duration * overlappingRatio;
        }
        
        [UIView setAnimationDuration:duration];

        
        if (bounce == PSSVBounceMoveToInitial) {
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        }else if(bounce == PSSVBounceBleedOver) {
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        }
    }
        
    PSLog(@"Begin aliging VCs. Last drag offset:%d direction:%d bounce:%d.", lastDragOffset_, lastDragOption_, bounce);
    
    // calculate offset used only when we're bleeding over
    NSInteger snapOverOffset = 0; // > 0 = <--- ; we scrolled from right to left.
    NSUInteger firstVisibleIndex = [self firstVisibleIndex];
    NSUInteger lastFullyVCIndex = [self.viewControllers indexOfObject:[self lastVisibleViewControllerCompletelyVisible:YES]];
    BOOL bounceAtVeryEnd = NO;
    
    if (abs(lastDragOffset_) > 10 && bounce == PSSVBounceBleedOver) {
        snapOverOffset = lastDragOffset_ / 5.f;
        if (snapOverOffset > kPSSVMaxSnapOverOffset) {
            snapOverOffset = kPSSVMaxSnapOverOffset;
        }

        // if we're dragging menu all the way out, bounce back in
        PSLog(@"%@", NSStringFromCGRect(self.firstViewController.containerView.frame));
        if (firstVisibleIndex == 0 && self.firstViewController.containerView.left >= self.leftInset && lastDragOption_ == SVSnapOptionRight) {
            bounceAtVeryEnd = YES;
        }else if(lastFullyVCIndex == [self.viewControllers count]-1 && lastDragOption_ == SVSnapOptionLeft) {
            bounceAtVeryEnd = YES;
        }

        PSLog(@"bouncing with offset: %d, firstIndex:%d, snapToLeft:%d veryEnd:%d", snapOverOffset, firstVisibleIndex, snapOverOffset<0, bounceAtVeryEnd);
    }
        
    // iterate over all view controllers and snap them to their correct positions
    [self.viewControllers enumerateObjectsWithOptions:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *currentVC = (UIViewController *)obj;
        UIViewController *leftVC = [self previousViewController:currentVC];
        
        if (idx <= self.firstVisibleIndex) {
            // collapsed = snap to menu
            currentVC.containerView.left = [self currentLeftInset];
        }else {
            // connect vc to left vc's right!
            currentVC.containerView.left = leftVC.containerView.right;
        }
        
        // menu drag to right case or swiping last vc towards menu
        if (bounceAtVeryEnd) {
            if (idx == firstVisibleIndex) {
                currentVC.containerView.left -= snapOverOffset;
            }
        }
        // snap the leftmost view controller
        else if (snapOverOffset > 0 && idx == firstVisibleIndex) {
            // different snapping if we're at the first index (menu)
            BOOL isOverMenu = firstVisibleIndex == 0 && currentVC.containerView.left > self.leftInset;
            currentVC.containerView.left += snapOverOffset * (isOverMenu ? -1 : 1);
        }else if(snapOverOffset < 0 && idx == firstVisibleIndex+1) {
            currentVC.containerView.left += snapOverOffset;
        }
    }];
    
    if (animated) {
        [UIView commitAnimations];
        [self addAnimationBlockerView];
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
        PSLog(@"animation didn't finish, stopping here at bounce option: %d", bounceOption);
        [self removeAnimationBlockerView];
        return;
    }

    switch (bounceOption) {
        case PSSVBounceMoveToInitial: {
            // bleed over now!
            [self alignStackAnimated:YES duration:kPSSVStackAnimationBounceDuration/2.f bounceType:PSSVBounceBleedOver];
        }break;
        case PSSVBounceBleedOver: {
            // now bounce back to origin
            [self alignStackAnimated:YES duration:kPSSVStackAnimationBounceDuration/2.f bounceType:PSSVBounceBack];
        }break;
            
        // we're done here
        case PSSVBounceNone:
        case PSSVBounceBack:
        default: {
            lastDragOffset_ = 0; // clear last drag offset for the animation
            [self removeAnimationBlockerView];
        }break;
    }
}

- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    CGPoint translatedPoint = [recognizer translationInView:self.view];
    
    // reset last offset if gesture just started
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        lastDragOffset_ = 0;
    }
    
    NSInteger offset = translatedPoint.x - lastDragOffset_;
    
    // if the move does not make sense (no snapping region), only use 1/2 offset
    BOOL snapPointAvailable = [self snapPointAvailableAfterOffset:offset];
    if (!snapPointAvailable) {
        PSLog(@"offset dividing/2 in effect");
        
        // we only want to move full pixels - but if we drag slowly, 1 get divided to zero.
        // so only omit every second event
        if (offset == 1) {
            if(!lastDragDividedOne_) {
                lastDragDividedOne_ = YES;
                offset = 0;
            }else {
                lastDragDividedOne_ = NO;
            }
        }else {
            offset = offset/2;            
        }
    }
    [self moveStackWithOffset:offset animated:NO userDragging:YES];
    
    // set up designated drag destination
    if (recognizer.state == UIGestureRecognizerStateBegan) {
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
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        lastDragOffset_ = translatedPoint.x;
    }
    
    // perform snapping after gesture ended
    BOOL gestureEnded = recognizer.state == UIGestureRecognizerStateEnded;
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

- (NSUInteger)canCollapseStack; {
    NSUInteger steps = [self.viewControllers count] - self.firstVisibleIndex - 1;
    
    if (self.lastVisibleIndex == [self.viewControllers count]-1) {
        //PSLog(@"complete stack is displayed - aborting.");
        steps = 0;
    }else if (self.firstVisibleIndex + steps > [self.viewControllers count]-1) {
        steps = [self.viewControllers count] - self.firstVisibleIndex - 1;
        //PSLog(@"too much steps, adjusting to %d", steps);
    }
    
    return steps;
}


- (NSUInteger)collapseStack:(NSUInteger)steps animated:(BOOL)animated; { // (<--- increases firstVisibleIndex)
    PSLog(@"collapsing stack with %d steps [%d-%d]", steps, self.firstVisibleIndex, self.lastVisibleIndex);
    
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
        PSLog(@"Warning: firstVisibleIndex is higher than viewController count!");
        steps = [self.viewControllers count]-1;
    }
    
    return steps;
}

- (NSUInteger)expandStack:(NSUInteger)steps animated:(BOOL)animated; { // (---> decreases firstVisibleIndex)
    PSLog(@"expanding stack with %d steps [%d-%d]", steps, self.firstVisibleIndex, self.lastVisibleIndex);
    
    if (self.firstVisibleIndex < steps) {
        steps = self.firstVisibleIndex;
        PSLog(@"Warn! steps are too high! adjusting to %d", steps);
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
    [self.rootViewController viewWillDisappear:animated];

    for (UIViewController *controller in self.viewControllers) {
        [controller viewWillDisappear:animated];
    }
    
    [super viewWillDisappear:animated];
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
    for (UIViewController *controller in self.viewControllers) {
        [controller willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    
    lastVisibleIndexBeforeRotation_ = self.lastVisibleIndex;
}

// event relay
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation; {
    for (UIViewController *controller in self.viewControllers) {
        [controller didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }    
    
    // enlarge/shrinken stack
    [self displayViewControllerIndexOnRightMost:lastVisibleIndexBeforeRotation_ animated:YES];
}

// event relay
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration; {
    for (UIViewController *controller in self.viewControllers) {
        [controller willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    [self updateViewControllerMasksAndShadow];
}

@end
