//
//  ExampleViewController2.m
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "AppDelegate.h"
#import "ExampleViewController1.h"
#import "ExampleViewController2.h"

@implementation ExampleViewController2

@synthesize indexNumber = indexNumber_;

- (id)initWithStyle:(UITableViewStyle)style {
    if ((self = [super initWithStyle:style])) {
        
        // random color
        self.view.backgroundColor = [UIColor colorWithRed:((float)rand())/RAND_MAX green:((float)rand())/RAND_MAX blue:((float)rand())/RAND_MAX alpha:1.0];
        
    }
    return self;
}


#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Example2Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.text = [NSString stringWithFormat:@"[%d] Cell %d", self.indexNumber, indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    UIViewController<PSStackedViewDelegate> *viewController;
    if (indexPath.row == 0) {
        viewController = [[ExampleViewController1 alloc] initWithNibName:@"ExampleViewController1" bundle:nil];
    }else {
        viewController = [[ExampleViewController2 alloc] initWithStyle:UITableViewStylePlain];        
    }
    
    [XAppDelegate.stackController pushViewController:viewController animated:YES];
	[viewController release];
}

- (void)setIndexNumber:(NSUInteger)anIndexNumber {
    indexNumber_ = anIndexNumber;
    [self.tableView reloadData];
}



///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSStackedViewDelegate

- (NSUInteger)stackableMaxWidth; {
    return 250;
}

- (NSUInteger)stackableMinWidth; {
    return 100;
}


@end
