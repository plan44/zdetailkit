//
//  ZButtonCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"

#define ZBUTTONCELL_WITH_UIBUTTON 0


typedef enum {
  ZButtonCellStyleCenterText, // button with centered label
  ZButtonCellStyleDisclose, // disclosure (submenu) button
  ZButtonCellStyleDestructive, // destructive button (e.g. delete)
} ZButtonCellStyle;


@interface ZButtonCell : ZDetailViewBaseCell

@property (assign, nonatomic) ZButtonCellStyle buttonStyle;

@end
