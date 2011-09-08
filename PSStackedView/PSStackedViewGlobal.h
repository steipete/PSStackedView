//
//  PSStackedViewGlobal.h
//  PSStackedView
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "UIView+PSSizes.h"

enum {
    PSSVLogLevelNothing,
    PSSVLogLevelError,    
    PSSVLogLevelInfo,
    PSSVLogLevelVerbose
}typedef PSSVLogLevel;

extern PSSVLogLevel kPSSVDebugLogLevel; // defaults to PSSVLogLevelError

#define kPSSVStackedViewKitDebugEnabled

#define PSIsIpad() ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define PSAppStatusBarOrientation ([[UIApplication sharedApplication] statusBarOrientation])
#define PSIsPortrait()  UIInterfaceOrientationIsPortrait(PSAppStatusBarOrientation)
#define PSIsLandscape() UIInterfaceOrientationIsLandscape(PSAppStatusBarOrientation)
#define PSIsIpad() ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#ifdef kPSSVStackedViewKitDebugEnabled
#define PSSVLogVerbose(fmt, ...) do { if(kPSSVDebugLogLevel >= PSSVLogLevelVerbose) NSLog((@"%s/%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); }while(0)
#define PSSVLog(fmt, ...) do { if(kPSSVDebugLogLevel >= PSSVLogLevelInfo) NSLog((@"%s/%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); }while(0)
#define PSSVLogError(fmt, ...) do { if(kPSSVDebugLogLevel >= PSSVLogLevelError) NSLog((@"Error: %s/%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); }while(0)
#else
#define PSSVLogVerbose(...)
#define PSSVLog(...)
#define PSVSLogError(...)
#endif