//
//  MenuTableViewCell.m
//  PSStackedViewExample
// 
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "MenuTableViewCell.h"

@implementation MenuTableViewCell

@synthesize glowView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.clipsToBounds = YES;
		
		UIView* bgView = [[UIView alloc] init];
		bgView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.25f];
		self.selectedBackgroundView = bgView;
		[bgView release];
				
		self.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
		self.textLabel.shadowOffset = CGSizeMake(0, 2);
		self.textLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.25];
		
		self.imageView.contentMode = UIViewContentModeCenter;
		
		UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 1)];
		topLine.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.25];
		[self.textLabel.superview addSubview:topLine];
		[topLine release];
		
		UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 43, 200, 1)];
		bottomLine.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
		[self.textLabel.superview addSubview:bottomLine];
		[bottomLine release];
		
		glowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 43)];
		glowView.image = [UIImage imageNamed:@"glow"];
		glowView.hidden = YES;
		[self addSubview:glowView];
		[glowView release];
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.textLabel.frame = CGRectMake(75, 0, 125, 43);
	self.imageView.frame = CGRectMake(0, 0, 70, 43);
}

- (void)setSelected:(BOOL)sel animated:(BOOL)animated {
	[super setSelected:sel animated:animated];
		
	if (sel) {
		self.textLabel.textColor = [UIColor whiteColor];
	}
	else {
		self.textLabel.textColor = [UIColor colorWithRed:(188.f/255.f) green:(188.f/255.f) blue:(188.f/255.f) alpha:1.f];
	}
}

- (void)dealloc {
	[glowView release];
	[super dealloc];
}

@end
