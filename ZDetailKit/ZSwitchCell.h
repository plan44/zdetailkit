//
//  ZSwitchCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 31.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"

@interface ZSwitchCell : ZDetailViewBaseCell

@property (readonly, nonatomic) UISwitch *switchControl;

@property (assign, nonatomic) BOOL checkMark;
@property (assign, nonatomic) BOOL inverse;
@property (assign, nonatomic) NSUInteger bitMask;
@property (assign, nonatomic) NSUInteger switchVal;

@property (weak, readonly,nonatomic) ZDetailValueConnector *valueConnector;

@end
