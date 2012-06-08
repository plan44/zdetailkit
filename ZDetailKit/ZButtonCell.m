//
//  ZButtonCell.m
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZButtonCell.h"

@implementation ZButtonCell

- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if (aStyle & ZDetailViewCellStyleFlagAutoStyle) {
    // set recommended standard style for buttons
    aStyle = UITableViewCellStyleDefault+ZDetailViewCellStyleFlagCustomLayout+ZDetailViewCellStyleFlagAutoStyle;
  }
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    buttonStyle = ZButtonCellStyleDisclose; // default to disclosure (submenu) button
  }
  return self;
}

@synthesize buttonStyle;


- (CGFloat)valueCellShare
{
  // override when autostyled
  if (self.detailViewCellStyle & ZDetailViewCellStyleFlagAutoStyle) {
    return 0; // use the entire cell for description
  }
  return [super valueCellShare];
}


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
    self.descriptionLabel.textAlignment = UITextAlignmentCenter;
  }
  else if (buttonStyle==ZButtonCellStyleDisclose) {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.descriptionLabel.textAlignment = UITextAlignmentLeft;
  }
  [super updateForDisplay];
}


@end

