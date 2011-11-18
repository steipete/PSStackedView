//
//  AppDelegate.m
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "AppDelegate.h"
#import "ExampleMenuRootController.h"

@interface AppDelegate ()
@property (nonatomic, strong) PSStackedViewController *stackController;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize stackController = stackController_;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions; {

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor]; // really should be default
    
    // set root controller as stack controller
    ExampleMenuRootController *menuController = [[ExampleMenuRootController alloc] init];
    self.stackController = [[PSStackedViewController alloc] initWithRootViewController:menuController];
    self.window.rootViewController = self.stackController;
    [self.window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application; {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
