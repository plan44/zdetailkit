//
//  ZChoiceListController.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 06.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailTableViewController.h"

#import "ZChoicesManager.h"
#import "ZDetailValueConnector.h"

@class ZChoiceListController;

typedef ZDetailViewBaseCell *(^ZChoicesManagerBuildCellHandler)(ZChoiceListController *aChoiceListController , ZChoiceInfo  *aInfo);


@interface ZChoiceListController : ZDetailTableViewController <ZChoicesManagerDelegate>

@property (assign, nonatomic) BOOL selectionCloses;
@property (copy, nonatomic) ZChoicesManagerBuildCellHandler buildCellHandler;


@property (readonly, nonatomic) ZChoicesManager *choicesManager;
@property (readonly, nonatomic) ZDetailValueConnector *valueConnector;


@end
