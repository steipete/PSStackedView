//
//  AppDelegate.h
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSStackedView.h"

#define XAppDelegate ((AppDelegate *)[[UIApplication sharedApplication] delegate])

@class PSStackedViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    PSStackedViewController *stackController_;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain, readonly) PSStackedViewController *stackController;

@end
