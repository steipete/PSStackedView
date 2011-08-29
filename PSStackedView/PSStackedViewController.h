//
//  SVStackRootController.h
//  PSStackedView
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSStackedViewDelegate.h"

// Swizzles UIViewController's navigationController property. DANGER, WILL ROBINSON!
// Only swizzles if a PSStackedViewRootController is created, and also works in peaceful
// coexistance to UINavigationController.
#define ALLOW_SWIZZLING_NAVIGATIONCONTROLLER

/// grid snapping options
enum {
    SVSnapOptionNearest,
    SVSnapOptionLeft,
    SVSnapOptionRight
} typedef PSSVSnapOption;

/// StackController hosing a backside rootViewController and the stacked controllers
@interface PSStackedViewController : UIViewController {
    UIViewController *rootViewController_;
    
    // properites
    NSUInteger leftInset_;
    NSUInteger largeLeftInset_;    
    
    // stack state
    BOOL showingFullMenu_;
    NSInteger firstVisibleIndex_;
    NSMutableArray *viewControllers_;
    
    // internal drag state handling and other messy details
    PSSVSnapOption lastDragOption_;
    BOOL snapBackFromLeft_;
    NSInteger lastDragOffset_;
    BOOL lastDragDividedOne_;
    
    NSInteger lastVisibleIndexBeforeRotation_;
}

/// the root controller gets the whole background view
- (id)initWithRootViewController:(UIViewController *)rootViewController;

/// Uses a horizontal slide transition. Has no effect if the view controller is already in the stack.
/// baseViewController is used to remove subviews if a previous controller invokes a new view. can be nil.
- (void)pushViewController:(UIViewController *)viewController fromViewController:(UIViewController *)baseViewController animated:(BOOL)animated;

/// pushes the view controller, sets the last current vc as parent controller
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// remove top view controller from stack, return it
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;

/// remove view controllers until 'viewController' is found
- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// removes all view controller
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;

/// can we collapse (= hide) view controllers? Only collapses until screen width is used
- (NSUInteger)canCollapseStack;

/// can the stack be further expanded (are some views stacked?)
- (NSUInteger)canExpandStack;

/// moves view controller stack to the left, potentially hiding older VCs (increases firstVisibleIndex)
- (NSUInteger)collapseStack:(NSUInteger)steps animated:(BOOL)animated;

/// move view controller stack to the right, showing older VCs (decreases firstVisibleIndex)
- (NSUInteger)expandStack:(NSUInteger)steps animated:(BOOL)animated;

/// align stack to nearest grid
- (void)alignStackAnimated:(BOOL)animated;

/// expands/collapses stack until entered index is topmost right
- (void)displayViewControllerIndexOnRightMost:(NSInteger)index animated:(BOOL)animated;

/// The top(last) view controller on the stack.
@property(nonatomic, readonly, retain) UIViewController *topViewController;
/// first view controller
@property(nonatomic, readonly, retain) UIViewController *firstViewController;

/// view controllers visible. NOT KVO compliant, is calculated on demand.
@property(nonatomic, readonly, retain) NSArray *visibleViewControllers;

@property(nonatomic, readonly, retain) NSArray *fullyVisibleViewControllers;

/// index of first currently visible view controller [state]
@property(nonatomic, assign, readonly) NSInteger firstVisibleIndex;

/// index of last currently visible view controller [calculated]
@property(nonatomic, assign, readonly) NSInteger lastVisibleIndex;

/// array of all current view controllers, sorted
@property(nonatomic, assign, readonly) NSArray *viewControllers;

/// toggle full menu / small menu
@property(nonatomic, assign, getter=isShowingFullMenu, readonly) BOOL showingFullMenu;

/// left inset thats always visible. Defaults to 60.
@property(nonatomic, assign) NSUInteger leftInset;
/// animate setting of the left inset that is always visible
- (void)setLeftInset:(NSUInteger)leftInset animated:(BOOL)animated;

/// large left inset. is visible to show you the full menu width. Defaults to 200.
@property(nonatomic, assign) NSUInteger largeLeftInset;
/// animate setting of large left inset
- (void)setLargeLeftInset:(NSUInteger)largeLeftInset animated:(BOOL)animated;

// compatibility with UINavigationBar -- returns nil
#ifdef ALLOW_SWIZZLING_NAVIGATIONCONTROLLER
@property(nonatomic, assign) UINavigationBar *navigationBar;
#endif

@end
