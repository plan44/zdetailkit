//
//  ZChoiceListCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 06.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZChoiceListCell.h"

#import "ZChoiceListController.h"


@interface ZChoiceListCell ( /* class extension */ )

@end

@implementation ZChoiceListCell

- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    // nop
  }
  return self;
}




#pragma mark - cell configuration


- (void)updateForDisplay
{
  // reconfigure views
  if (self.allowsEditing) {
    // editable - show disclosure indicator
    self.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;      
  }
  else {
    // non-editable - no disclosure indicator
    self.accessoryType = UITableViewCellAccessoryNone; // view only, no disclosure indicator
  }
  // update cell basics
  [super updateForDisplay];
}


#pragma mark - updating choices and selection


- (void)updateChoicesDisplay
{
  // need to update summary of choices
  [self updateChoiceSelection];
}


- (void)updateChoiceSelection
{
  // create a summary in the value label
  NSMutableString *summary = [NSMutableString string];
  for (ZChoiceInfo *info in self.choicesManager.choiceInfos) {
    // check if selected one
    if (info.selected) {
      // use separate summary text if any
      NSString *s = [info.choice valueForKey:@"summary"];
      if (s==nil) {
        // no summary, use regular text
        s = [info.choice valueForKey:@"text"];
        if (s==nil)
          s = [NSString stringWithFormat:@"[%@]", [info.key description]];
      }
      // add to string
      if (summary.length>0)
        [summary appendString:@", "];
      [summary appendString:s];
    }
  }
  // show choice summary in value label
  self.valueLabel.text = summary;
  [self setNeedsLayout]; // needed as labels might start hidden
}


#pragma mark - choices editor


- (UIViewController *)editorForTapInAccessory:(BOOL)aInAccessory
{
  ZChoiceListController *clc = nil;
  if (self.allowsEditing) {
    clc = [ZChoiceListController controllerWithTitle:self.detailTitleText];
    // pass on the choices and config
    clc.choicesManager.choicesArray = self.choicesManager.choicesArray;
    clc.choicesManager.mode = self.choicesManager.mode;
    clc.choicesManager.multipleChoices = self.choicesManager.multipleChoices;
    clc.choicesManager.noChoice = self.choicesManager.noChoice;
    clc.choicesManager.reorderable = self.choicesManager.reorderable;
    // connect the value
    [clc.valueConnector connectTo:self.valueConnector keyPath:@"internalValue"];
  }
  return clc;
}



@end
