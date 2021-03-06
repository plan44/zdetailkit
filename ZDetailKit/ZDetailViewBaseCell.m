//
//  ZDetailViewBaseCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 17.05.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"

#import "NSObject+ZValueConnectorContainer.h"
#import "ZDBGMacros.h"

// if defined, living instances are recorded in a set to monitor if all are closed properly (DEBUG only)
#define DETAILVIEWCELLS_MONITORINSTANCES 0


#if DETAILVIEWCELLS_MONITORINSTANCES && defined(DEBUG)

#define COUNTONLY 0

#if !COUNTONLY
NSMutableSet *openDetailViewCellsSet = nil;
#endif
static unsigned long totalCells = 0;

void cell_created(id aCell)
{
  totalCells++;
  NSLog(@"+++ (%03lu) 0x%lX : %@", totalCells, (intptr_t)aCell, [aCell description]);
  #if !COUNTONLY
  if (!openDetailViewCellsSet) {
    openDetailViewCellsSet = [[NSMutableSet alloc] init];
  }
  [openDetailViewCellsSet addObject:[NSNumber numberWithUnsignedLongLong:(intptr_t)aCell]];
  #endif
}

void cell_deleted(id aCell)
{
  totalCells--;
  NSLog(@"--- (%03lu) 0x%lX : %@", totalCells, (intptr_t)aCell, [aCell description]);
  #if !COUNTONLY
  [openDetailViewCellsSet removeObject:[NSNumber numberWithUnsignedLongLong:(intptr_t)aCell]];
  NSMutableString *s = [NSMutableString string];
  unsigned long cc = 0;
  for (id cell in openDetailViewCellsSet) {
    __unsafe_unretained ZDetailViewBaseCell *dvc = (__bridge ZDetailViewBaseCell *)((void *)[cell unsignedLongLongValue]);
    if (!dvc.disconnected) {
      cc++;
      [s appendFormat:@"\n   - 0x%lX : %@", (intptr_t)dvc, [dvc description]];
    }
  }
  NSLog(@"------ Still %lu cells (of %lu existing) are connected:%@", cc, (unsigned long)openDetailViewCellsSet.count, s);
  #endif
}

#define CELL_CREATED(k) cell_created(k)
#define CELL_DELETED(k) cell_deleted(k)
#define CELLNSLOG(...) DBGNSLOG(__VA_ARGS__)
#define CELLLOGGING 1

#else
#define CELL_CREATED(k)
#define CELL_DELETED(k)
#define CELLNSLOG(...)
#define CELLLOGGING 0
#endif




@interface ZDetailViewBaseCell ( /* class extension */ )
{
  // non-public instance vars
  BOOL needsDisplayUpdate;
  // normal description label colors (used to remember during validation errors)
  UIColor *nonErrorTextColor;
  UIColor *nonErrorHighlightedTextColor;
  // measured values for content indenting
  CGFloat contentLeftMargin; // origin.x of contentView in non-tableedit mode relative to its superview
  CGFloat contentRightMargin; // right margin (space to size of superview on the right)
  CGFloat backgroundLeftMargin; // origin.x of contentView in non-tableedit mode relative to its superview
  CGFloat backgroundRightMargin; // right margin (space to size of superview on the right)
  // image view usage
  BOOL imageViewInUse;
  // autoopening
  BOOL shouldAutoOpen;
  #if CELLLOGGING
  BOOL disconnected;
  #endif
}

@end



@implementation ZDetailViewBaseCell

@dynamic valueConnectors;

@synthesize basicCellStyle, detailViewCellStyle;

