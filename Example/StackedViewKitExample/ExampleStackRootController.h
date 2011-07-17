//
//  ExampleStackRootController.h
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSStackedViewRootController.h"

@interface ExampleStackRootController : PSStackedViewRootController <UITableViewDataSource, UITableViewDelegate> {
    UITableView *menuTable_;
    NSArray *cellContents_;
}

@end
