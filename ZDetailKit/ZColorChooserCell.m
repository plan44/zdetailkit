//
//  ZColorChooserCell.m
//  ZDetailKit
//
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZColorChooserCell.h"

#import "ZDetailTableViewController.h"


@interface ZColorChooserCell ( /* class extension */ )
{
}

@end


@implementation ZColorChooserCell

@synthesize colorChooser;

@synthesize valueConnector;


- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    colorChooser = nil; // created on demand
    if (aStyle & ZDetailViewCellStyleFlagAutoStyle) {
      // set recommended auto style
      self.standardCellHeight = 66; // need room for two color strips
      self.valueViewAdjustment = ZDetailCellItemAdjustFillWidth+ZDetailCellItemAdjustFillHeight+ZDetailCellItemAdjustExtend; // fill available space
      self.descriptionViewAdjustment = ZDetailCellItemAdjustHide;
      self.valueCellShare = 1.0; // only value
      self.autoSetDescriptionLabelText = NO; // don't set
    }
    // valueConnector
    valueConnector = [self registerConnector:
      [ZDetailValueConnector connectorWithValuePath:@"colorChooser.color" owner:self]
    ];
  }
  return self;
}




#pragma mark - cell configuration


- (void)updateForDisplay
{
  // reconfigure views
  self.descriptionView = nil;
  self.valueView = self.colorChooser; // put switch under layout control
  self.accessoryType = UITableViewCellAccessoryNone;
  // enable switch when editing is allowed
  self.colorChooser.enabled = self.allowsEditing;
  self.colorChooser.noColorAllowed = self.valueConnector.nilAllowed;
  // update cell basics
  [super updateForDisplay];
}


- (void)layoutSubviews
{
  [super layoutSubviews];
}


#pragma mark - embedded color chooser


- (void)blockScrollingForSliders:(BOOL)aBlockScrolling
{
  [self.cellOwner tempBlockScrolling:aBlockScrolling];
}



- (void)colorChanged
{
  // KVO on ZColorChooser.color does not work, report change
  self.valueConnector.unsavedChanges = YES;
}



- (ZColorChooser *)colorChooser
{
  if (colorChooser==nil) {
    colorChooser = [[ZColorChooser alloc] initWithFrame:CGRectZero];
    colorChooser.delegate = self;
    [colorChooser addTarget:self action:@selector(colorChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:colorChooser];
  }
  return colorChooser;
}


@end
