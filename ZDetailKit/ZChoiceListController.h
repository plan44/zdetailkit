//
//  ZChoiceListController.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 06.06.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZDetailTableViewController.h"

#import "ZChoicesManager.h"
#import "ZValueConnector.h"

@class ZChoiceListController;

typedef ZDetailViewBaseCell *(^ZChoicesManagerBuildCellHandler)(ZChoiceListController *aChoiceListController , ZChoiceInfo  *aInfo);


@interface ZChoiceListController : ZDetailTableViewController <ZChoicesManagerDelegate>

/// if set and this is a list of single choices, the list closes as soon as a new selection is made
/// if not set, making a selection does not close the list, explicit done or cancel buttons must be used
@property (assign, nonatomic) BOOL selectionCloses;

/// if set, making a selection will try to play a sound named according to the "soundName" in the choice dict if present, or
/// otherwise a sound named according to the choice key. Closing the list will stop the sound.
@property (assign, nonatomic) BOOL playSoundSample;

@property (copy, nonatomic) ZChoicesManagerBuildCellHandler buildCellHandler;
- (void)setBuildCellHandler:(ZChoicesManagerBuildCellHandler)buildCellHandler; // declaration needed only for XCode autocompletion of block

@property (readonly, nonatomic) ZChoicesManager *choicesManager;
@property (weak, readonly, nonatomic) ZValueConnector *valueConnector;


@end
