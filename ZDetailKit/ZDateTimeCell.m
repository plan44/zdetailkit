//
//  ZDateTimeCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 11.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDateTimeCell.h"

#import "ZDate_utils.h"

#import "ZDetailTableViewController.h"
#import "ZSwitchCell.h"
#import "ZButtonCell.h"

@interface ZDateTimeCell ( /* class extension */ )
{
  NSDateFormatter *formatter;
  BOOL pickerIsUpdating;
  BOOL pickerInstalling;
  NSTimeInterval intervalFromMasterDate;
}
@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;
@property (strong, nonatomic) NSDate *masterDate;
@property (strong, nonatomic) NSDate *pickerDate;
@property (readonly, nonatomic) UIDatePicker *datePicker;
@property (readonly, nonatomic) NSString *calculatedStartDateLabelText;

- (void)updateData;

@end


@implementation ZDateTimeCell

@synthesize startDateConnector, endDateConnector, dateOnlyConnector;
@synthesize suggestedDateConnector, masterDateConnector;
@synthesize editInDetailView;

@synthesize dateOnlyInUTC, moveEndWithStart;
@synthesize autoEnterDefaultDate, suggestedDuration, minuteInterval;


- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    dateOnlyInUTC = YES; // date-only values are represented as UTC 0:00
    moveEndWithStart = YES; // move end date when start date is modified
    autoEnterDefaultDate = NO;
    editInDetailView = NO; // default to in-place editing
    pickerIsUpdating = NO;
    pickerInstalling = NO;
    suggestedDuration = 60*60; // 1 hour
    minuteInterval = 1; // 1 minute by default
    // formatter
    formatter = [[NSDateFormatter alloc] init];
    // valueConnectors
    // - first those that values might depend
    suggestedDateConnector = [self registerConnector:
      [ZDetailValueConnector connectorWithValuePath:@"suggestedDate" owner:self]
    ];
    masterDateConnector = [self registerConnector:
      [ZDetailValueConnector connectorWithValuePath:@"masterDate" owner:self]
    ];
    // - now the values
    startDateConnector = [self registerConnector:
      [ZDetailValueConnector connectorWithValuePath:@"startDate" owner:self]
    ];
    startDateConnector.nilAllowed = NO; // by default, don't allow no date
    endDateConnector = [self registerConnector:
      [ZDetailValueConnector connectorWithValuePath:@"endDate" owner:self]
    ];
    endDateConnector.nilAllowed = NO; // by default, don't allow no date
    dateOnlyConnector = [self registerConnector:
      [ZDetailValueConnector connectorWithValuePath:@"dateOnly" owner:self]
    ];
    dateOnlyConnector.nilNulValue = [NSNumber numberWithBool:NO]; // default to date+time mode
    if (aStyle & ZDetailViewCellStyleFlagAutoStyle) {
      // set recommended standard layout for dates
      self.valueViewAdjustment = self.valueViewAdjustment | ZDetailCellItemAdjustFillHeight | ZDetailCellItemAdjustExtend;
      self.descriptionViewAdjustment = self.descriptionViewAdjustment | ZDetailCellItemAdjustFillHeight;
    }
  }
  return self;
}





#pragma mark - cell configuration


@synthesize startDateLabelText, endDateLabelText, dateOnlyLabelText, clearDateButtonText;


- (NSString *)labelText
{
  // return specific text if any
  if (self.specificLabelText) return self.specificLabelText;
  // if none specified, return combination of start/end
  if (startDateLabelText) {
    if (endDateLabelText)
      return [NSString stringWithFormat:@"%@\n%@", startDateLabelText, endDateLabelText];
    else
      return startDateLabelText;
  }
  // none constructed, use default
  return [super labelText];
}


- (NSString *)calculatedStartDateLabelText
{
  if (startDateLabelText)
    return startDateLabelText;
  else
    return [super labelText];
}



