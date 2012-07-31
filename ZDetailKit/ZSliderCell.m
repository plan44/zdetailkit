//
//  ZSliderCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 31.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZSliderCell.h"

#import "ZDetailTableViewController.h"


@interface ZSliderCell ( /* class extension */ )
{
}

@end


@implementation ZSliderCell

@synthesize sliderControl = _sliderControl;
@synthesize valueConnector = _valueConnector;


- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    _sliderControl = nil; // created on demand
    self.valueLabel.hidden = YES; // don't show value label
    self.valueViewAdjustment = ZDetailCellItemAdjustFillWidth+ZDetailCellItemAdjustMiddle; // use all horizontal space, vertically centered
    // valueConnector
    _valueConnector = [self registerConnector:
      [ZDetailValueConnector connectorWithValuePath:@"sliderControl.value" owner:self]
    ];
    _valueConnector.nilNulValue = [NSNumber numberWithInt:0]; // default to show external nil/null as zero
    _valueConnector.autoRevertOnValidationError = YES; // just don't allow non-validating state of the switch
  }
  return self;
}




#pragma mark - cell configuration


- (void)updateForDisplay
{
  // reconfigure views
  self.valueView = self.sliderControl; // put slider under layout control
  self.accessoryType = UITableViewCellAccessoryNone;
  // enable slider when editing is allowed
  self.sliderControl.enabled = self.allowsEditing;
  // update cell basics
  [super updateForDisplay];
}


#pragma mark - embedded slider


- (void)sliderChanged
{
  // KVO on UISwitch.on does not work, report change
  self.valueConnector.unsavedChanges = YES;
}



- (UISlider *)sliderControl
{
  if (_sliderControl==nil) {
    _sliderControl = [[UISlider alloc] initWithFrame:CGRectZero];
    _sliderControl.continuous = self.valueConnector.autoSaveValue;
    [_sliderControl addTarget:self action:@selector(sliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:_sliderControl];
  }
  return _sliderControl;
}


@end