// internal initialisation, might be derived in subclasses
- (void)internalInit
{
  #if CELLLOGGING
  disconnected = NO;
  #endif
  // needed mode flags to be visible (included in table view)
  showInModes = ZDetailDisplayModeAlways; // always visible by default
  showsValidationStatus = YES; // show validation problems
  active = NO;
  shouldAutoOpen = NO;
  cellOwner = nil;
  needsDisplayUpdate = YES; // certainy we need a data update at least once after init
  focusedEditing = NO; // focused editing (in-cell editors that can get/loose focus) not in progress
  // custom labels
  valueLabel = nil;
  descriptionLabel = nil;
  // geometry params
  standardCellHeight = -1; // undefined, owning view controllers tableview rowheight will be used
  // - share of value cell relative to entire cell depends on style
  if (basicCellStyle==UITableViewCellStyleDefault)
    valueCellShare = 1;
  else if (basicCellStyle==UITableViewCellStyleValue1)
    valueCellShare = 0.4;
  else
    valueCellShare = 0.65;
  contentMargins = CGSizeMake(16, 5);
  labelValueMargin = 16;
  descriptionViewAdjustment = ZDetailCellItemAdjustMiddle;
  valueViewAdjustment = ZDetailCellItemAdjustMiddle;
  // - other internals
  nonErrorTextColor = nil;
  nonErrorHighlightedTextColor = nil;
  imageViewInUse = NO; // will be set when imageView property is first accessed
  // - measured values for content indent
  contentLeftMargin = -1; // not yet measured
  contentRightMargin = -1; // not yet measured
  backgroundLeftMargin = -1; // not yet measured
  backgroundRightMargin = -1; // not yet measured
  // other params
  tableEditingStyle = UITableViewCellEditingStyleDelete; // table editing defaults to delete
  readOnly = NO;
  tapClaimsFocus = YES;
  labelText = nil;
  keepSelectedAfterTap = NO;
  autoSetDescriptionLabelText = YES; // set descriptionlabel to labelText automatically
  detailTitleText = nil;
  placeholderText = nil;
  // Custom layout mechanism init
  if (detailViewCellStyle & ZDetailViewCellStyleFlagAutoLabelLayout) {
    // put labels under custom layout control
    self.descriptionView = self.descriptionLabel;
    self.valueView = self.valueLabel;
  }
  // UITableViewCell properties
  self.selectionStyle = UITableViewCellSelectionStyleBlue ; // standard blue selection
}



+ (id)alloc
{
  id obj = [super alloc];
  CELL_CREATED(obj);
  return obj;
}


- (void)dealloc
{
  [self disconnect];
  CELL_DELETED(self);
}



// UITableViewCell compatible, except that style has extended functionality (includes flags)
- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier;
{
	basicCellStyle = (UITableViewCellStyle)(aStyle & ZDetailViewCellStyleBasicStyleMask);
	if ((self = [super initWithStyle:basicCellStyle reuseIdentifier:nil])) {
    // save style
    detailViewCellStyle = aStyle;
    // now rest of initialisation
    [self internalInit];
  }
  return self;
}
    

#pragma mark - debugging aid

- (NSString *)description
{
  //return [NSString stringWithFormat:@"<ZDetailViewBaseCell labelText='%@' <%@>>", self.labelText, super.description];
  return [NSString stringWithFormat:@"<%@ %slabelText='%@'>", [[self class] description], disconnected ? "DISCONNECTED " : "", self.labelText];
}


#pragma mark - ZDetailViewCell protocol methods - might be derived in subclasses

@synthesize disconnected;

- (void)disconnect
{
  // make inactive
  CELLNSLOG(@">>> (%03lu) 0x%lX : %@ -> DISCONNECTING", totalCells, (intptr_t)self, [self description]);
  // disable all connections to make sure no KVO remains active to
  // embedded objects that might get destroyed before the embedded valueConnectors
  // (as we don't have any control over ARCs order of deallocation)
  self.active = NO;
  // disconnect all value connectors
  [self disconnectValues];
  // clear all blocks to untie all held references
  self.cellVisibleInModeHandler = nil;
  self.valueChangedHandler = nil;
  self.tapHandler = nil;
  self.editorSetupHandler = nil;
  self.editorFinishedHandler = nil;
  self.editingEndedHandler = nil;
  self.validationStatusHandler = nil;
  // clear other references
  self.cellOwner = nil;
  self.valueLabel = nil;
  self.valueView = nil;
  self.descriptionView = nil;
  self.descriptionLabel = nil;
  #if CELLLOGGING
  disconnected = YES;
  #endif
}



