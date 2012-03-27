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

@synthesize showBackButton;
@synthesize backButton;

#pragma mark - View Lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (showBackButton) {
        [[self backButton] setHidden:![self showBackButton]];
    }

}
- (void)viewDidUnload {
    [self setBackButton:nil];
    [super viewDidUnload];
}


#pragma mark - Actions

- (void)pushViewControllerWithColor:(UIColor *)color {
    
    PSViewController *viewController = [[PSViewController alloc] init];
    
    [[viewController view] setBackgroundColor:color];
    [viewController setShowBackButton:YES];
    
    [[self stackController] pushViewController:viewController animated:YES];
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

- (IBAction)goBack:(id)sender {

    [[self stackController] expandStack:1 animated:YES];
}

@end
