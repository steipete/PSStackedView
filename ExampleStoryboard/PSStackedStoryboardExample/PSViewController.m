//
//  PSViewController.m
//  PSStackedStoryboardExample
//
//  Created by Franklin Webber on 3/26/12.
//  Copyright (c) 2012 University of Washington. All rights reserved.
//

#import "PSViewController.h"
#import "UIViewController+PSStackedView.h"

@interface PSViewController ()

@end

@implementation PSViewController

- (void)pushViewControllerWithColor:(UIColor *)color {
    
    PSViewController *viewController = [[PSViewController alloc] init];
    
    [[viewController view] setBackgroundColor:color];
    
    [[self stackController] pushViewController:viewController animated:YES];
    [[self stackController] setLeftInset:50];
//    [[self stackController] pushViewController:viewController fromViewController:self animated:YES];
}


- (IBAction)addRedViewController:(id)sender {    
    [self pushViewControllerWithColor:[UIColor redColor]];
}

- (IBAction)addGreenViewController:(id)sender {
    [self pushViewControllerWithColor:[UIColor greenColor]];
}

- (IBAction)addBlueViewController:(id)sender {
    [self pushViewControllerWithColor:[UIColor blueColor]];
}

@end
