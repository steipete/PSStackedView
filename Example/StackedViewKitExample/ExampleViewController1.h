//
//  ExampleViewController1.h
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#include "PSStackedViewDelegate.h"

@interface ExampleViewController1 : UIViewController <PSStackedViewDelegate>

@property(nonatomic, strong) IBOutlet UILabel *indexNumberLabel;
@property(nonatomic, assign) NSUInteger indexNumber;

@end
