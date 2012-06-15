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

@property (retain,nonatomic) NSString *startDateLabelText;
@property (retain,nonatomic) NSString *endDateLabelText;
@property (retain,nonatomic) NSString *dateOnlyLabelText;


@property (assign,nonatomic) BOOL editInDetailView; // just show the value, edit it in detail view
@property (readonly,nonatomic) ZDetailValueConnector *suggestedDateConnector;
@property (readonly,nonatomic) ZDetailValueConnector *masterDateConnector; // if this changes, my (start)date must keep same time interval to it
@property (assign,nonatomic) NSTimeInterval *suggestionOffset;
@property (assign,nonatomic) BOOL dateOnlyInUTC;
@property (assign,nonatomic) BOOL moveEndWithStart; // used to make start the master date of end in detail editor

@end
