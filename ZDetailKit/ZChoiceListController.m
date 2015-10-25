//
//  ZChoiceListController.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 06.06.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZChoiceListController.h"

#import "ZSwitchCell.h"

#import "ZSoundPlayer.h"

@interface ZChoiceListController ( /* class extension */ )
{
  ZSoundPlayer *soundPlayer;
}

@end


@implementation ZChoiceListController

@synthesize choicesManager, valueConnector, buildCellHandler, selectionCloses, playSoundSample;


- (void)internalInit
{
  [super internalInit];
  // init my own stuff
  choicesManager = [[ZChoicesManager alloc] init];
  choicesManager.delegate = self;
  soundPlayer = nil;
  // options
  buildCellHandler = nil;
  selectionCloses = YES; // non-multiple-choice lists close by default when selection is made
  playSoundSample = NO; // do not assume list entries to be sound samples to play when selected
  // connector for current choice(s)
  valueConnector = [self registerValueConnector:
    [ZValueConnector connectorWithValuePath:@"currentChoice" owner:choicesManager]
  ];
}




#pragma mark - choices list generation

- (BOOL)buildDetailContent
{
  // need editing mode if reorderable
  self.editing = self.choicesManager.reorderable;
  // custom content building prevails
  if (![super buildDetailContent]) {
    // no custom content, use standard choices list building
    [self startSection];
    // - get choices in right order
    for (ZChoiceInfo *info in choicesManager.choiceInfos) {
      ZDetailViewBaseCell *cell = nil;
      if (buildCellHandler) {
        cell = buildCellHandler(self, info);
      }
      if (!cell) {
        // standard list consists of switch cells
        ZSwitchCell *sw = [[ZSwitchCell alloc] initWithStyle:UITableViewCellStyleValue1+ZDetailViewCellStyleFlagAutoLabelLayout reuseIdentifier:nil];
        sw.labelText = [info.choice valueForKey:@"text"];
        sw.tableEditingStyle = UITableViewCellEditingStyleNone; // no editing style
        sw.checkMark = !self.choicesManager.reorderable; // use in-cell switch control when cells need to be reorderable
        sw.showsReorderControl = self.choicesManager.reorderable;
        sw.shouldIndentWhileEditing = NO; // no indent (but seems not effective, need shouldIndentWhileEditingRowAtIndexPath:
        sw.showInModes = ZDetailDisplayModeAlways; // no restrictions, always show
        // - optional image
        UIImage *img = nil;
        NSString *imgName = [info.choice valueForKey:@"imageName"];
        if (imgName) {
          img = [UIImage imageNamed:imgName];
        }
        if (!img) {
          img = [info.choice valueForKey:@"image"];
        }    
        if (img) {
          sw.imageView.image = img;
        }
        // - connect to choicesManager's dynamic "sel_nn" properties which represent the selected choices
        [sw.valueConnector connectTo:choicesManager keyPath:[NSString stringWithFormat:@"sel_%lu",(unsigned long)info.index]];
        sw.valueConnector.autoSaveValue = YES;
        cell = (ZDetailViewBaseCell *)sw;
      }
      if (cell) {
        // configure
        if (self.selectionCloses && !self.choicesManager.multipleChoices) {
          // add tap handler to cause closing if needed
          [cell setTapHandler:^(ZDetailViewBaseCell *aCell, BOOL aInAccessory) {
            // perform closing later, because switching the choice must finish before!
            [(id)aCell.cellOwner performSelector:@selector(saveButtonAction) withObject:nil afterDelay:0];
            return NO; // not entirely handled, still have normal action (e.g. toggling switch values) occur
          }];
        }
        // add cell
        [self addDetailCell:cell];
      }
    }
    [self endSection];
    // overall config
    self.navigationMode =
      ZDetailNavigationModeLeftButtonCancel | // always a cancel button
      (!self.selectionCloses || self.choicesManager.multipleChoices ? ZDetailNavigationModeRightButtonSave : 0); // save only if not selection already closes the view
  }
  return YES; // built!
}



#pragma mark - UITableViewDelegate methods for reordering


- (void)tableView:(UITableView *)aTableView moveRowAtIndexPath:(NSIndexPath *)aFromIndexPath toIndexPath:(NSIndexPath *)aToIndexPath
{
  // reorder in the cells in the base class
  if ([self moveRowFromIndexPath:aFromIndexPath toIndexPath:aToIndexPath]) {
    // also reorder in the choiceInfos
    [self.choicesManager moveChoiceFrom:aFromIndexPath.row to:aToIndexPath.row];
  }  
}


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	// No insert or delete buttons
	return NO;
}



#pragma mark - ZDetailTableViewController subclassed methods

- (void)setActive:(BOOL)aActive
{
  if (aActive!=self.active) {
    // the choice manager must be active before value connectors are accessing it 
    choicesManager.active = aActive;
    // stop playing sound if any
    if (!aActive && soundPlayer) {
      [soundPlayer stop];
    }
  }
  [super setActive:aActive];
}




#pragma mark - ZChoicesManager delegate methods

/*
- (void)currentChoiceChanged
{
  
}


- (void)updateChoicesDisplay
{

}

*/

- (void)updateChoiceSelection
{
  if (playSoundSample) {
    for (ZChoiceInfo *info in choicesManager.choiceInfos) {
      if (info.selected) {
        NSString *soundName = [info.choice valueForKey:@"soundName"];
        if (!soundName) {
          // no separate sound name, assume key is the sound name
          soundName = info.key;
        }
        if (soundName) {
          // play it
          if (!soundPlayer) {
            soundPlayer = [[ZSoundPlayer alloc] init];
          }
          soundPlayer.soundName = soundName;
          [soundPlayer play];
        }
      }
    }
  }
}






@end
