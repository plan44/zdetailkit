//
//  ZColorChooserCell.h
//  ZDetailKit
//
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"
#import "ZColorChooser.h"


@interface ZColorChooserCell : ZDetailViewBaseCell <ZColorChooserDelegate>

@property (readonly, nonatomic) ZColorChooser *colorChooser;

@property (weak, readonly,nonatomic) ZValueConnector *valueConnector;

@end
