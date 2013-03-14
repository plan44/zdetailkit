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
    _valueConnector = [self registerValueConnector:
      [ZValueConnector connectorWithValuePath:@"sliderControl.value" owner:self]
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



- (UISlider *)sliderControl
{
  if (_sliderControl==nil) {
    _sliderControl = [[UISlider alloc] initWithFrame:CGRectZero];
    _sliderControl.continuous = self.valueConnector.autoSaveValue;
    // KVO on slider.value does not work, add target to forward change to value connector
    [_sliderControl addTarget:self.valueConnector action:@selector(markInternalValueChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:_sliderControl];
  }
  return _sliderControl;
}


@end
