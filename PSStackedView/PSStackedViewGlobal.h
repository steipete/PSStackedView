//
//  SVStackedViewKitGlobal.h
//  StackedViewKit
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "UIView+PSSizes.h"

#define kPSSVStackedViewKitDebugEnabled

#define PSIsIpad() ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define PSAppStatusBarOrientation ([[UIApplication sharedApplication] statusBarOrientation])
#define PSIsPortrait()  UIInterfaceOrientationIsPortrait(PSAppStatusBarOrientation)
#define PSIsLandscape() UIInterfaceOrientationIsLandscape(PSAppStatusBarOrientation)
#define PSIsIpad() ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#ifdef kPSSVStackedViewKitDebugEnabled
#define PSLog(fmt, ...) NSLog((@"%s/%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define PSLog(...)
#endif
