//
//  MenuTableViewCell.h
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuTableViewCell : UITableViewCell {
	UIImageView *glowView;
    UIImage *savedImage;
}

@property(nonatomic,strong) UIImageView *glowView;
@property(nonatomic,strong) UIView *disabledView;
@property(nonatomic) BOOL enabled;

@end
