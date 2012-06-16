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
@property (assign,nonatomic) NSTimeInterval suggestedDuration; // used to set default end date
@property (assign,nonatomic) NSInteger minuteInterval; // for date picker
@property (readonly,nonatomic) ZDetailValueConnector *masterDateConnector; // if this changes, my (start)date must keep same time interval to it
@property (assign,nonatomic) BOOL dateOnlyInUTC;
@property (assign,nonatomic) BOOL moveEndWithStart; // used to make start the master date of end in detail editor
@property (assign,nonatomic) BOOL autoEnterDefaultDate; // set the default date when no date is found

@property (readonly,nonatomic) NSDate *defaultDate;
@property (readonly,nonatomic) NSDate *defaultEndDate;
@end
