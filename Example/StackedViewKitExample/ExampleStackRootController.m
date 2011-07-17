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

- (id)init {
    if ((self = [super init])) {
        SVLog(@"Init example VC");
    }
    return self;
}

- (void)dealloc {
    [menuTable_ release];
    [cellContents_ release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];
    SVLog(@"Init example VC VIEW");
    
    // add example background
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    
    // prepare menu content
    NSMutableArray *cellContents = [[[NSMutableArray alloc] init] autorelease];
    [cellContents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"08-chat"], kCellImage, NSLocalizedString(@"Example1",@""), kCellText, nil]];
    [cellContents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"11-clock"], kCellImage, NSLocalizedString(@"Example2",@""), kCellText, nil]];
    [cellContents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"15-tags"], kCellImage, NSLocalizedString(@" ",@""), kCellText, nil]];
    [cellContents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"08-chat"], kCellImage, NSLocalizedString(@"<- Collapse",@""), kCellText, nil]];
    [cellContents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"11-clock"], kCellImage, NSLocalizedString(@"Expand ->",@""), kCellText, nil]];
    [cellContents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageNamed:@"15-tags"], kCellImage, NSLocalizedString(@"Clear All",@""), kCellText, nil]];    
    self.cellContents = [[cellContents copy] autorelease];
    
    // add table menu
    self.menuTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kMenuWidth, self.view.height) style:UITableViewStylePlain];
    
    self.menuTable.backgroundColor = [UIColor clearColor];
    self.menuTable.delegate = self;
    self.menuTable.dataSource = self;
    [self.view addSubview:self.menuTable];
    [self.menuTable reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    [super viewDidUnload];
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
	return 70;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
	//return _menuHeader;
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
        
        // make menu an extra step
//        if([self isMenuCollapsable] && self.isShowingFullMenu)
        
        [self collapseStack:1 animated:YES];
        
    }else {
        viewController = [[ExampleViewController2 alloc] initWithStyle:UITableViewStylePlain];     
        ((ExampleViewController2 *)viewController).indexNumber = [self.viewControllers count];
    }
    
    if (viewController) {
        [XAppDelegate.stackController pushViewController:viewController animated:YES];
    }
}

@end
