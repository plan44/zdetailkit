//
//  ZChoicesBaseCell.h
//
//  Created by Lukas Zeller on 01.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"
#import "ZChoicesManager.h"

@interface ZChoicesBaseCell : ZDetailViewBaseCell <ZChoicesManagerDelegate>

@property (readonly,nonatomic) ZDetailValueConnector *valueConnector;
@property (readonly,nonatomic) ZDetailValueConnector *choicesConnector;
@property (readonly,nonatomic) ZChoicesManager *choicesManager;

@end
