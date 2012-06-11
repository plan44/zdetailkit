//
//  ZDateTimeCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 11.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"

@interface ZDateTimeCell : ZDetailViewBaseCell


@property (readonly,nonatomic) ZDetailValueConnector *startDateConnector;
@property (readonly,nonatomic) ZDetailValueConnector *endDateConnector;
@property (readonly,nonatomic) ZDetailValueConnector *dateOnlyConnector;

@property (assign,nonatomic) BOOL editInDetailView; // just show the value, edit it in detail view
@property (readonly,nonatomic) ZDetailValueConnector *suggestedDateConnector;
@property (assign,nonatomic) NSTimeInterval *suggestionOffset;
@property (assign,nonatomic) BOOL dateOnlyInUTC;

@end
