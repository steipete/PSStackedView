//
//  MenuTableViewCell.m
//  PSStackedViewExample
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "MenuTableViewCell.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MenuTableViewCell

@synthesize glowView;
@synthesize disabledView;
@synthesize enabled;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        savedImage = nil;
        enabled = YES;

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
        glowView.image = [UIImage imageNamed:@"NewGlow"];
        glowView.hidden = YES;
        [self addSubview:glowView];
        [glowView release];
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
    [super layoutSubviews];

    self.textLabel.frame = CGRectMake(75, 0, 125, 43);
    self.imageView.frame = CGRectMake(0, 0, 70, 43);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSelected:(BOOL)sel animated:(BOOL)animated {
    [super setSelected:sel animated:animated];

    if (sel) {
        self.glowView.hidden = NO;
        self.textLabel.textColor = [UIColor whiteColor];
    }
    else {
        self.glowView.hidden = YES;
        self.textLabel.textColor = [UIColor colorWithRed:(188.f/255.f)
                                                   green:(188.f/255.f)
                                                    blue:(188.f/255.f)
                                                   alpha:1.f];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setEnabled:(BOOL)newValue {
    enabled = newValue;

    if (self.enabled) {
        if (self.disabledView) {
            // Remove the "dimmed" view, if there is one. (see below)
            [self.disabledView removeFromSuperview];
            self.disabledView = nil;
        }

        if (savedImage) {
            self.imageView.image = savedImage;
            [savedImage release];
            savedImage = nil;
        }

        // Reenable user interaction and selection ability
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        self.userInteractionEnabled = YES;
    }
    else {
        /* Create the appearance of a "dimmed" table cell, with a standard error icon */
        UIView *newView = [[UIView alloc] initWithFrame:self.bounds];
        newView.backgroundColor = [UIColor colorWithWhite:.5f alpha:.5f];

        if (self.imageView.image) {
            savedImage = [self.imageView.image retain];
            self.imageView.image = [UIImage imageNamed:@"error"];
        }
        else {
            UIImageView *error = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
            CGFloat imgDim = 24.f;
            // set the error image's frame origin to be on the far right side of the table view cell
            CGRect frm = CGRectMake(195.f - imgDim , roundf((self.bounds.size.height/2) - (imgDim/2)), imgDim, imgDim);
            error.frame = frm;
            [newView addSubview:error];
            [error release];
        }
        [self addSubview:newView];
        [self bringSubviewToFront:newView];
        self.disabledView = newView;
        [newView release];

        // Disable future user interaction and selections
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.userInteractionEnabled = NO;

        // Turn off any current selections/highlights
        if (self.selected) {
            self.selected = NO;
        }
        if (self.highlighted) {
            self.highlighted = NO;
        }
    }
    [self setNeedsDisplay];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
    [savedImage release];
    [glowView release];
    [super dealloc];
}

@end