- (void)setEditInDetailView:(BOOL)aEditInDetailView
{
  if (aEditInDetailView!=editInDetailView) {
    editInDetailView = aEditInDetailView;
    // needs reconfiguration of views
    [self setNeedsUpdate];
  }
}


- (void)updateForDisplay
{
  // update cell basic layout
  [super updateForDisplay];
  // adjust disclosure
  if (self.editInDetailView && self.allowsEditing) {
    // edit in separate detail view - show disclosure indicator
    self.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
  }
  else {
    // view only or inplace editing
    self.accessoryType = UITableViewCellAccessoryNone;
  }  
  // readjust font if autostyling
  if (self.detailViewCellStyle & ZDetailViewCellStyleFlagAutoStyle) {
    // smaller font
    self.valueLabel.font = [self.valueLabel.font fontWithSize:12];
    self.descriptionLabel.font = [self.descriptionLabel.font fontWithSize:12];
  }
}



#pragma mark - inplace editing date picker (used as custom input view)

@synthesize datePicker;

#define ZDATETIMECELL_INPUTVIEW_TAG 27142178

- (UIDatePicker *)datePicker
{
  if (datePicker==nil) {
    // check if current custom input view is of right type - if so, reuse it
    if ([self.cellOwner isKindOfClass:[ZDetailTableViewController class]]) {
      ZDetailTableViewController *dvc = (ZDetailTableViewController *)self.cellOwner;
      UIView *iv = dvc.customInputView;
      if (iv && iv.tag==ZDATETIMECELL_INPUTVIEW_TAG && [iv isKindOfClass:[UIDatePicker class]]) {
        // we can use this as-is
        datePicker = (UIDatePicker *)iv;
      }
    }
    if (datePicker==nil) {
      // we need a new one
      datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, self.window.frame.size.width , 216)];
      datePicker.tag = ZDATETIMECELL_INPUTVIEW_TAG; // mark it as one of mine
      datePicker.autoresizingMask = UIViewAutoresizingFlexibleTopMargin+UIViewAutoresizingFlexibleWidth;
      datePicker.contentMode = UIViewContentModeBottom;
      // set time zone (note that it must be explicitly assigned, as we use datePicker.timeZone for pickerDate adjustment)
      datePicker.timeZone = [NSTimeZone cachedTimezone];
    }
  }
  return datePicker;
}


