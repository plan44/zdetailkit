//
//  ZChoiceListController.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 06.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailTableViewController.h"

#import "ZChoicesManager.h"
#import "ZValueConnector.h"

@class ZChoiceListController;

typedef ZDetailViewBaseCell *(^ZChoicesManagerBuildCellHandler)(ZChoiceListController *aChoiceListController , ZChoiceInfo  *aInfo);


@interface ZChoiceListController : ZDetailTableViewController <ZChoicesManagerDelegate>

@property (assign, nonatomic) BOOL selectionCloses;
@property (copy, nonatomic) ZChoicesManagerBuildCellHandler buildCellHandler;
- (void)setBuildCellHandler:(ZChoicesManagerBuildCellHandler)buildCellHandler; // declaration needed only for XCode autocompletion of block

@property (readonly, nonatomic) ZChoicesManager *choicesManager;
@property (weak, readonly, nonatomic) ZValueConnector *valueConnector;


@end