@synthesize active, autoOpen;

- (void)setActive:(BOOL)aActive
{
  if (aActive!=active) {
    active = aActive;
    // before going from inactive to active, prepare cell for display
    // (this might include configuring connectors, which must occur before first connection)
    if (aActive) {
      // going active
      [self prepareForDisplay];
    }
    // now activate connectors
    [self setValueConnectorsActive:aActive];
    // make sure we are prepared for display
    [self prepareForDisplay];
  }
}



// true if cell should be visible in the passed mode
// Note: ZDetailDisplayModeXXXXNonEmpty flags can be passed set in aMode to
//   force cell to be treated as non-empty in a particular mode
- (BOOL)nowVisibleInMode:(ZDetailDisplayMode)aMode
{
  // Or in non-empty flag from actual internal state
  if (![self presentingEmptyValue]) {
    // cell is currently non-empty, so adapt aMode to also pass the XXXnonEmpty requirements
    if (aMode & ZDetailDisplayModeBasics)
      aMode |= ZDetailDisplayModeBasicsNonEmpty;
    if (aMode & ZDetailDisplayModeDetails)
      aMode |= ZDetailDisplayModeDetailsNonEmpty;
    if (aMode & ZDetailDisplayModeViewing)
      aMode |= ZDetailDisplayModeViewingNonEmpty;
    if (aMode & ZDetailDisplayModeEditing)
      aMode |= ZDetailDisplayModeEditingNonEmpty;
  }
  // let handler decide if we have one
  if (self.cellVisibleInModeHandler) {
    return self.cellVisibleInModeHandler(self, aMode);
  }
  // default behaviour: visible if
  // - no level flags specified in showInModes or at least one of them matching
  // - AND no editing flags specified in showInModes or at least one of them matching
  return
    ((self.showInModes & ZDetailDisplayModeLevelMask)==0 || (self.showInModes & aMode & ZDetailDisplayModeLevelMask)!=0) &&
    ((self.showInModes & ZDetailDisplayModeEditingMask)==0 || (self.showInModes & aMode & ZDetailDisplayModeEditingMask)!=0);
}


// called to prepare for (re)display of the cell
// Note:for ZDetailViewBaseCell, just derive updateForDisplay and use setNeedsUpdate!
- (void)prepareForDisplay
{
  if (needsDisplayUpdate) {
    [self updateForDisplay]; // perform the update
    needsDisplayUpdate = NO;
  }
}


// will be called from detailviewcontroller on all other cells when a new cell gets focus
- (void)defocusCell
{
  // end focused editing
  if (focusedEditing) {
    [self endedEditingWithGotoNext:NO];
  }
}


// called to try to begin editing (e.g. getting kbd focus) in this cell. Returns YES if possible
- (BOOL)beginEditing
{
  return NO; // base class cannot begin editing
}


// set current cell mode
// Note: displayMode property is readonly and not part of ZDetailViewCell protocol
- (void)setDisplayMode:(ZDetailDisplayMode)aMode animated:(BOOL)aAnimated
{
  if (aMode!=self.displayMode) {
    displayMode = aMode;
    [self setNeedsUpdate];
    if (aAnimated) {
      // perform the update with animations
      [UIView animateWithDuration:0.2 animations:^{
        [self prepareForDisplay];
      }];
    }
  }
}


// will be called from cellOwner to give cell a chance to handle taps internally
// Note: this will be called before trying to open a standard editor
- (BOOL)handleTapInAccessory:(BOOL)aInAccessory
{
  BOOL handled = NO;
  // base class action is calling handler, if any
  if (tapHandler) {
    handled = tapHandler(self,aInAccessory);
  }
	return handled;
}


