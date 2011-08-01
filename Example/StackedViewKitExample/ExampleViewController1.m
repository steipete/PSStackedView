//
//  ExampleViewController1.m
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "ExampleViewController1.h"
#import "PSStackedView.h"

@implementation ExampleViewController1

@synthesize indexNumber, indexNumberLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {

        // random color
        self.view.backgroundColor = [UIColor colorWithRed:((float)rand())/RAND_MAX green:((float)rand())/RAND_MAX blue:((float)rand())/RAND_MAX alpha:1.0];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.width = PSIsIpad() ? 300 : 150;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setIndexNumber:(NSUInteger)anIndexNumber {
    self.indexNumberLabel.text = [NSString stringWithFormat:@"%d", anIndexNumber];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSStackedViewDelegate

- (NSUInteger)stackableMinWidth; {
    return 100;
}


@end
