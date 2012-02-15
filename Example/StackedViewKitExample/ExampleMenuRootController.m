//
//  ExampleMenuRootController.m
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/18/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSStackedView.h"
#import "AppDelegate.h"
#import "MenuTableViewCell.h"
#import "ExampleMenuRootController.h"
#import "ExampleViewController1.h"
#import "ExampleViewController2.h"
#import "UIImage+OverlayColor.h"

#include <QuartzCore/QuartzCore.h>

#define kMenuWidth 200
#define kCellText @"CellText"
#define kCellImage @"CellImage" 

@interface ExampleMenuRootController()
@property (nonatomic, strong) UITableView *menuTable;
@property (nonatomic, strong) NSArray *cellContents;
@property (nonatomic, strong) UIImageView *popIconLeft;
@property (nonatomic, strong) UIImageView *popIconRight;
@end

@implementation ExampleMenuRootController

@synthesize menuTable = menuTable_;
@synthesize cellContents = cellContents_;
@synthesize popIconLeft = popIconLeft_;
@synthesize popIconRight = popIconRight_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject



///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"load example view, frame: %@", NSStringFromCGRect(self.view.frame));
        
#if 0
    self.view.layer.borderColor = [UIColor greenColor].CGColor;
    self.view.layer.borderWidth = 2.f;
#endif
    
    // add example background
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
            
    // prepare menu content
    NSMutableArray *contents = [[NSMutableArray alloc] init];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage invertImageNamed:@"08-chat"], kCellImage, NSLocalizedString(@"Example1",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage invertImageNamed:@"11-clock"], kCellImage, NSLocalizedString(@"Example2",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage invertImageNamed:@"15-tags"], kCellImage, NSLocalizedString(@" ",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage invertImageNamed:@"08-chat"], kCellImage, NSLocalizedString(@"<- Collapse",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage invertImageNamed:@"11-clock"], kCellImage, NSLocalizedString(@"Expand ->",@""), kCellText, nil]];
    [contents addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage invertImageNamed:@"15-tags"], kCellImage, NSLocalizedString(@"Clear All",@""), kCellText, nil]];    
    self.cellContents = contents;
    
    // add table menu
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kMenuWidth, self.view.height) style:UITableViewStylePlain];
    self.menuTable = tableView;
    
    self.menuTable.backgroundColor = [UIColor clearColor];
    self.menuTable.delegate = self;
    self.menuTable.dataSource = self;
    [self.view addSubview:self.menuTable];
    [self.menuTable reloadData];
    
    self.popIconLeft = [[UIImageView alloc] initWithFrame:CGRectMake(225, 482, 50, 70)];
    self.popIconLeft.image = [UIImage imageNamed:@"popIcon.png"];
    self.popIconLeft.alpha = 0.0;
    [self.view addSubview:self.popIconLeft];
    
    self.popIconRight = [[UIImageView alloc] initWithFrame:CGRectMake(245, 502, 50, 70)];
    self.popIconRight.image = [UIImage imageNamed:@"popIcon.png"];
    self.popIconRight.alpha = 0.0;
    [self.view addSubview:self.popIconRight];
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
        cell = [[MenuTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	cell.textLabel.text = [[cellContents_ objectAtIndex:indexPath.row] objectForKey:kCellText];
	cell.imageView.image = [[cellContents_ objectAtIndex:indexPath.row] objectForKey:kCellImage];
	    
    //if (indexPath.row == 5)
    //    cell.enabled = NO;
    
    return cell;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {  
    PSStackedViewController *stackController = XAppDelegate.stackController;
    UIViewController*viewController = nil;
    
    
    if (indexPath.row < 3) {
        // Pop everything off the stack to start a with a fresh app feature
        // DISABLED FOR DEBUGGING
        //[stackController popToRootViewControllerAnimated:YES];
    }
    
    if (indexPath.row == 0) {
        viewController = [[ExampleViewController1 alloc] initWithNibName:@"ExampleViewController1" bundle:nil];
        ((ExampleViewController1 *)viewController).indexNumber = [stackController.viewControllers count];
    }else if(indexPath.row == 1) {
        viewController = [[ExampleViewController2 alloc] initWithStyle:UITableViewStylePlain];     
        ((ExampleViewController2 *)viewController).indexNumber = [stackController.viewControllers count];
    }else if(indexPath.row == 2) { // Twitter style
        viewController = [[ExampleViewController1 alloc] initWithNibName:@"ExampleViewController1" bundle:nil];
        ((ExampleViewController1 *)viewController).indexNumber = [stackController.viewControllers count];
        viewController.view.width = roundf((self.view.width - stackController.leftInset)/2);
    }
    else if(indexPath.row == 3) {        
        [stackController collapseStack:1 animated:YES];
    }else if(indexPath.row == 4) { // right
        [stackController expandStack:1 animated:YES];
    }else if(indexPath.row == 5) {
        while ([stackController.viewControllers count]) {
            [stackController popViewControllerAnimated:YES];
        }
    }
    
    if (viewController) {
        [XAppDelegate.stackController pushViewController:viewController fromViewController:nil animated:YES];
    }
}

/// PSStackedViewDelegate methods

- (void)stackedViewDidStartDragging:(PSStackedViewController *)stackedView {
    if([stackedView.viewControllers count] > 1) {
        [UIView animateWithDuration:0.2 animations:^(void) {
            self.popIconLeft.alpha = 1.0;
            self.popIconRight.alpha = 1.0;
        }];
    }
}

- (void)stackedViewDidStopDragging:(PSStackedViewController *)stackedView {
    [UIView animateWithDuration:0.2 animations:^(void) {
        self.popIconLeft.alpha = 0.0;
        self.popIconRight.alpha = 0.0;
        self.popIconRight.transform = CGAffineTransformIdentity;
    }];
}

-(void)stackedView:(PSStackedViewController *)stackedView WillPopViewControllers:(NSArray *)controllers {
    if([controllers count] > 0) {
        [UIView animateWithDuration:0.2 animations:^(void) {
            self.popIconRight.alpha = 0.5;
            CGAffineTransform trans = CGAffineTransformMakeTranslation(40, 10);
            trans = CGAffineTransformRotate(trans, M_PI/4);
            self.popIconRight.transform = trans;
        }];
    }
}

- (void)stackedView:(PSStackedViewController *)stackedView WillNotPopViewControllers:(NSArray *)controllers {
    if([controllers count] > 0) {
        [UIView animateWithDuration:0.2 animations:^(void) {
            self.popIconRight.alpha = 1.0;
            self.popIconRight.transform = CGAffineTransformIdentity;
        }];
    }
}

@end
