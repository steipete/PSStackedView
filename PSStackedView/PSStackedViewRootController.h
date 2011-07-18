//
//  SVStackRootController.h
//  PSStackedView
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSStackedViewDelegate.h"

// grid snapping options
enum {
    SVSnapOptionNearest,
    SVSnapOptionLeft,
    SVSnapOptionRight
} typedef SVSnapOption;

// root controller hosting all stacked controllers
// override controller if you want to fill the background with content (e.g. a menu)
@interface PSStackedViewRootController : UIViewController {
    UIViewController *rootViewController_;
    
    // properites
    NSUInteger backMinWidth_;
    NSUInteger backEmptyWidth_;    
    
    // stack state
    BOOL showingFullMenu_;
    NSInteger firstVisibleIndex_;
    NSMutableArray *viewControllers_;
    
    // internal drag state handling and other messy details
    NSInteger lastDragOffset_;
    SVSnapOption lastDragOption_;
    BOOL lastDragDividedOne_;
    
    NSInteger lastVisibleIndexBeforeRotation_;
}

// the root controller gets the whole background view
- (id)initWithRootViewController:(UIViewController *)rootViewController;

// Uses a horizontal slide transition. Has no effect if the view controller is already in the stack.
// baseViewController is used to remove subviews if a previous controller invokes a new view. can be nil.
- (void)pushViewController:(UIViewController *)viewController fromViewController:(UIViewController *)baseViewController animated:(BOOL)animated;

 // Returns the popped controller.
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

// can we collapse (=hide) viewControllers? Only collapses until screen width is used
- (NSUInteger)canCollapseStack;

// can the stack be further expanded (are some views stacked?)
- (NSUInteger)canExpandStack;

// moves view controller stack to the left, potentially hiding older VCs (increases firstVisibleIndex)
- (NSUInteger)collapseStack:(NSUInteger)steps animated:(BOOL)animated;

// move view controller stack to the right, showing older VCs (decreases firstVisibleIndex)
- (NSUInteger)expandStack:(NSUInteger)steps animated:(BOOL)animated;

// align stack to nearest grid
- (void)alignStackAnimated:(BOOL)animated;

// expands/collapses stack until entered index is topmost right
- (void)displayViewControllerIndexOnRightMost:(NSUInteger)index animated:(BOOL)animated;

 // The top view controller on the stack.
@property(nonatomic, readonly, retain) UIViewController *topViewController;

// view controllers visible. NOT KVO compliant, is calculated on demand.
@property(nonatomic, readonly, retain) NSSet *visibleViewControllers;
@property(nonatomic, readonly, retain) NSSet *fullyVisibleViewControllers;

// index of first currently visible view controller
@property(nonatomic, assign, readonly) NSInteger firstVisibleIndex;

// index of last currently visible view controller (calculated)
@property(nonatomic, assign, readonly) NSInteger lastVisibleIndex;

// array of all current view controllers, sorted
@property(nonatomic, assign, readonly) NSArray* viewControllers;

// toggle full menu / small menu
@property(nonatomic, assign, getter=isShowingFullMenu, readonly) BOOL showingFullMenu;

// width for menu icons only (left gap)
@property(nonatomic, assign) NSUInteger backMinWidth;

// width for menu icons + text
@property(nonatomic, assign) NSUInteger backEmptyWidth;

@end
