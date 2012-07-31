//
//  ZSliderCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 31.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"

@interface ZSliderCell : ZDetailViewBaseCell

@property (readonly, nonatomic) UISlider *sliderControl;

@property (weak, readonly,nonatomic) ZDetailValueConnector *valueConnector;

@end
