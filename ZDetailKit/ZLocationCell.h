//
//  ZLocationCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 17.02.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"


@interface ZLocationCell : ZDetailViewBaseCell

@property (weak, readonly,nonatomic) ZDetailValueConnector *valueConnector;

// connectors for the edited values
@property (weak, readonly,nonatomic) ZDetailValueConnector *textValueConnector;
@property (weak, readonly,nonatomic) ZDetailValueConnector *coordinateValueConnector;

@property (strong,nonatomic) NSString *editedText;
@property (strong,nonatomic) NSValue *editedCoordinate;

@end
