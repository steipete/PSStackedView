//
//  ExampleMenuRootController.h
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/18/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExampleMenuRootController : UIViewController <UITableViewDataSource, UITableViewDelegate, PSStackedViewDelegate> {
    UITableView *menuTable_;
    UIImageView *popIconLeft_;
    UIImageView *popIconRight_;
    NSArray *cellContents_;
}

@end
