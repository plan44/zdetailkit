//
//  ZColorChooserCell.h
//  ZDetailKit
//
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"
#import "ZColorChooser.h"


@interface ZColorChooserCell : ZDetailViewBaseCell <ZColorChooserDelegate>

@property (readonly, nonatomic) ZColorChooser *colorChooser;

@property (readonly,nonatomic) ZDetailValueConnector *valueConnector;

@end