// called to try to begin editing (e.g. getting kbd focus) in this cell. Returns YES if possible
- (BOOL)beginEditing
{
  if (!self.editInDetailView && self.allowsEditing && [self.cellOwner isKindOfClass:[ZDetailTableViewController class]]) {
    ZDetailTableViewController *dvc = (ZDetailTableViewController *)self.cellOwner;
    pickerInstalling = YES;
    // in all cases, make sure THIS object gets picker events, and previous user doesn't any more
    [self.datePicker removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    [self.datePicker addTarget:self action:@selector(pickerChanged) forControlEvents:UIControlEventValueChanged];
    self.datePicker.minuteInterval = self.minuteInterval;
    // present it (if not already presented)
    [dvc requireCustomInputView:self.datePicker];
    [self startedEditing];
    pickerInstalling = NO;
    // make sure picker has current data
    [self updateData];
    return YES;
  }
  return NO; 
}



// will be called from detailviewcontroller on all other cells when a new cell gets focus
- (void)defocusCell
{
  // only if already focused editing started, dismiss custom input view.
  if (self.focusedEditing && !pickerInstalling) {
    if ([self.cellOwner isKindOfClass:[ZDetailTableViewController class]]) {
      ZDetailTableViewController *dvc = (ZDetailTableViewController *)self.cellOwner;
      [dvc releaseCustomInputView:datePicker];
    }
    datePicker = nil;
  }
  [super defocusCell];
}



- (NSDate *)pickerDate
{
	NSDate *d = nil;
  if (datePicker) {
    NSTimeInterval offs = 0;
    if (self.dateOnly && self.dateOnlyInUTC) {
      offs = [datePicker.timeZone secondsFromGMTForDate:datePicker.date];
      // return as UTC/GMT
      d = [datePicker.date dateByAddingTimeInterval:offs];
    }
    else {
      // return as-is
      d = datePicker.date;
    }
    //DBGNSLOG(@"pickerDate returns (offs=%g): %@\n",offs,[d description]);
  }
  return d;
}



- (NSDate *)pickerDateWithPrevious:(NSDate *)aPreviousDate
{
	NSDate *picked = self.pickerDate;
  NSTimeInterval step = [aPreviousDate timeIntervalSinceDate:picked];
  if (secondsSinceMidnight(picked)<=SecondsPerHour && (step==11*SecondsPerHour || step==10*SecondsPerHour)) {
  	// exactly 11 or 10 hours backwards and landing at 0AM or 1AM in one step:
    // this is very likely caused by the UIDatePicker bug that
    // does switch from AM to PM too late when moving the hours wheel by single tap.
    // Really moving 10 or 11 hours back in a single sweep is highly improbable
    picked = [picked dateByAddingTimeInterval:12*SecondsPerHour];
    self.pickerDate = picked;
  }
  return picked;
}



- (void)setPickerDate:(NSDate *)aPickerDate
{
  if (datePicker) {
    DBGNSLOG(@"requesting pickerDate: %@\n",[aPickerDate description]);
    // round down to what picker can show
    aPickerDate = [aPickerDate dateByAddingTimeInterval:
      -((NSInteger)[aPickerDate timeIntervalSinceReferenceDate] % (datePicker.minuteInterval*SecondsPerMin))
    ];
    // shift in case of dateOnly
    NSTimeInterval offs = 0;
    if (self.dateOnly && self.dateOnlyInUTC) {
      // input is UTC, move to local time
      offs = [datePicker.timeZone secondsFromGMTForDate:aPickerDate];
      datePicker.date = [aPickerDate dateByAddingTimeInterval:-offs];
    }
    else {
      // set as-is
      datePicker.date = aPickerDate;
    }
    DBGNSLOG(@"set pickerDate to (offs=%g): %@\n",offs,[aPickerDate description]);
  }
}


- (void)pickerChanged
{
  pickerIsUpdating = YES;
	// update the start date
  self.startDate = self.pickerDate;
	[self updateData]; // update  
  pickerIsUpdating = NO;
}



#pragma mark - internal data management

@synthesize startDate, endDate, dateOnly, suggestedDate, masterDate, defaultDate;


// default date when no date is set (for picker, or new editor)
- (NSDate *)defaultDate
{  
  if (self.startDate)
    return self.startDate; // what we already have
  else if (self.suggestedDate)
    return self.suggestedDate; // ...or explicit suggestion
  else if (self.masterDate)
    return self.masterDate; // ...or master date
  else
    return [NSDate date]; // ...or current time
}


- (NSDate *)defaultEndDate
{
  return [self.defaultDate dateByAddingTimeInterval:suggestedDuration];
}



- (void)setActive:(BOOL)aActive
{
  [super setActive:aActive];
  // after everything activated, make sure data is updated (as it depends on all connectors)
  [self updateData];
}


- (void)setStartDate:(NSDate *)aStartDate
{
  if (aStartDate==nil && self.autoEnterDefaultDate) {
    aStartDate = self.defaultDate;
    self.startDateConnector.unsavedChanges = YES;
  }
  if (!sameDate(aStartDate, startDate)) {
    startDate = aStartDate;
    [self updateData];
  }
}


- (void)setEndDate:(NSDate *)aEndDate
{
  if (aEndDate==nil && self.autoEnterDefaultDate) {
    aEndDate = self.defaultEndDate;
    self.endDateConnector.unsavedChanges = YES;
  }
  if (!sameDate(aEndDate, endDate)) {
    endDate = aEndDate;
    [self updateData];
  }
}


- (void)setDateOnly:(BOOL)aDateOnly
{
  if (aDateOnly!=dateOnly) {
    dateOnly = aDateOnly;
    [self updateData];
  }
}


- (void)setSuggestedDate:(NSDate *)aSuggestedDate
{
  if (!sameDate(aSuggestedDate, suggestedDate)) {
    suggestedDate = aSuggestedDate;
  }  
}



- (void)setMasterDate:(NSDate *)aMasterDate
{
  if (!sameDate(aMasterDate, masterDate)) {
    if (startDate && masterDate && aMasterDate) {
      // we have a start date, and we already had a master date before, and have a new one now -> update start
      intervalFromMasterDate = [startDate timeIntervalSinceDate:masterDate];
      // update start date, same interval relative to new master date
      self.startDate = [aMasterDate dateByAddingTimeInterval:intervalFromMasterDate];
    }
    masterDate = aMasterDate;
    [self updateData];
  }
}





- (void)updateData
{
  // prepare formatter
  [formatter setDateStyle:NSDateFormatterMediumStyle]; // medium date
  if (self.dateOnly) {
    [formatter setTimeStyle:NSDateFormatterNoStyle]; // no time
    if (dateOnlyInUTC)
	    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]]; // real date-only are stored as UTC 0:00
  }
  else {
    [formatter setTimeStyle:NSDateFormatterShortStyle]; // short time
    [formatter setTimeZone:[NSTimeZone cachedTimezone]]; // show relative to our own zone
  }
  [formatter setDateFormat:[@"EEE, " stringByAppendingString:[formatter dateFormat]]];
  // now display
  if (endDateConnector.connected) {
    // show for start and end
    self.valueLabel.numberOfLines = 2;
    self.valueLabel.text = [NSString stringWithFormat:@"%@\n%@",
      startDate ? [formatter stringFromDate:startDate] : @"-",
      endDate ? [formatter stringFromDate:endDate] : @"-"
    ];
  }
  else {
  	// single date
    self.valueLabel.numberOfLines = 1;
    self.valueLabel.text =
    	startDate ? [formatter stringFromDate:startDate] : @"-";
	}
  // update date picker if present
  if (datePicker && !pickerIsUpdating) {
    // select mode
    if (self.dateOnly)
      self.datePicker.datePickerMode = UIDatePickerModeDate;
    else
      self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    // set value
    self.pickerDate = self.defaultDate;
  }
}


