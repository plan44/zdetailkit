//
//  ZButtonCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZButtonCell.h"

@implementation ZButtonCell

- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if (aStyle & ZDetailViewCellStyleFlagAutoStyle) {
    // set recommended standard style for buttons
    aStyle = UITableViewCellStyleDefault+ZDetailViewCellStyleFlagAutoLabelLayout+ZDetailViewCellStyleFlagAutoStyle;
  }
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    buttonStyle = ZButtonCellStyleDisclose; // default to disclosure (submenu) button
  }
  return self;
}



- (CGFloat)valueCellShare
{
  // override when autostyled
  if (self.detailViewCellStyle & ZDetailViewCellStyleFlagAutoStyle) {
    return 0; // use the entire cell for description
  }
  return [super valueCellShare];
}


@synthesize buttonStyle;

- (void)setButtonStyle:(ZButtonCellStyle)aButtonStyle
{
  if (aButtonStyle!=buttonStyle) {
    buttonStyle = aButtonStyle;
    [self setNeedsUpdate];
  }
}


- (void)updateForDisplay
{
  if (buttonStyle==ZButtonCellStyleCenterText) {
    self.accessoryType = UITableViewCellAccessoryNone;
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
  }
  else if (buttonStyle==ZButtonCellStyleDisclose) {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
  }
  else if (buttonStyle==ZButtonCellStyleDestructive) {
    // like centered text
    self.accessoryType = UITableViewCellAccessoryNone;
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    // label text is red
    self.textLabel.textColor = [UIColor redColor];
  }
  [super updateForDisplay];
}


@end

