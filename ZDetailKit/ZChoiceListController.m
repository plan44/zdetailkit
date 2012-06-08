//
//  ZChoiceListController.m
//
//  Created by Lukas Zeller on 06.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZChoiceListController.h"

#import "ZSwitchCell.h"

@interface ZChoiceListController ()

@end

@implementation ZChoiceListController

@synthesize choicesManager, valueConnector, buildCellHandler, selectionCloses;


- (void)internalInit
{
  [super internalInit];
  // init my own stuff
  choicesManager = [[ZChoicesManager alloc] init];
  choicesManager.delegate = self;
  // options
  buildCellHandler = nil;
  selectionCloses = YES; // non-multiple-choice lists close when selection is made
  // connector for current choice(s)
  valueConnector = [self registerConnector:
    [ZDetailValueConnector connectorWithValuePath:@"currentChoice" owner:choicesManager]
  ];
}


- (void)dealloc
{
  [buildCellHandler release];
  [choicesManager release];
  [super dealloc];
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
        ZSwitchCell *sw = [[ZSwitchCell alloc] initWithStyle:UITableViewCellStyleValue1+ZDetailViewCellStyleFlagCustomLayout reuseIdentifier:nil];
        sw.labelText = [info.choice valueForKey:@"text"];
        sw.tableEditingStyle = UITableViewCellEditingStyleNone; // no editing style
        sw.checkMark = !self.choicesManager.reorderable; // use in-cell switch control when cells need to be reorderable
        sw.showsReorderControl = self.choicesManager.reorderable;
        sw.shouldIndentWhileEditing = NO; // no indent (but seems not effective, need shouldIndentWhileEditingRowAtIndexPath:
        sw.neededModes = 0; // no restrictions, always show
        // - connect to choicesManager's dynamic "sel_nn" properties which represent the selected choices
        [sw.valueConnector connectTo:choicesManager keyPath:[NSString stringWithFormat:@"sel_%d",info.index]];
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
  // reorder in 
  if ([self moveRowFromIndexPath:aFromIndexPath toIndexPath:aToIndexPath]) {
    // reorder in the choiceInfos
    [self.choicesManager moveChoiceFrom:aFromIndexPath.row to:aToIndexPath.row];
  }  
}


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	// No insert or delete buttons
	return NO;
}



#pragma mark - ZDetailTableViewController subclassed methods

- (void)setCellsActive:(BOOL)aCellsActive
{
  if (aCellsActive!=self.cellsActive) {
    // the choice manager must be active before value connectors are accessing it 
    choicesManager.active = aCellsActive;
  }
  [super setCellsActive:aCellsActive];
}




#pragma mark - ZChoicesManager delegate methods

/*
- (void)currentChoiceChanged
{
  
}


- (void)updateChoicesDisplay
{
  [self.detailTableView reloadData];
}


- (void)updateChoiceSelection
{
  [self.detailTableView reloadData];
}*/





@end