#pragma mark - detail editor

static id _sd = nil;
static id _sd_dateOnlyConnector = nil; // %%%
static id _adsw_valueConnector = nil;
static id _sd_startDateConnector = nil;

- (UIViewController *)editorForTapInAccessory:(BOOL)aInAccessory
{
  ZDetailTableViewController *dtvc = nil;
  if (self.editInDetailView && self.allowsEditing) {
    dtvc = [ZDetailTableViewController controllerWithTitle:self.detailTitleText];
    dtvc.defaultCellStyle = ZDetailViewCellStyleEntryDetail;
    dtvc.navigationMode = ZDetailNavigationModeLeftButtonCancel+ZDetailNavigationModeRightButtonSave;
    [dtvc setBuildDetailContentHandler:^(ZDetailTableViewController *c) {
      c.autoStartEditing = YES; // auto-start editing in the first field
      c.detailTableView.scrollEnabled = NO; // prevent scrolling
      [c startSection];
      // Start date
      ZDateTimeCell *sd = [c detailCell:[ZDateTimeCell class]];
      _sd = sd; // %%%
      sd.labelText = self.calculatedStartDateLabelText;
      sd.minuteInterval = self.minuteInterval;
      sd.descriptionLabel.numberOfLines = 1;
      sd.valueLabel.numberOfLines = 1;
      sd.valueLabel.textAlignment = UITextAlignmentRight;
      sd.editInDetailView = NO;
      [sd.startDateConnector connectTo:self.startDateConnector keyPath:@"internalValue"];
      sd.startDateConnector.nilAllowed = YES;
      [sd.suggestedDateConnector connectTo:self keyPath:@"defaultDate"];
      sd.startDateConnector.autoSaveValue = NO;
      sd.autoEnterDefaultDate = !self.startDateConnector.nilAllowed;
      ZDateTimeCell *ed = nil;
      if (self.endDateConnector.connected) {
        // Optional end date
        ed = [c detailCell:[ZDateTimeCell class]];
        ed.labelText = self.endDateLabelText;
        ed.minuteInterval = self.minuteInterval;
        ed.descriptionLabel.numberOfLines = 1;
        ed.valueLabel.numberOfLines = 1;
        ed.valueLabel.textAlignment = UITextAlignmentRight;
        ed.editInDetailView = NO;
        [ed.startDateConnector connectTo:self.endDateConnector keyPath:@"internalValue"];
        ed.startDateConnector.nilAllowed = YES;
        [ed.suggestedDateConnector connectTo:self keyPath:@"defaultEndDate"];
        ed.startDateConnector.autoSaveValue = NO;
        ed.autoEnterDefaultDate = !self.endDateConnector.nilAllowed;
        // keep selection on start/end only if we have two dates
        sd.keepSelectedAfterTap = YES;
        ed.keepSelectedAfterTap = YES;
        // moving end with start
        _sd_startDateConnector = sd.startDateConnector; // %%%
        if (moveEndWithStart) {
          // link to start date as master
          sd.startDateConnector.autoValidate = YES; // immediately validate to update valueForExternal
          [ed.masterDateConnector connectTo:sd.startDateConnector keyPath:@"valueForExternal"];
        }
        // preventing end before start
        ed.startDateConnector.autoValidate = YES; // immediately validate to update valueForExternal
        [ed.startDateConnector setValidationHandler:^(ZDetailValueConnector *aConnector, id aValue, NSError **aErrorP) {
          if (sd.startDateConnector.internalValue && aValue && [sd.startDateConnector.internalValue compare:aValue]==NSOrderedDescending) {
            // error - end before start
            *aErrorP = [NSError errorWithDomain:@"ZValidationError" code:NSKeyValueValidationError userInfo:
              [NSDictionary dictionaryWithObjectsAndKeys:
                @"End date must be later than or same as start date", NSLocalizedDescriptionKey,
                nil
              ]
            ];
            return NO;
          }
          return YES; // ok
        }];
      }
      if (self.startDateConnector.nilAllowed || self.endDateConnector.nilAllowed) {
        // start or end (or both) can be nil, add extra button to set nil
        ZButtonCell *b = [c detailCell:[ZButtonCell class]];
        b.labelText = self.clearDateButtonText;
        b.buttonStyle = ZButtonCellStyleCenterText;
        [b setTapHandler:^(ZDetailViewBaseCell *aCell, BOOL aInAccessory) {
          if (self.startDateConnector.nilAllowed) sd.startDateConnector.internalValue = nil;
          if (self.endDateConnector.nilAllowed) ed.startDateConnector.internalValue = nil;
          return YES; // fully handled
        }];
      }
      if (self.dateOnlyConnector.connected) {
        // Optional allday switch
        ZSwitchCell *adsw = [c detailCell:[ZSwitchCell class]];
        _adsw_valueConnector = adsw.valueConnector; // %%%
        adsw.labelText = self.dateOnlyLabelText;
        [adsw.valueConnector connectTo:self.dateOnlyConnector keyPath:@"internalValue"];
        adsw.valueConnector.autoSaveValue = NO;
        adsw.valueConnector.autoValidate = YES; // immediately validate to update valueForExternal
        // - connect the allday of the start and end (optional) dates to this switch's internal value
        _sd_dateOnlyConnector = sd.dateOnlyConnector; // %%%
        [sd.dateOnlyConnector connectTo:adsw.valueConnector keyPath:@"valueForExternal"];
        if (ed) [ed.dateOnlyConnector connectTo:adsw.valueConnector keyPath:@"valueForExternal"];
      }
      // section done
      [c endSection];
      return YES; // built
    }];
  }
  return dtvc;
}



@end
