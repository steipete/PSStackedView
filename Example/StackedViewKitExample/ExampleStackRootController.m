//
//  ExampleStackRootController.m
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "AppDelegate.h"
#import "ExampleStackRootController.h"
#import "MenuTableViewCell.h"

#import "ExampleViewController1.h"
#import "ExampleViewController2.h"

#include <QuartzCore/QuartzCore.h>

#define kMenuWidth 200
#define kCellText @"CellText"
#define kCellImage @"CellImage" 

@interface ExampleStackRootController()
@property (nonatomic, retain) UITableView *menuTable;
@property (nonatomic, retain) NSArray *cellContents;
@end

@implementation ExampleStackRootController

@synthesize menuTable = menuTable_;
@synthesize cellContents = cellContents_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (void)dealloc {
    [menuTable_ release];
    [cellContents_ release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];
    PSLog(@"load example view, frame: %@", NSStringFromCGRect(self.view.frame));
    
#if 0
    self.view.layer.borderColor = [UIColor greenColor].CGColor;
    self.view.layer.borderWidth = 2.f;
#endif
    
    // add example background
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    
    // prepare menu content
    NSMutableArray *contents = [[NSMutableArray alloc] init];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"08-chat"], kCellImage, NSLocalizedString(@"Example1",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"11-clock"], kCellImage, NSLocalizedString(@"Example2",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"15-tags"], kCellImage, NSLocalizedString(@" ",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"08-chat"], kCellImage, NSLocalizedString(@"<- Collapse",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"11-clock"], kCellImage, NSLocalizedString(@"Expand ->",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"15-tags"], kCellImage, NSLocalizedString(@"Clear All",@""), kCellText, nil]];    
    self.cellContents = contents;
	[contents release];
    
    // add table menu
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kMenuWidth, self.view.height) style:UITableViewStylePlain];
    self.menuTable = tableView;
	[tableView release];
    
    self.menuTable.backgroundColor = [UIColor clearColor];
    self.menuTable.delegate = self;
    self.menuTable.dataSource = self;
    [self.view addSubview:self.menuTable];
    [self.menuTable reloadData];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [cellContents_ count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ExampleMenuCell";
    
    MenuTableViewCell *cell = (MenuTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[MenuTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.text = [[cellContents_ objectAtIndex:indexPath.row] objectForKey:kCellText];
	cell.imageView.image = [[cellContents_ objectAtIndex:indexPath.row] objectForKey:kCellImage];
	
	cell.glowView.hidden = indexPath.row != 3;
    
    return cell;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    UIViewController<PSStackedViewDelegate> *viewController = nil;
    if (indexPath.row == 0) {
        viewController = [[ExampleViewController1 alloc] initWithNibName:@"ExampleViewController1" bundle:nil];
        ((ExampleViewController1 *)viewController).indexNumber = [self.viewControllers count];
    }else if(indexPath.row == 5) {
        while ([self.viewControllers count]) {
            [self popViewControllerAnimated:YES];
        }
    }else if(indexPath.row == 4) { // right
        [self expandStack:1 animated:YES];
    }else if(indexPath.row == 3) {        
        [self collapseStack:1 animated:YES];
    }else {
        viewController = [[ExampleViewController2 alloc] initWithStyle:UITableViewStylePlain];     
        ((ExampleViewController2 *)viewController).indexNumber = [self.viewControllers count];
    }
    
    if (viewController) {
        [XAppDelegate.stackController pushViewController:viewController fromViewController:nil animated:YES];
		[viewController release];
    }
}

@end
