//
//  ZDetailViewBaseCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 17.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZDetailValueConnector.h"
#import "ZDetailEditing.h"

#import "ZTextExpanderSupport.h"
#import "ZString_utils.h"

// set 1 to color views touched by custom layout for debugging
#define LAYOUT_DEBUG 0


// handler for changed value
// - can return YES to signal situation fully handled (suppresses default action, if any)
// - if no handler is set, processing continues as if the handler had returned NO
typedef BOOL (^ZDetailCellConnectionHandler)(ZDetailViewBaseCell *aCell, ZDetailValueConnector *aConnector);
// handler for when detail editor for this cell has finished (was closed)
typedef BOOL (^ZDetailCellEditorFinishedHandler)(ZDetailViewBaseCell *aCell, BOOL aCancelled);
// handler for tap in cell or cell accessory
typedef BOOL (^ZDetailCellTapHandler)(ZDetailViewBaseCell *aCell, BOOL aInAccessory);
// handler for checking if cell should be visible in a particular mode
typedef BOOL (^ZDetailCellVisibleInModeHandler)(ZDetailViewBaseCell *aCell, ZDetailDisplayMode aMode);
// handler for custom end-of-editing behaviour
typedef BOOL (^ZDetailCellEditingEndedHandler)(ZDetailViewBaseCell *aCell);

typedef enum {
  ZDetailCellItemAdjustNone = 0,
  ZDetailCellItemAdjustLeft = 0x01,
  ZDetailCellItemAdjustRight = 0x02,
  ZDetailCellItemAdjustFillWidth = 0x08,
  ZDetailCellItemAdjustHMask = 0x0F,
  ZDetailCellItemAdjustTop = 0x10,
  ZDetailCellItemAdjustBottom = 0x20,
  ZDetailCellItemAdjustMiddle = 0x40,
  ZDetailCellItemAdjustFillHeight = 0x80,
  ZDetailCellItemAdjustVMask = 0xF0,
  ZDetailCellItemAdjustExtend = 0x100
} ZDetailCellItemAdjust;


@interface ZDetailViewBaseCell : UITableViewCell <ZDetailViewCell, ZDetailValueConnectorOwner>

// declaration for ZDetailViewCell protocol
@property (assign, nonatomic) id<ZDetailCellOwner> cellOwner;
@property (assign, nonatomic) BOOL active;


// the style as passed when initialized
@property (readonly, nonatomic) ZDetailViewCellStyle detailViewCellStyle;
@property (readonly, nonatomic) UITableViewCellStyle basicCellStyle;
// aliases for the labels, default to UITableViewCell labels, but can be set to other labels
@property (retain, nonatomic) UILabel *valueLabel;
@property (retain, nonatomic) UILabel *descriptionLabel;


// visibility depending on tableController's editing mode
@property (assign, nonatomic) ZDetailDisplayMode neededModes;

// geometry info
@property (assign, nonatomic) CGFloat standardCellHeight; // standard cell height (subclasses might implement dynamic resizing, so actual cellHeight might be different)
@property (readonly, nonatomic) CGFloat cellHeight; // cell height, equal to standardCellHeight in base class, can vary for subclasses which dynamically resize cells
@property (assign, nonatomic) CGFloat valueCellShare; // share of the entire cell that is used to represent value in (0..1)
@property (assign, nonatomic) CGFloat contentIndent; // content indent in pixels
@property (assign, nonatomic) CGSize contentMargins; // content margins
@property (assign, nonatomic) CGFloat labelValueMargin; // margin between deacription and value
@property (retain, nonatomic) UIView *valueView; // for custom layout: must contain the view that shows the value 
@property (retain, nonatomic) UIView *descriptionView; // for custom layout: must contain the view that shows the description
@property (assign, nonatomic) ZDetailCellItemAdjust descriptionViewAdjustment; // for custom layout: how to adjust description view
@property (assign, nonatomic) ZDetailCellItemAdjust valueViewAdjustment; // for custom layout: how to adjust value view

// handlers for customizing behaviour
@property (copy, nonatomic) ZDetailCellVisibleInModeHandler cellVisibleInModeHandler;
@property (copy, nonatomic) ZDetailCellConnectionHandler valueChangedHandler;
@property (copy, nonatomic) ZDetailCellTapHandler tapHandler;
@property (copy, nonatomic) ZDetailCellEditorFinishedHandler editorFinishedHandler;
@property (copy, nonatomic) ZDetailCellEditingEndedHandler editingEndedHandler;
@property (copy, nonatomic) ZDetailCellConnectionHandler validationStatusHandler;

// customizing look and behaviour
@property (retain, nonatomic) NSString *labelText; // text for description label - defaults to keyPath of first valueConnector
@property (readonly, nonatomic) NSString *specificLabelText; // returns text specifically set as labelText (is nil if label is autocalculated)
@property (retain, nonatomic) NSString *detailTitleText; // text for detail editor - defaults to labelText
@property (retain, nonatomic) NSString *placeholderText; // text for placeholder in editing fields - defaults to detailTitleText
@property (assign, nonatomic) BOOL keepSelectedAfterTap; // keep selected after tapping cell
@property (assign, nonatomic) BOOL autoSetDescriptionLabelText; // if not set, description label will not be touched
@property (assign, nonatomic) BOOL readOnly;
@property (assign, nonatomic) BOOL alwaysEditable;
@property (assign, nonatomic) BOOL editorEnabled;
@property (assign, nonatomic) BOOL showsValidationStatus; // if set, cell will show validation status as it changes
@property (readonly, nonatomic) ZDetailDisplayMode displayMode;
@property (readonly, nonatomic) BOOL allowsEditing;
@property (readonly, nonatomic) BOOL focusedEditing;

// Methods for owner
// - UITableViewCell compatible, except that style has extended functionality (includes flags)
- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier;

// Interaction with value connectors
// - standard callbacks from value connectors
- (BOOL)valueChangedInConnector:(ZDetailValueConnector *)aConnector; // a value in a connector has changed
- (BOOL)validationStatusChangedInConnector:(ZDetailValueConnector *)aConnector error:(NSError *)aError; // validation status has changed

// methods intended to be derived by subclasses
- (void)updateForDisplay; // called when prepareForDisplay is called and needsUpdate is set
- (void)updateValidationStatusError:(NSError *)aError; // called when validation status changes (so subclasses can show/hide in-cell notices)
- (BOOL)presentingEmptyValue; // should return true when cell is presenting an empty value (such that empty cells can be hidden in some modes)

// might be called to communicate that the editing rectangle has changed (such as for live resizing textView)
- (void)cellEditingRectChanged; 
// might be called by subclasses to signal start/end of in-cell editing (like focusing/defocusing text field)
- (BOOL)startedEditing;
- (BOOL)endedEditingWithGotoNext:(BOOL)aGotoNext;

// Services for subclasses (DO NOT DERIVE)
// - flag need for updating visual representation (calling updateForDisplay)
- (void)setNeedsUpdate;
// - flag need for reloading the table of which this cell is part of (e.g. due to cell height changes)
- (void)setNeedsTableReload;
// - flag need for reloading this cell
- (void)setNeedsReloadAnimated:(BOOL)aAnimated;
// - register connectors (usually in the subclass' internalInit)
- (ZDetailValueConnector *)registerConnector:(ZDetailValueConnector *)aConnector;



@end