// returns the standard editor, configured for editing the cell's value
// The caller only needs to present that editor (push to navcontroller, show as popover)
- (UIViewController *)editorForTapInAccessory:(BOOL)aInAccessory
{
  if (editorSetupHandler) {
    // return the editor
    return editorSetupHandler(self,aInAccessory);
  }
  return nil; // no editor
}


// called when editor (as obtained by editorForTapInAccessory:) has finished
- (void)editor:(UIViewController *)aEditorViewController finishedWithCancel:(BOOL)aCancelled
{
  // base class calls custom handler, if defined
  if (editorFinishedHandler) {
    editorFinishedHandler(self, aEditorViewController, aCancelled);
  }
}


- (BOOL)keepSelected
{
  return self.keepSelectedAfterTap;
}



#pragma mark - services for cell owners

@synthesize cellOwner;
@synthesize showInModes;

@synthesize cellVisibleInModeHandler;
@synthesize valueChangedHandler;
@synthesize tapHandler;
@synthesize editorSetupHandler;
@synthesize editorFinishedHandler;
@synthesize editingEndedHandler;
@synthesize validationStatusHandler;

@synthesize showsValidationStatus;

// standard callback from value connectors when the managed internal value (NOT the connected model/key) has changed
- (BOOL)valueChangedInConnector:(ZValueConnector *)aConnector
{
  BOOL handled = NO;
  if (active && valueChangedHandler) {
    handled = valueChangedHandler(self,aConnector);
  }
  return handled;
}


// standard callback from value connectors when the managed value's validation status changes
- (BOOL)validationStatusChangedInConnector:(ZValueConnector *)aConnector error:(NSError *)aError
{
  BOOL handled = NO;
  if (active && validationStatusHandler) {
    handled = validationStatusHandler(self,aConnector);
  }
  if (!handled && self.showsValidationStatus) {
    // possible standard handling in derived cells
    [self updateValidationStatusError:aError];
  }
  return handled;  
}


#pragma mark - services for myself and subclasses (methods that can be called by subclasses)


// will cause updateForDisplay to be called before cell is shown next time
- (void)setNeedsUpdate
{
  needsDisplayUpdate = YES;
}



// - flag need for reloading the table of which this cell is part of (e.g. due to cell height changes)
- (void)setNeedsTableReload
{
  if ([cellOwner respondsToSelector:@selector(setNeedsReloadingCell:animated:)]) {
    [cellOwner setNeedsReloadingCell:nil animated:NO];
  }
}


// - flag need for reloading this cell
- (void)setNeedsReloadAnimated:(BOOL)aAnimated
{
  if ([cellOwner respondsToSelector:@selector(setNeedsReloadingCell:animated:)]) {
    [cellOwner setNeedsReloadingCell:self animated:aAnimated];
  }
}


- (void)setNeedsTableRebuild
{
  if ([cellOwner respondsToSelector:@selector(setNeedsRebuilding)]) {
    [cellOwner setNeedsRebuilding];
  }
}



// must be called when cell detects itself that it was tapped
// Note: UITableViewCell/UITableView native setup is such that cell should not
//   act itself, but have tableView perform actions, so that's why we pass a
//   locally detected tap back for processing.
//   The cellOwner can then use handleTapInAccessory: in case the cell
//   must do something.
- (void)cellTappedInAccessory:(BOOL)aInAccessory
{
	if (cellOwner) {
  	if ([cellOwner respondsToSelector:@selector(cellTapped:inAccessory:)]) {
    	[cellOwner cellTapped:self inAccessory:aInAccessory];
    }
  }	
}



#pragma mark - subclass hooks (methods that can be overridden by subclasses)

@synthesize focusedEditing;


// called to have non-value display details being updated (like labels, placeholders etc.)
- (void)updateForDisplay
{
  if (
    autoSetDescriptionLabelText && // enabled
    (self.descriptionViewAdjustment & ZDetailCellItemAdjustHide)==0 // not explicitly hidden
  ) {
    // make sure description label text is set
    self.descriptionLabel.text = self.labelText;
  }
  // just cause relayout in base class, as label configuration might have changed
  [self setNeedsLayout];
}



