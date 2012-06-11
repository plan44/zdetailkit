//
//  ZSegmentChoicesCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 03.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZSegmentChoicesCell.h"

#import "ZDetailTableViewController.h"

@interface ZSegmentChoicesCell ( /* class extension */ )

@end


@implementation ZSegmentChoicesCell

@synthesize segmentedControl;


- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    segmentedControl = nil; // created on demand
    self.valueLabel.hidden = YES; // don't show value label
    self.valueViewAdjustment = ZDetailCellItemAdjustMiddle+ZDetailCellItemAdjustFillHeight; // full height
  }
  return self;
}


- (void)dealloc
{
	[segmentedControl release];
	[super dealloc];
}


#pragma mark - cell configuration


- (void)updateForDisplay
{
  // reconfigure views
  self.valueView = self.segmentedControl; // put segmented control under layout control
  // disable when read-only
  self.segmentedControl.enabled = self.allowsEditing;
  // update cell basics
  [super updateForDisplay];
}


#pragma mark - updating choices and selection


- (void)updateChoicesDisplay
{
  // configure segments according to choices
  [self.segmentedControl removeAllSegments];
  NSInteger selectedIndex = -1;
  NSInteger index = 0;
  for (ZChoiceInfo *info in self.choicesManager.choiceInfos) {
    // add a segment for each choice
    UIImage *img = nil;
    NSString *imgName = [info.choice valueForKey:@"imageName"];
    if (imgName) {
      img = [UIImage imageNamed:imgName];
    }
    if (!img) {
      img = [info.choice valueForKey:@"image"];
    }    
    if (img) {
      // image base segment
      [self.segmentedControl insertSegmentWithImage:img atIndex:index animated:NO];
    }
    else {
      // text based segment
      NSString *text = [info.choice valueForKey:@"text"];
      if (!text) text = [NSString stringWithFormat:@"#%d",index];
      [self.segmentedControl insertSegmentWithTitle:text atIndex:index animated:NO];
    }
    // check if selected one
    if (info.selected) selectedIndex = index;
    // next
    index++;
  }
  // Note: -1 turns off selection in UISegmentedControl
  self.segmentedControl.selectedSegmentIndex = selectedIndex;
}


- (void)updateChoiceSelection
{
  // configure segments according to choices
  NSInteger selectedIndex = -1;
  NSInteger index = 0;
  for (ZChoiceInfo *info in self.choicesManager.choiceInfos) {
    // check if selected one
    if (info.selected) {
      selectedIndex = index;
      break;
    }
    // next
    index++;
  }
  // Note: -1 turns off selection in UISegmentedControl
  self.segmentedControl.selectedSegmentIndex = selectedIndex;
}
 



#pragma mark - embedded segmented control


- (void)segmentChanged
{
  // update selected item
  NSInteger index = 0;
  for (ZChoiceInfo *info in self.choicesManager.choiceInfos) {
    // set selected for the current segment, off for all others
    info.selected = index==self.segmentedControl.selectedSegmentIndex;
    // next
    index++;
  }
  self.valueConnector.unsavedChanges = YES;
}



- (UISegmentedControl *)segmentedControl
{
  if (segmentedControl==nil) {
    segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"???"]];
    [segmentedControl addTarget:self action:@selector(segmentChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:segmentedControl];
  }
  return segmentedControl;
}


@end
