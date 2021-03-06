//
//  ZChoicesBaseCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 01.06.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZChoicesBaseCell.h"

#import "ZDetailTableViewController.h"



@implementation ZChoicesBaseCell

@synthesize valueConnector, choicesConnector, choicesManager;


- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    // choices manager
    choicesManager = [[ZChoicesManager alloc] init];
    choicesManager.delegate = self;
    // connector for current choice(s)
    valueConnector = [self registerValueConnector:
      [ZValueConnector connectorWithValuePath:@"choicesManager.currentChoice" owner:self]
    ];
    // connector for choices array (array with a dictionary for each choice)
    choicesConnector = [self registerValueConnector:
      [ZValueConnector connectorWithValuePath:@"choicesManager.choicesArray" owner:self]
    ];
  }
  return self;
}




#pragma mark - updating


- (void)setActive:(BOOL)aActive
{
  // the choice manager must be active before value connectors are accessing it 
  self.choicesManager.active = aActive;
  [super setActive:aActive];
}


- (void)updateForDisplay
{
  // update cell basics
  [super updateForDisplay];
}



#pragma mark - ZChoicesManager delegate methods


// called when change of parameters cause a choiceInfo rebuild that affects currentChoice
- (void)currentChoiceChanged
{
  self.valueConnector.unsavedChanges = YES;
}


- (void)updateChoicesDisplay
{
  // NOP in base class
}


- (void)updateChoiceSelection
{
  // NOP in base class
}


@end