// called when validation status changes (so subclasses can show/hide in-cell notices)
- (void)updateValidationStatusError:(NSError *)aError
{
  // Simple mechanism in base class: make label red when we have an error
  if (aError) {
    if (nonErrorTextColor==nil) nonErrorTextColor = self.descriptionLabel.textColor; // capture this
    if (nonErrorHighlightedTextColor==nil) nonErrorHighlightedTextColor = self.descriptionLabel.highlightedTextColor; // capture this
    self.descriptionLabel.textColor = [UIColor redColor];
    self.descriptionLabel.highlightedTextColor = [UIColor colorWithRed:1.000 green:0.289 blue:0.294 alpha:1.000]; // light red has better contrast
  }
  else {
    self.descriptionLabel.textColor = nonErrorTextColor;
    self.descriptionLabel.highlightedTextColor = nonErrorHighlightedTextColor;
  }
}



- (BOOL)presentingEmptyValue
{
  // in base class, all values are considered non-empty.
  // Subclasses should check their current value
  return NO;
}


- (void)changedEditingRect:(CGRect)aEditingRect
{
  // if cell is used in a tableView (it usually is), communicate start of editing
  // or change of size to allow tableview to scroll cell in view
  if ([cellOwner respondsToSelector:@selector(changedEditingRect:)]) {
    [cellOwner changedEditingRect:aEditingRect];
  }
}


// might be called by subclasses to signal start of in-cell editing (like focusing text field)
- (BOOL)startedEditing
{
  // communicate rectangle of cell being edited
  [self changedEditingRect:self.frame];
  // flag to prevent multiple editing end events
  focusedEditing = YES;
  // otherwise, this is not considered handling it finally.
  return NO; // not handled
}



// might be called by subclasses to signal end of in-cell editing (like defocusing text field)
- (BOOL)endedEditingWithGotoNext:(BOOL)aGotoNext;
{
  BOOL handled = NO;
  // prevent ending focused editing multiple times
  if (focusedEditing) {
    focusedEditing = NO; // not ending twice!
    // let app know editing has ended
    [self changedEditingRect:CGRectNull];
    // call handler if any
    if (self.editingEndedHandler) {
      handled = self.editingEndedHandler(self);
    }
    // also evaluate the gotoNext
    if (aGotoNext) {
      if ([cellOwner respondsToSelector:@selector(beginEditingInNextCellAfter:)]) {
        [cellOwner beginEditingInNextCellAfter:self];
      }
    }
  }
  return handled;
}


#pragma mark - common properties for cell appearance and behaviour control

@synthesize keepSelectedAfterTap;

@synthesize valueView, descriptionView;

@synthesize valueLabel, descriptionLabel;

- (UILabel *)valueLabel
{
  // return the explicitly set label if there is one
  if (valueLabel)
    return valueLabel;
  // by default, the value is in UITableViewCell's detailTextLabel
  // except for the single-label cell where it is an alias to the descriptionLabel (textLabel)
  return basicCellStyle==UITableViewCellStyleDefault ? self.textLabel : self.detailTextLabel;
}


- (UILabel *)descriptionLabel
{
  // return the explicitly set label if there is one
  if (descriptionLabel) return descriptionLabel;
  // The cell description is in UITableViewCell's textLabel
  // (For for single-label cell, the valueLabel is also an alias to this)
  return self.textLabel;
}



@synthesize valueCellShare;

- (void)setValueCellShare:(CGFloat)aValueCellShare
{
  if (aValueCellShare!=valueCellShare) {
    valueCellShare = aValueCellShare;
    [self setNeedsUpdate];
  }
}


@synthesize contentMargins;

- (void)setContentMargins:(CGSize)aContentMargins
{
  if (!CGSizeEqualToSize(aContentMargins,contentMargins)) {
    contentMargins = aContentMargins;
    [self setNeedsUpdate];
  }
}


@synthesize labelValueMargin;

