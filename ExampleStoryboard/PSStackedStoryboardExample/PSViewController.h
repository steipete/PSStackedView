//
//  PSViewController.h
//  PSStackedStoryboardExample
//
//  Created by Franklin Webber on 3/26/12.
//  Copyright (c) 2012 University of Washington. All rights reserved.
//

#import "PSStackedViewController.h"

@interface PSViewController : UIViewController

@property (nonatomic,assign) BOOL showBackButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

- (IBAction)addRedViewController:(id)sender;
- (IBAction)addGreenViewController:(id)sender;
- (IBAction)addBlueViewController:(id)sender;

- (IBAction)goBack:(id)sender;
@end
