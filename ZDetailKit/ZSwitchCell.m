//
//  ZSwitchCell.m
//
//  Created by Lukas Zeller on 31.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZSwitchCell.h"

#import "ZDetailTableViewController.h"

@interface ZSwitchCell ( /* class extension */ )
{
  BOOL updating;
}
@property (assign, nonatomic) BOOL internalState;

@end


@implementation ZSwitchCell

@synthesize switchControl;

@synthesize inverse, bitMask;

@synthesize valueConnector, switchVal;


- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    switchControl = nil; // created on demand
    self.valueLabel.hidden = YES; // don't show value label
    self.valueViewAdjustment = ZDetailCellItemAdjustRight+ZDetailCellItemAdjustMiddle; // always right-aligned
    //self.valueViewAdjustment = self.valueViewAdjustment & ~ZDetailCellItemAdjustFillWidth; // don't try to resize switch
    inverse = NO; // not inversed
    bitMask = 0; // not using a bitmask
    updating = NO; // to break recursions
    checkMark = NO; // use switch control, not checkmark
    // valueConnector
    valueConnector = [self registerConnector:
      [ZDetailValueConnector connectorWithValuePath:nil owner:self]
    ];
    valueConnector.nilNulValue = [NSNumber numberWithBool:NO]; // default to show external nil/null as NO
    valueConnector.autoRevertOnValidationError = YES; // just don't allow non-validating state of the switch
  }
  return self;
}


- (void)dealloc
{
	[switchControl release];
	[super dealloc];
}


#pragma mark - cell configuration


@synthesize checkMark;

- (void)setCheckMark:(BOOL)aCheckMark
{
  if (aCheckMark!=checkMark) {
    checkMark = aCheckMark;
    [self setNeedsUpdate];
  }
}


- (void)updateForDisplay
{
  // connect textview (also creates it)
  self.valueConnector.valuePath = @"switchVal";  
  // reconfigure views
  if (checkMark) {
    // boolean value is represented by checkmark
    self.valueView = nil; // no value view
    [switchControl release]; switchControl = nil; // no switch
  }
  else {
    // boolean value is represented by switch control
    self.valueView = self.switchControl; // put switch under layout control
    self.accessoryType = UITableViewCellAccessoryNone;
    // enable switch when editing is allowed
    self.switchControl.enabled = self.allowsEditing;
  }
  // update cell basics
  [super updateForDisplay];
}


#pragma mark - switch value


- (BOOL)internalState
{
  if (checkMark)
    return self.accessoryType==UITableViewCellAccessoryCheckmark;
  else
    return self.switchControl.on;
}


- (void)setInternalState:(BOOL)aInternalState
{
  if (checkMark)
    self.accessoryType = aInternalState ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
  else
    self.switchControl.on = aInternalState;
}


- (NSUInteger)switchVal
{
  BOOL flagVal = self.internalState ^ inverse;
  if (bitMask) {
    // need read-modify-write
    if (!updating) {
      updating = YES;
      [self.valueConnector loadValue]; // updates switchVal
      updating = NO;
    }
    NSUInteger sv = (switchVal & ~bitMask);
    if (flagVal)
      sv |= bitMask;
    return sv;
  }
  else {
    return flagVal;
  }
}


- (void)setSwitchVal:(NSUInteger)aSwitchVal
{
  switchVal = aSwitchVal;
  if (!updating) {
    self.internalState = (bitMask ? (switchVal & bitMask)!=0 : switchVal) ^ inverse;
  }
}



// called to handle a tap in the cell (instead of in the cellOwner), return YES if handled
- (BOOL)handleTapInAccessory:(BOOL)aInAccessory
{
  // first give base class chance to use custom handler
  BOOL handled = [super handleTapInAccessory:aInAccessory];
  if (!handled) {
    // not fully handled, do my own standard stuff
    if (checkMark) {
      if (self.allowsEditing) {
        // toggle checkmark
        self.internalState = !self.internalState;
        // this is a change
        self.valueConnector.unsavedChanges = YES;
      }
      handled = YES;
    }
  }
  return handled;
}



#pragma mark - embedded switch


- (void)switchChanged
{
  // KVO on UISwitch.on does not work, report change
  self.valueConnector.unsavedChanges = YES;
}



- (UISwitch *)switchControl
{
  if (switchControl==nil) {
    switchControl = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switchControl addTarget:self action:@selector(switchChanged) forControlEvents:UIControlEventValueChanged];

    [self.contentView addSubview:switchControl];
  }
  return switchControl;
}


@end