- (void)setLabelValueMargin:(CGFloat)aLabelValueMargin
{
  if (aLabelValueMargin!=labelValueMargin) {
    labelValueMargin = aLabelValueMargin;
    [self setNeedsUpdate];
  }
}


@synthesize descriptionViewAdjustment;


- (ZDetailCellItemAdjust)descriptionViewAdjustment
{
  if ((descriptionViewAdjustment & ZDetailCellItemAdjustHMask)==0) {
    // no horizontal adjustment specified at all, derive from label's textalignment
    return
      descriptionViewAdjustment | ZDetailCellItemAdjustFillWidth |
      (self.descriptionLabel.textAlignment==NSTextAlignmentRight ? ZDetailCellItemAdjustRight : ZDetailCellItemAdjustLeft);
  }
  return descriptionViewAdjustment;
}


- (void)setDescriptionViewAdjustment:(ZDetailCellItemAdjust)aDescriptionViewAdjustment
{
  if (aDescriptionViewAdjustment!=descriptionViewAdjustment) {
    descriptionViewAdjustment = aDescriptionViewAdjustment;
    [self setNeedsUpdate];
  }
}


@synthesize valueViewAdjustment;

- (ZDetailCellItemAdjust)valueViewAdjustment
{
  if ((valueViewAdjustment & ZDetailCellItemAdjustHMask)==0) {
    // no horizontal adjustment specified at all, derive from label's textalignment
    return
      valueViewAdjustment | ZDetailCellItemAdjustFillWidth |
      (self.valueLabel.textAlignment==NSTextAlignmentRight ? ZDetailCellItemAdjustRight : ZDetailCellItemAdjustLeft);
  }
  return valueViewAdjustment;
}


- (void)setValueViewAdjustment:(ZDetailCellItemAdjust)aValueViewAdjustment
{
  if (aValueViewAdjustment!=valueViewAdjustment) {
    valueViewAdjustment = aValueViewAdjustment;
    [self setNeedsUpdate];
  }
}


@synthesize displayMode; // readonly - use ZDetailViewCell protocol's setDisplayMode:animated: to set


// returns YES if in-cell editing should be allowed now
- (BOOL)allowsEditing
{
  return !self.readOnly && (self.displayMode & ZDetailDisplayModeEditing);
}


//- (void)willTransitionToState:(UITableViewCellStateMask)aState
//{
//  [super willTransitionToState:aState];
//}
//
//
//- (void)didTransitionToState:(UITableViewCellStateMask)aState
//{
//  [super didTransitionToState:aState];
//}


@synthesize labelText;
@synthesize autoSetDescriptionLabelText;

- (NSString *)labelText
{
  // return specific text if any
  if (labelText) return labelText;
  // default to first non-empty keyPath in valueConnectors
  for (ZValueConnector *vc in self.valueConnectors) {
    if (vc.keyPath && vc.keyPath.length>0)
      return vc.keyPath;
  }
  // no label text found
  return @"???";
}

- (NSString *)specificLabelText
{
  return labelText;
}



@synthesize detailTitleText;

- (NSString *)detailTitleText
{
  // return specific text if any
  if (detailTitleText) return detailTitleText;
  // return sensible default instead
  return labelText;
}


@synthesize placeholderText;

- (NSString *)placeholderText
{
  // return specific text if any
  if (placeholderText) return placeholderText;
  // return sensible default instead
  return self.detailTitleText;
}


@synthesize readOnly;

- (void)setReadOnly:(BOOL)aReadOnly
{
  if (aReadOnly!=readOnly) {
    readOnly = aReadOnly;
    [self setNeedsUpdate];    
  }
}


@synthesize tapClaimsFocus;


@synthesize tableEditingStyle;


#pragma mark - Geometry and layout calculation

@synthesize standardCellHeight;


- (CGFloat)standardCellHeight
{
  if (standardCellHeight<=0) {
    // not set, try initializing with rowheight of owning tableview
    if (self.cellOwner && [self.cellOwner respondsToSelector:@selector(detailTableView)])
      standardCellHeight = self.cellOwner.detailTableView.rowHeight;
    else
      standardCellHeight = 44; // iOS default
  }
  return standardCellHeight;
}


