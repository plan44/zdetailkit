//
//  ZDateTimeCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 11.06.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZDateTimeCell.h"

#import "ZDate_utils.h"
#import "ZCustomI8n.h"
#import "ZDBGMacros.h"
#import "ZTransparentTouchDetector.h"

#import "ZDetailTableViewController.h"
#import "ZSwitchCell.h"
#import "ZButtonCell.h"




@interface ZDateTimeCell ( /* class extension */ )
{
  NSDateFormatter *formatter;
  UIButton *deleteButton;
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

@synthesize dateOnlyInUTC, displayPreviousDay, showEndDateInclusive, moveEndWithStart;
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
    displayPreviousDay = NO;
    showEndDateInclusive = YES;
    // formatter
    formatter = [[NSDateFormatter alloc] init];
    // delete button created on demand
    deleteButton = nil;
    // valueConnectors
    // - first those that values might depend
    suggestedDateConnector = [self registerValueConnector:
      [ZValueConnector connectorWithValuePath:@"suggestedDate" owner:self]
    ];
    masterDateConnector = [self registerValueConnector:
      [ZValueConnector connectorWithValuePath:@"masterDate" owner:self]
    ];
    // - now the values
    startDateConnector = [self registerValueConnector:
      [ZValueConnector connectorWithValuePath:@"startDate" owner:self]
    ];
    startDateConnector.nilAllowed = NO; // by default, don't allow no date
    endDateConnector = [self registerValueConnector:
      [ZValueConnector connectorWithValuePath:@"endDate" owner:self]
    ];
    endDateConnector.nilAllowed = NO; // by default, don't allow no date
    dateOnlyConnector = [self registerValueConnector:
      [ZValueConnector connectorWithValuePath:@"dateOnly" owner:self]
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


- (UIButton *)deleteAccessoryButton
{
  if (deleteButton==nil) {
    deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteButton.frame = CGRectMake(0, 0, 20, 20);
    [deleteButton setImage:[UIImage imageNamed:@"ZDTC_delbtn.png"] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(deleteAccessoryButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  }
  return deleteButton;
}


- (void)updateForDisplay
{
  // adjust accessory
  self.editingAccessoryType = UITableViewCellAccessoryNone; // none during table editing
  BOOL needsDisclosure = NO;
  BOOL needsDelButton = NO;
  // calculate what we need
  if (self.editInDetailView && self.allowsEditing) {
    // edit in separate detail view - show disclosure indicator
    needsDisclosure = YES;
  }
  else {
    // view only or inplace editing
    if (self.startDateConnector.nilAllowed && clearDateButtonText==nil && datePicker) {
      // nil is allowed, show clear button instead
      needsDelButton = YES;
    }
  }
  // apply
  if ((self.accessoryType==UITableViewCellAccessoryDisclosureIndicator)!=needsDisclosure) {
    // needs setting new value
    self.accessoryType =
      needsDisclosure ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
  }
  if ((self.accessoryView!=nil)!=needsDelButton) {
    // needs setting new view
    self.accessoryView =
      needsDelButton ? self.deleteAccessoryButton : nil;
  }
  // update cell basic layout
  [super updateForDisplay];
  // readjust font if autostyling
  if (self.detailViewCellStyle & ZDetailViewCellStyleFlagAutoStyle) {
    // smaller font
    self.valueLabel.font = [self.valueLabel.font fontWithSize:12];
    self.descriptionLabel.font = [self.descriptionLabel.font fontWithSize:12];
  }
}



#pragma mark - custom input view

static UIDatePicker *sharedDatePicker = nil;

+ (UIDatePicker *)sharedDatePicker
{
  if (sharedDatePicker==nil) {
    // Create a date picker
    sharedDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 1, [UIScreen mainScreen].bounds.size.width , 216)];
    sharedDatePicker.autoresizingMask = UIViewAutoresizingFlexibleTopMargin+UIViewAutoresizingFlexibleWidth;
    sharedDatePicker.contentMode = UIViewContentModeBottom;
  }
  return sharedDatePicker;
}


@synthesize datePicker;

- (UIDatePicker *)datePicker
{
  if (datePicker==nil) {
    // Get the shared instance
    datePicker = [self.class sharedDatePicker];
    // set time zone (note that it must be explicitly assigned, as we use datePicker.timeZone for pickerDate adjustment)
    datePicker.timeZone = [NSTimeZone cachedTimezone];
    // set up for use with this cell
    // i.e. make sure THIS cell gets picker events, and previous user not any more (in case of future %%% shared picker)
    // - remove previous target and recognizers
    [datePicker removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    for (UIGestureRecognizer *g in [datePicker.gestureRecognizers copy]) [datePicker removeGestureRecognizer:g];
    // - add new target
    [datePicker addTarget:self action:@selector(pickerChanged) forControlEvents:UIControlEventValueChanged];
    // - add detector to see when the view is touched
    [datePicker addGestureRecognizer:[ZTransparentTouchDetector transparentTouchDetectorWithHandler:^void(ZTransparentTouchDetector *aGestureRecognizer) {
      // there's a touch on the picker, apply data if still empty
      if (self.startDate==nil) {
        self.startDate = self.pickerDate;
      }
    }]];
    // adjust minute interval
    datePicker.minuteInterval = self.minuteInterval;
  }
  return datePicker;
}


- (UIView *)inputView
{
  UIView *iv = [self datePicker];
  // make sure picker has current data
  [self updateData];
  return iv;
}


- (BOOL)canBecomeFirstResponder
{
  return self.allowsEditing && !self.editInDetailView;
}



// called to try to begin editing (e.g. getting kbd focus) in this cell. Returns YES if possible
- (BOOL)beginEditing
{
  ZDetailTableViewController *dvc = self.detailTableViewController;
  if (dvc && [self canBecomeFirstResponder]) {
    pickerInstalling = YES;
    // present it (if not already presented)
    [self becomeFirstResponder];
    // now editing can start
    [self startedEditing];
    pickerInstalling = NO;
    // update my own display status
    [self updateForDisplay];    
    // in case we have a suggestion, and start date is empty, set it now
    if (!self.startDateConnector.nilAllowed && startDate==nil) {
      // we MUST have a value, apply default
      self.startDate = self.defaultDate;
    }
    return YES;
  }
  return NO; 
}



// will be called from detailviewcontroller on all other cells when a new cell gets focus
- (void)defocusCell
{
  // only if already focused editing started, dismiss custom input view.
  if (self.focusedEditing && !pickerInstalling) {
    [self resignFirstResponder];
    [self updateForDisplay];
  }
  [super defocusCell];
}



- (NSDate *)pickerDate
{
	NSDate *d = nil;
  if (datePicker) {
    NSTimeInterval offs = 0;
    d = datePicker.date;
    if (self.dateOnly) {
      if (self.dateOnlyInUTC) {
        // return as UTC/GMT
        offs += [datePicker.timeZone secondsFromGMTForDate:datePicker.date];
      }
      if (self.displayPreviousDay) {
        // picker displays one day earlier than the (excluded) end date, so adjust back here before returning
        offs += SecondsPerDay;
      }
      // adjust
      d = [d dateByAddingTimeInterval:offs];
    }
    //DBGNSLOG(@"pickerDate returns (offs=%g): %@\n",offs,[d description]);
  }
  return d;
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
    if (self.dateOnly) {
      if (self.dateOnlyInUTC) {
        // input is UTC, move to local time
        offs -= [datePicker.timeZone secondsFromGMTForDate:aPickerDate];
      }
      if (self.displayPreviousDay) {
        // picker displays one day earlier than the (excluded) end date, so adjust back here before returning
        offs -= SecondsPerDay;
      }
    }
    datePicker.date = [aPickerDate dateByAddingTimeInterval:offs];
    DBGNSLOG(@"set pickerDate to (offs=%g): %@\n", offs, [aPickerDate description]);
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


- (void)deleteAccessoryButtonPressed
{
  self.startDate = nil; // remove date
}



#pragma mark - internal data management

@synthesize startDate, endDate, dateOnly, suggestedDate, masterDate, defaultDate;


// should return true when cell is presenting an "empty" value (such that empty cells can be hidden in some modes)
- (BOOL)presentingEmptyValue
{
  // for switches, we consider switches in off position as "empty"
  return startDate==nil && endDate==nil;
}




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
  BOOL unsaved = NO;
  if (aStartDate==nil && self.autoEnterDefaultDate) {
    aStartDate = self.defaultDate;
    unsaved = YES; // we modified the start date
  }
  if (!sameDate(aStartDate, startDate)) {
    startDate = aStartDate;
    [self updateData];
  }
  if (unsaved) {
    // change from within, unsaved now
    self.startDateConnector.unsavedChanges = unsaved;
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
  NSDate *sd = startDate ? [startDate dateByAddingTimeInterval:self.dateOnly && self.displayPreviousDay ? -SecondsPerDay : 0] : nil;
  if (endDateConnector.connected) {
    // show for start and end
    NSDate *ed = endDate ? [endDate dateByAddingTimeInterval:self.dateOnly && self.showEndDateInclusive ? -SecondsPerDay : 0] : nil;
    self.valueLabel.numberOfLines = 2;
    self.valueLabel.text = [NSString stringWithFormat:@"%@\n%@",
      sd ? [formatter stringFromDate:sd] : @"-",
      ed ? [formatter stringFromDate:ed] : @"-"
    ];
  }
  else {
  	// single date
    self.valueLabel.numberOfLines = 1;
    self.valueLabel.text =
    	sd ? [formatter stringFromDate:sd] : @"-";
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

- (UIViewController *)editorForTapInAccessory:(BOOL)aInAccessory
{
  ZDetailTableViewController *dtvc = nil;
  if (self.editInDetailView && self.allowsEditing) {
    dtvc = [ZDetailTableViewController controllerWithTitle:self.detailTitleText];
    dtvc.defaultCellStyle = ZDetailViewCellStyleEntryDetail|ZDetailViewCellStyleFlagInherit;
    dtvc.navigationMode = ZDetailNavigationModeLeftButtonCancel+ZDetailNavigationModeRightButtonSave;
    [dtvc setBuildDetailContentHandler:^(ZDetailTableViewController *c) {
      c.autoStartEditing = YES; // auto-start editing in the first field
      c.detailTableView.scrollEnabled = NO; // prevent scrolling
      [c startSection];
      // Start date
      ZDateTimeCell *sd = [c detailCell:[ZDateTimeCell class]];
      sd.labelText = self.calculatedStartDateLabelText;
      sd.clearDateButtonText = self.clearDateButtonText; // inherit as it switches off clear button accessory if we have a common clear button
      sd.minuteInterval = self.minuteInterval;
      sd.descriptionLabel.numberOfLines = 1;
      sd.valueLabel.numberOfLines = 1;
      sd.valueLabel.textAlignment = NSTextAlignmentRight;
      sd.editInDetailView = NO;
      sd.displayPreviousDay = self.displayPreviousDay;
      [sd.startDateConnector connectTo:self.startDateConnector keyPath:@"internalValue"];
      sd.startDateConnector.nilAllowed = self.startDateConnector.nilAllowed;
      [sd.suggestedDateConnector connectTo:self keyPath:@"defaultDate"];
      sd.startDateConnector.autoSaveValue = NO;
      sd.autoEnterDefaultDate = !self.startDateConnector.nilAllowed;
      sd.startDateConnector.autoValidate = YES; // immediately validate to update valueForExternal (for being master, and for actual validation)
      ZDateTimeCell *ed = nil;
      if (self.endDateConnector.connected) {
        // Optional end date
        ed = [c detailCell:[ZDateTimeCell class]];
        ed.labelText = self.endDateLabelText;
        ed.clearDateButtonText = self.clearDateButtonText; // inherit as it switches off clear button accessory if we have a common clear button
        ed.minuteInterval = self.minuteInterval;
        ed.descriptionLabel.numberOfLines = 1;
        ed.valueLabel.numberOfLines = 1;
        ed.valueLabel.textAlignment = NSTextAlignmentRight;
        ed.editInDetailView = NO;
        ed.displayPreviousDay = self.showEndDateInclusive;
        [ed.startDateConnector connectTo:self.endDateConnector keyPath:@"internalValue"];
        ed.startDateConnector.nilAllowed = self.endDateConnector.nilAllowed;
        [ed.suggestedDateConnector connectTo:self keyPath:@"defaultEndDate"];
        ed.startDateConnector.autoSaveValue = NO;
        ed.autoEnterDefaultDate = !self.endDateConnector.nilAllowed;
        // keep selection on start/end only if we have two dates
        sd.keepSelectedAfterTap = YES;
        ed.keepSelectedAfterTap = YES;
        // moving end with start
        if (self.moveEndWithStart) {
          // link to start date as master
          [ed.masterDateConnector connectTo:sd.startDateConnector keyPath:@"valueForExternal"];
        }
        // preventing end before start
        ed.startDateConnector.autoValidate = YES; // immediately validate to update valueForExternal
        [ed.startDateConnector setValidationHandler:^(ZValueConnector *aConnector, id aValue, NSError **aErrorP) {
          NSDate *e = (NSDate *)aValue;
          if (e && sd.dateOnly && self.showEndDateInclusive) {
            // if end date is shown inclusive, actual end date must be at least 1 day more than start
            e = [e dateByAddingTimeInterval:-SecondsPerDay];
          }
          if (sd.startDateConnector.internalValue && e && [sd.startDateConnector.internalValue compare:e]==NSOrderedDescending) {
            // error - end before start
            *aErrorP = [NSError errorWithDomain:@"ZValidationError" code:NSKeyValueValidationError userInfo:@{
              NSLocalizedDescriptionKey: ZLocalizedStringWithDefault(@"ZDTK_ValErr_EndBeforeStart",@"End date must be later than or same as start date")
            }];
            return NO;
          }
          return YES; // ok
        }];
      }
      if (self.clearDateButtonText && (self.startDateConnector.nilAllowed || self.endDateConnector.nilAllowed)) {
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
      if (self.dateOnlyConnector.connected && self.dateOnlyConnector.readonly==NO) {
        // Optional allday switch if allday status is not readonly
        ZSwitchCell *adsw = [c detailCell:[ZSwitchCell class]];
        adsw.labelText = self.dateOnlyLabelText;
        [adsw.valueConnector connectTo:self.dateOnlyConnector keyPath:@"internalValue"];
        adsw.valueConnector.autoSaveValue = NO;
        adsw.valueConnector.autoValidate = YES; // immediately validate to update valueForExternal
        // - connect the allday of the start and end (optional) dates to this switch's internal value
        [sd.dateOnlyConnector connectTo:adsw.valueConnector keyPath:@"valueForExternal"];
        if (ed) [ed.dateOnlyConnector connectTo:adsw.valueConnector keyPath:@"valueForExternal"];
        // prevent tapping cells from defocusing other cells
        adsw.tapClaimsFocus = NO;
        [adsw.valueConnector setValueChangedHandler:^BOOL(ZValueConnector *aConnector) {
          if (!aConnector.loading && self.showEndDateInclusive && ed.startDateConnector.internalValue) {
            if ([[aConnector internalValue] intValue]!=0) {
              // switching to dateOnly, make sure end date is next day
              ed.startDateConnector.internalValue = [ed.startDateConnector.internalValue dateByAddingTimeInterval:SecondsPerDay];
            }
            else {
              ed.startDateConnector.internalValue = [ed.startDateConnector.internalValue dateByAddingTimeInterval:-SecondsPerDay];
            }
          }
          return NO; // not fully handled yet
        }];
      }
      // section done
      [c endSection];
      return YES; // built
    }];
  }
  return dtvc;
}



@end
