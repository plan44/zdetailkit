//
//  ZDateTimeCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 11.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"


/// ZDateTimeCell can edit a single date or date/time, or a pair of start/end dates or date/time.
/// Optionally, it can also allow users to switch between date and date/time modes
@interface ZDateTimeCell : ZDetailViewBaseCell

/// @name data connection

/// connector for the start NSDate value (or the only value if endDateConnector is not used)
@property (weak, readonly,nonatomic) ZValueConnector *startDateConnector;

/// connector for the end NSDate value
/// @note leave unconnected to show only a single date
@property (weak, readonly,nonatomic) ZValueConnector *endDateConnector;

/// connector for a boolean value to switch between date and date/time
/// @note leave unconnected and set the mode with dateOnly property when users may not choose between date-only and datetime
@property (weak, readonly,nonatomic) ZValueConnector *dateOnlyConnector;

/// set the mode to date-only (YES) or date/time (NO) when the dateOnlyConnector is not used
@property (assign, nonatomic) BOOL dateOnly;


/// @name labels

/// description text for the start date (or only date)
@property (strong,nonatomic) NSString *startDateLabelText;

/// description text for end date in cells that have the endDateConnector active.
@property (strong,nonatomic) NSString *endDateLabelText;

/// description text for date-only switch in cells that have the dateOnlyConnector active (i.e. can switch between date and date/time entry)
@property (strong,nonatomic) NSString *dateOnlyLabelText;

/// if set to non-nil, and editInDetailView is set, and dates are allowed to be nil,
/// a button with this text will appear in detail editing views to clear the date input. Without this text defined
/// an accessory button will be used instead. Default: nil.
@property (strong,nonatomic) NSString *clearDateButtonText;

/// @name value suggestions

/// this can be set to a date suggestion. This date will be used as default value
/// (in the date picker when no value has been set yet, or auto-entered into fields that require a value).
/// If nil, the current time is used as default value
@property (strong, nonatomic) NSDate *suggestedDate;

/// the suggestedDate can be connected to a model value with this connector
@property (weak, readonly,nonatomic) ZValueConnector *suggestedDateConnector;

/// a time interval used as a default duration for start/end editing. This duration is added to the suggestedDate
/// to generate the defaultEndDate.
@property (assign,nonatomic) NSTimeInterval suggestedDuration; // used to set default end date

/// if set, in start/end editing, the end date will move when the start date is changed to keep the duration unchanged
@property (assign,nonatomic) BOOL moveEndWithStart; // used to make start the master date of end in detail editor

/// if set, the default date is auto-entered into the date field when no date is set yet.
/// Otherwise, the default date is only shown in the picker and copied into the date field when the picker is touched or changed
@property (assign,nonatomic) BOOL autoEnterDefaultDate; // set the default date when no date is found

/// returns the current default date
/// @note this returns the first non-nil value of startDate, suggestedDate, masterDate, current time, in that order. 
@property (weak, readonly,nonatomic) NSDate *defaultDate;
/// returns the current default end date, which is defaultDate plus suggestedDuration
@property (weak, readonly,nonatomic) NSDate *defaultEndDate;

/// this can be connected to a model value or a "valueForExternal" of another field's connector, in order to
/// keep this date adjusted such that the time interval between this date and the master date remains the same
/// when the master date is changed.
/// @note this is useful for example for reminder time setting, which should be kept adjusted to a event start date.
@property (weak, readonly,nonatomic) ZValueConnector *masterDateConnector; // if this changes, my (start)date must keep same time interval to it

/// @name behaviour

/// if set, a separate editor is opened to edit the values (rather than in-place)
@property (assign,nonatomic) BOOL editInDetailView; // just show the value, edit it in detail view

/// sets the minute step size for the date picker
@property (assign,nonatomic) NSInteger minuteInterval; // for date picker

/// if set, date-only values are always represented in UTC (independently from the current time zone). This is useful
/// for implementing real date-only values (which specify a calendar day, and not an absolute point-in-time)
@property (assign,nonatomic) BOOL dateOnlyInUTC;


@end