- (CGFloat)cellHeight
{
  // in base class, just return standard height
  // (subclasses might return dynamically calculated heights)
  return standardCellHeight;
}


// helper function to apply layout rules
static CGRect adjustFrame(CGRect f, ZDetailCellItemAdjust adjust, CGRect r)
{
  // Horizontally
  // - width
  if (adjust & ZDetailCellItemAdjustFillWidth) {
    f.size.width = r.size.width; // set width
    f.origin.x = r.origin.x; // and origin
  }
  // - X position
  if (adjust & ZDetailCellItemAdjustLeft)
    f.origin.x = r.origin.x; // left adjusted
  else if (adjust & ZDetailCellItemAdjustRight)
    f.origin.x = r.origin.x+r.size.width-f.size.width; // right adjusted
  // Vertically
  // - height
  if (adjust & ZDetailCellItemAdjustFillHeight) {
    f.size.height = r.size.height; // set height
    f.origin.y = r.origin.y; // and origin
  }
  // - Y position
  if (adjust & ZDetailCellItemAdjustTop)
    f.origin.y = r.origin.y; // top
  else if (adjust & ZDetailCellItemAdjustBottom)
    f.origin.y = r.origin.y+r.size.height-f.size.height; // bottom
  else if (adjust & ZDetailCellItemAdjustMiddle)
    f.origin.y = r.origin.y+round((r.size.height-f.size.height)/2);
  // return result
  return f;
}


- (UIImageView *)imageView
{
  // mark image view in use
  imageViewInUse = YES;
  return super.imageView;
}



