//
//  SVStackedViewKitGlobal.h
//  StackedViewKit
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "UIView+PSSizes.h"

#define kSVStackedViewKitDebugEnabled

#define SVAppStatusBarOrientation ([[UIApplication sharedApplication] statusBarOrientation])
#define SVIsPortrait()  UIInterfaceOrientationIsPortrait(SVAppStatusBarOrientation)
#define SVIsLandscape() UIInterfaceOrientationIsLandscape(SVAppStatusBarOrientation)

#ifdef kSVStackedViewKitDebugEnabled
#define SVLog(fmt, ...) NSLog((@"%s/%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define SVLog(...)
#endif
