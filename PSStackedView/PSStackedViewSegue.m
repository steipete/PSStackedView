//
//  PSStackedViewSegue.m
//  PSStackedView
//
//  Created by Marcel Ball on 12-01-19.
//  Copyright (c) 2012 Peter Steinberger. All rights reserved.
//

#import "PSStackedViewSegue.h"
#import "PSStackedViewController.h"
#import "UIViewController+PSStackedView.h"

@implementation PSStackedViewSegue

- (void)perform {
    PSStackedViewController* stackController = [self.sourceViewController stackController];
    [stackController pushViewController:self.destinationViewController fromViewController:self.sourceViewController animated:YES];
}

@end