- (void)layoutSubviews
{
  [super layoutSubviews];
  // automatic layout mechanism for valueView and descriptionView
  // Note:
  // - the ZDetailViewCellStyleFlagCustomLayout flag is not checked here, because it already decides
  //   if the standard UITableViewCell labels are assigned to valueView and descriptionView or not.
  // - even without ZDetailViewCellStyleFlagCustomLayout, autoLayout is active for views
  //   programmatically assigned to valueView and descriptionView.
  #if LAYOUT_DEBUG
  // color views for debugging
  self.contentView.backgroundColor = [UIColor colorWithRed:0.847 green:1.000 blue:0.738 alpha:0.7];
  if (self.descriptionView && !self.descriptionView.hidden) {
    self.descriptionView.backgroundColor = [UIColor colorWithRed:0.730 green:0.934 blue:1.000 alpha:0.7]; 
  }
  if (self.valueView && !self.valueView.hidden) {
    self.valueView.backgroundColor = [UIColor colorWithRed:1.000 green:0.783 blue:0.772 alpha:0.7]; 
  }
  #endif
  // perform custom layout
  UIView *bv = self.backgroundView;
  UIView *cv = self.contentView;
  // try to measure standard geometry
  // Note: differences here between iPhone and iPad - don't try to measure before BOTH cv and bv are ready!
  if (cv && bv && !self.editing && contentLeftMargin<0) {
    // - content view
    contentLeftMargin = cv.frame.origin.x;
    contentRightMargin = cv.superview.bounds.size.width - contentLeftMargin - cv.frame.size.width;
    // - background view
    backgroundLeftMargin = bv.frame.origin.x;
    backgroundRightMargin = bv.superview.bounds.size.width - contentLeftMargin - bv.frame.size.width;
  }
  // do not try to layout anything before we have the content view
  if (cv!=nil) {
    // assume both shown, if geometry demands, one or the other will be hidden below
    BOOL valueShown = (self.valueViewAdjustment & ZDetailCellItemAdjustHide)==0;
    BOOL descriptionShown = (self.descriptionViewAdjustment & ZDetailCellItemAdjustHide)==0;
    // configure geometry
    CGFloat cellWidth = self.bounds.size.width;
    // determine start of X coordinate of value part:
    // valueCellShare positive means relative to cellwidth, negative means relative to contentView width
    CGFloat valueStartXinContent;
    if (self.valueCellShare<0) {
      // relative to content view with (which might be indented)
      valueStartXinContent = fabs(self.valueCellShare)*cv.bounds.size.width;
    }
    else {
      // relative to entire cell width (does not move when cell morphs between modes)
      CGFloat valuePartStart = round((1-self.valueCellShare)*cellWidth); // position in cell coords
      // now find out where this line is in the current contentview
      valueStartXinContent = [self convertPoint:CGPointMake(valuePartStart, 0) toView:cv].x;
    }
    // - make adjustments when it is outside the content view
    CGFloat contentStartX = self.contentMargins.width;
    if (imageViewInUse) {
      // take image into account
      CGRect imgf = self.imageView.frame;
      contentStartX += imgf.origin.x+imgf.size.width;
    }
    CGFloat contentWidth = cv.bounds.size.width-contentStartX-self.contentMargins.width;
    CGFloat descriptionEndInContentX = valueStartXinContent-self.labelValueMargin;
    if (descriptionEndInContentX<=contentStartX) {
      // description has no room, disable it 
      descriptionShown = NO; // no room for any description, hide it
      if (valueStartXinContent<=contentStartX) {
        // also value would start left of content start, adjust
        valueStartXinContent = contentStartX; // start of value not outside content margin
      }
    }
    else if (valueStartXinContent>=contentStartX+contentWidth) {
      // no room for value, only description
      valueShown = NO;
      descriptionEndInContentX = contentStartX+contentWidth;
    }
    // Now we have the two areas for description and value
    CGRect df = self.descriptionView.frame;
    CGRect vf = self.valueView.frame;
    // - apply the layout where appropriate
    if (self.descriptionView && descriptionShown) {
      df = adjustFrame(
        df,
        self.descriptionViewAdjustment,
        CGRectMake(
          contentStartX, self.contentMargins.height,
          descriptionEndInContentX-contentStartX, cv.bounds.size.height-2*self.contentMargins.height
        )
      );
    }
    if (self.valueView && valueShown) {
      vf = adjustFrame(
        vf,
        self.valueViewAdjustment,
        CGRectMake(
          valueStartXinContent, self.contentMargins.height,
          contentStartX+contentWidth-valueStartXinContent, cv.bounds.size.height-2*self.contentMargins.height
        )
      );
    }
    // extend views in case other view does not use its full size (only if both shown at all)
    CGFloat room = 0;
    // - possibly extend description
    if (valueShown)
      room = vf.origin.x-valueStartXinContent; // use what is not used by value
    else
      room = contentStartX+contentWidth-valueStartXinContent; // use entire space
    if (descriptionShown && room>0 && (self.descriptionViewAdjustment & ZDetailCellItemAdjustExtend)) {
      df.size.width += room; // extend by what value does not use
    }
    // - possibly extend value
    if (descriptionShown)
      room = valueStartXinContent - (df.origin.x+df.size.width+self.labelValueMargin); // use what is not used by description
    else
      room = valueStartXinContent-contentStartX; // use entire space
    if (valueShown && room>0 && (self.valueViewAdjustment & ZDetailCellItemAdjustExtend)) {
      vf.origin.x -= room; // move left by what description does not use 
      vf.size.width += room; // extend by what description does not use 
    }
    // reduce value view when custom accessory is set
    if (self.accessoryView) {
      vf.size.width -= self.accessoryView.frame.size.width+2; // minimal margin
    }
    // assign hidden and frames
    BOOL canHide = self.descriptionView!=self.valueView;
    if (self.valueView) {
      self.valueView.hidden = !valueShown && canHide;
      if (valueShown) self.valueView.frame = vf;
    }
    if (self.descriptionView) {
      self.descriptionView.hidden = !descriptionShown && canHide;
      if (descriptionShown) self.descriptionView.frame = df;
    }
  }
}


@end
