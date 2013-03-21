//
//  ZChoicesBaseCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 01.06.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"
#import "ZChoicesManager.h"

@interface ZChoicesBaseCell : ZDetailViewBaseCell <ZChoicesManagerDelegate>

@property (weak, readonly,nonatomic) ZValueConnector *valueConnector;
@property (weak, readonly,nonatomic) ZValueConnector *choicesConnector;
@property (readonly,nonatomic) ZChoicesManager *choicesManager;

@end
