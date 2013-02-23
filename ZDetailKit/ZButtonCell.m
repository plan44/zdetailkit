//
//  ZButtonCell.m
//  ZDetailKit
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
    self.descriptionLabel.textAlignment = UITextAlignmentCenter;
  }
  else if (buttonStyle==ZButtonCellStyleDisclose) {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.descriptionLabel.textAlignment = UITextAlignmentLeft;
  }
  else if (buttonStyle==ZButtonCellStyleDestructive) {
    // like centered text
    self.accessoryType = UITableViewCellAccessoryNone;
    self.descriptionLabel.textAlignment = UITextAlignmentCenter;
    // but with special background image
    UIImage *img = [UIImage imageNamed:@"ZBC_delbtn.png"];
    self.backgroundView = [[UIImageView alloc] initWithImage:[img stretchableImageWithLeftCapWidth:7 topCapHeight:0]];
    // make sure content background is transparent
    self.contentView.backgroundColor = [UIColor clearColor];
    // value must have clear background to show button image through
    self.textLabel.backgroundColor = [UIColor clearColor];
    // label text is white
    self.textLabel.textColor = [UIColor whiteColor];
  }
  [super updateForDisplay];
}


@end

