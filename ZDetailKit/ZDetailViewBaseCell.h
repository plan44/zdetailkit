//
//  ZDetailViewBaseCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 17.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZValueConnector.h"
#import "ZDetailEditing.h"

#import "ZTextExpanderSupport.h"
#import "ZString_utils.h"

// set 1 to color views touched by custom layout for debugging
#define LAYOUT_DEBUG 0


// handler for changed value
// - can return YES to signal situation fully handled (suppresses default action, if any)
// - if no handler is set, processing continues as if the handler had returned NO
typedef BOOL (^ZDetailCellConnectionHandler)(ZDetailViewBaseCell *aCell, ZValueConnector *aConnector);
// handler for when detail editor for this cell has finished (was closed)
typedef BOOL (^ZDetailCellEditorFinishedHandler)(ZDetailViewBaseCell *aCell, BOOL aCancelled);
// handler for tap in cell or cell accessory
typedef BOOL (^ZDetailCellTapHandler)(ZDetailViewBaseCell *aCell, BOOL aInAccessory);
// handler for creating editor
typedef UIViewController *(^ZDetailCellEditorSetupHandler)(ZDetailViewBaseCell *aCell, BOOL aInAccessory);
// handler for checking if cell should be visible in a particular mode
typedef BOOL (^ZDetailCellVisibleInModeHandler)(ZDetailViewBaseCell *aCell, ZDetailDisplayMode aMode);
// handler for custom end-of-editing behaviour
typedef BOOL (^ZDetailCellEditingEndedHandler)(ZDetailViewBaseCell *aCell);

// Bitmasks to set label adjustments in descriptionViewAdjustment and valueViewAdjustment
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
  ZDetailCellItemAdjustExtend = 0x100,
  ZDetailCellItemAdjustHide = 0x200
} ZDetailCellItemAdjust;


/// Base cell for use in ZDetailTableViewController
///
/// ZDetailViewBaseCell can be initialized and used like a regular UITableViewCell.
/// It provides extensions over UITableViewCell in three main regards
///
/// - the style parameter passed in initWithStyle:reuseIdentifier:
///   can contain additional flags (see ZDetailViewCellStyleXXXX definitions) to enable many extra
///   automatic layout features for managing the description and value texts (for both cases when
///   using the UITableViewCell built-in UILabels and also when using other UIView or UIControls).
/// - ZDetailViewBaseCell is designed to interface in various ways with ZDetailTableViewController, by passing
///   events, allowing cells to show/hide based on contents, provide view controllers (editors) for editing
///   a cell's content and much more.
/// - Support for embedded ZValueConnector objects to dynamically bind cell contents to model attributes,
///   including save/cancel functionality, validation, value conversion and text formatting.
///
/// ZDetailViewBaseCell's behaviour can be customized in many ways by assigning handler blocks for various events.
@interface ZDetailViewBaseCell : UITableViewCell <ZDetailViewCell, ZValueConnectorOwner, ZValueConnectorContainer>

/// @name Initializing a cell

/// Initialize the cell
/// @param aStyle the UITableViewCell style plus optional ZDetailViewCellStyleXXX flags
/// @param aReuseIdentifier reuse identifier, see UITableViewCell
/// @note this method has the standard UITableViewCell compatible signature, except that style has extended functionality (includes flags).
/// This simplifies porting existing UITableViewCell subclasses to become ZDetailViewBaseCell subclasses.
- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier;


/// reference to the owning object.
///
/// Usually this is a ZDetailTableViewController, but
/// any other object implemenbe ting the ZDetailCellOwner protocol can be the owner
/// @note this property will automatically set when a cell is added using
/// one of the [ZDetailTableViewController detailCell:] factory method variants
@property (unsafe_unretained, nonatomic) id<ZDetailCellOwner> cellOwner;


/// @name Cell style

/// the ZDetailViewCellStyle as passed at initWithStyle:reuseIdentifier:
/// @note This is a combination of UITableViewCell styles enhanced with ZDetailViewCellStyleXXX flags for additional styling options
@property (readonly, nonatomic) ZDetailViewCellStyle detailViewCellStyle;
/// the pure UITableViewCellStyle as passed at initWithStyle:reuseIdentifier: (ZDetailViewCellStyleXXX flags masked out)
@property (readonly, nonatomic) UITableViewCellStyle basicCellStyle;


/// display mode flags describing in which modes (display, details, editing) and states
/// (non-empty value) this cell will be made visible (ORed flags)
@property (assign, nonatomic) ZDetailDisplayMode showInModes;

/// @name Cell geometry and layout

/// standard cell height (defaults to table's rowHeight)
@property (assign, nonatomic) CGFloat standardCellHeight;

/// actual cell height, equal to standardCellHeight in base class, can vary for subclasses which dynamically resize cells
@property (readonly, nonatomic) CGFloat cellHeight;

/// share of the entire cell that is used to represent value in
///
/// - positive values describe the share relative to the entire cell width (=table view width)
/// - negative values describe the share relative to the content view width (which might be indented, see contentIndent)
///
/// @note valueCellShare applies only to valueView and descriptionView (which are only assigned to the standard UITableViewCell
///   labels when ZDetailViewCellStyleFlagAutoLabelLayout flag is set in the cell style)
/// @note The default of this is dependent on the cell style set when creating the cell.
///   UITableViewCellStyleDefault have a valueCellShare of 1.0 (no description label), other styles
///   usually have something between 0.4 (prefs) and 0.65 (addressbook style).
/// @note to automatically set valueCellShare for all cells to the same value, use ZDetailTableViewController's
///   defaultValueCellShare property.
@property (assign, nonatomic) CGFloat valueCellShare;

/// content view indent (enlarged left margin) in pixels
/// @warning content indent does not look ok with UITableViewCellSeparatorStyleSingleLineEtched
@property (assign, nonatomic) CGFloat contentIndent;

/// content margins (free pixels to the left and right or top and bottom of actual cell content)
@property (assign, nonatomic) CGSize contentMargins;

/// margin between description and value labels
@property (assign, nonatomic) CGFloat labelValueMargin;

/// defines how the description view is placed and resized
@property (assign, nonatomic) ZDetailCellItemAdjust descriptionViewAdjustment;

/// defines how the value view is placed and resized
@property (assign, nonatomic) ZDetailCellItemAdjust valueViewAdjustment;


/// @name Description and value representation

/// alias for the accessing the label which represents the value text.
///
/// defaults to either detailTextLabel or textLabel of standard UITableViewCell, but can be assigned any other (also custom) UILabel
@property (strong, nonatomic) UILabel *valueLabel;
/// alias for the accessing the label which represents the description text.
///
/// defaults to either textLabel or detailTextLabel of standard UITableViewCell, but can be assigned any other (also custom) UILabel
@property (strong, nonatomic) UILabel *descriptionLabel;

/// This is the view which represents the value
///
/// Usually, this is one of the standard UITableViewCell labels, but can be set to any other view
/// (for example a UISwitch or UISlider).
/// The custom layout mechanism of ZDetailViewCell will place and resize the view assigned here according to
/// valueViewAdjustment, valueCellShare and chosen cell style.
/// @note the standard UITableViewCell UILabel is only automatically assigend to valueView (and thus put under layout control)
/// when ZDetailViewCellStyleFlagAutoLabelLayout flag is set in the cell style.
@property (strong, nonatomic) UIView *valueView;
/// This is the view which represents the description
///
/// Usually, this is one of the standard UITableViewCell labels
/// The custom layout mechanism of ZDetailViewCell will place and resize the view assigned here according to
/// descriptionViewAdjustment, valueCellShare and chosen cell style.
/// @note the standard UITableViewCell UILabel is only automatically assigend to descriptionView (and thus put under layout control)
/// when ZDetailViewCellStyleFlagAutoLabelLayout flag is set in the cell style.
@property (strong, nonatomic) UIView *descriptionView;


/// @name Customizing behaviour using blocks

/// block controlling visibility of the cell
///
/// This block, when assiged, is called to make a decision if the cell should be visible or not for the passed ZDetailDisplayMode.
/// The block must return YES if the cell should be visible, NO otherwise
/// If no block is assigned, the cell is visible when the current mode satisfies showInModes
@property (copy, nonatomic) ZDetailCellVisibleInModeHandler cellVisibleInModeHandler;
- (void)setCellVisibleInModeHandler:(ZDetailCellVisibleInModeHandler)cellVisibleInModeHandler; // declaration needed only for XCode autocompletion of block

/// block to respond to value changes (user edits)
///
/// This block, when assigned, is called after the value of the cell has changed (but not necessarily already written back to the connected model value).
/// This is the place to implement showing/hiding other cells depending on this cell's value, e.g. by
/// using [ZDetailTableViewController changeGroups:toVisible:]
/// @note Do not use this method to save values into your model - use the cocoa-bindings like mechanisms
/// provided by ZValueConnector instead
@property (copy, nonatomic) ZDetailCellConnectionHandler valueChangedHandler;
- (void)setValueChangedHandler:(ZDetailCellConnectionHandler)valueChangedHandler; // declaration needed only for XCode autocompletion of block

/// block to respond to the cell being tapped
///
/// This block, when assigned, is called when the cell is tapped. This is useful for implementing buttons
/// or drill down submenus by pushing another ZDetailTableViewController onto the navigation stack.
/// This block should return YES if it can fully handle the tap. If it returns NO, the cell might
/// perform standard actions (like opening a separate editor view for the value, for example)
@property (copy, nonatomic) ZDetailCellTapHandler tapHandler;
- (void)setTapHandler:(ZDetailCellTapHandler)tapHandler; // declaration needed only for XCode autocompletion of block

/// block called to return a value editor (separate view that opens to edit the value)
///
/// This block, when assigned, is called when a cell would like to open a value editor
/// @note unlike tapHandler, this handler should be used when the action of tapping a cell (or accessory)
///   should be pushing a detail editor for the cell's value (or set of values represented by the cell).
///   tapHandler is for more generic actions, which are not exactly opening a detail editor.
@property (copy, nonatomic) ZDetailCellEditorSetupHandler editorSetupHandler;
- (void)setEditorSetupHandler:(ZDetailCellEditorSetupHandler)editorSetupHandler; // declaration needed only for XCode autocompletion of block

/// block to respond to a value editor (separate view that opened to edit the value) being closed.
///
/// This block, when assigned, is called when a cell's value editor (separate view on top of the navigation stack)
/// has been closed.
/// The aCancelled block parameter is set to YES to when the edits made in the value editor were discarded.
@property (copy, nonatomic) ZDetailCellEditorFinishedHandler editorFinishedHandler;
- (void)setEditorFinishedHandler:(ZDetailCellEditorFinishedHandler)editorFinishedHandler; // declaration needed only for XCode autocompletion of block

/// block to respond to the end of a value being edited in-place
///
/// This block, when assigned, is called when editing of a cell's value in-place has ended (usually by moving the focus to another cell, or closing the entire detailView)  
@property (copy, nonatomic) ZDetailCellEditingEndedHandler editingEndedHandler;
- (void)setEditingEndedHandler:(ZDetailCellEditingEndedHandler)editingEndedHandler; // declaration needed only for XCode autocompletion of block

/// block to respond to a change of the cell's value's validation status.
///
/// This block is called when the validation status for any values represented by the cell has changed
/// from valid to invalid or vice versa.
/// This block can return YES to indicated that the status change has been fully handled; if it
/// returns NO, the standard validation status handling of the cell will be executed (standard
/// behaviour of ZDetailViewBaseCell is setting the color of the description label text to red).
@property (copy, nonatomic) ZDetailCellConnectionHandler validationStatusHandler;
- (void)setValidationStatusHandler:(ZDetailCellConnectionHandler)validationStatusHandler; // declaration needed only for XCode autocompletion of block

/// @name Customizing look and behaviour

/// text for description label - defaults to keyPath of first valueConnector
@property (strong, nonatomic) NSString *labelText;

/// returns text specifically set as labelText (is nil if label is autocalculated)
@property (weak, readonly, nonatomic) NSString *specificLabelText;

/// text for detail editor - defaults to labelText
@property (strong, nonatomic) NSString *detailTitleText;

/// text for placeholder in editing fields - defaults to detailTitleText
@property (strong, nonatomic) NSString *placeholderText;

/// if set to YES, cell selection remains set after tapping cell, otherwise releasing the touch will also remove the selection
@property (assign, nonatomic) BOOL keepSelectedAfterTap;

/// if not set, description label will not be automatically calculate
@property (assign, nonatomic) BOOL autoSetDescriptionLabelText;

/// if set, the cell's value is considered read-only, and cannot be edited. Depending on the actual cell, controls might get grayed out.
@property (assign, nonatomic) BOOL readOnly;

/// if set, cell will show validation status as it changes (unless overridden by validationStatusHandler)
@property (assign, nonatomic) BOOL showsValidationStatus;

/// if set (default), tapping cell will claim focus
/// (i.e. defocus other cells, which will make input views like keyboard to disappear)
@property (assign, nonatomic) BOOL tapClaimsFocus;


/// @name Cell status

/// the current display mode of the cell.
///
/// The mode determines if only viewing or editing values, and if detail properties are to be shown. Depending on
/// showInModes, the cell might become invisible in some modes.
/// @note the display mode is usually changed by ZDetailTableViewController calling setDisplayMode:animated:
/// and should not normally be set directly.
@property (readonly, nonatomic) ZDetailDisplayMode displayMode;

/// returns YES if cell currently allows editing its value (derived from readOnly setting and displayMode/showInModes)
@property (readonly, nonatomic) BOOL allowsEditing;

/// returns YES if cell currently has editing focus (like active cursor in a text field)
@property (readonly, nonatomic) BOOL focusedEditing;

/// set if cell is active (i.e. potentially connected to data and editing or displaying it)
/// @note this property is usually controlled by ZDetailTableViewController and should
/// normally not be modified directly
@property (assign, nonatomic) BOOL active;


/// @name Methods for receiving events from embedded ZValueConnector instances

/// the value of aConnector has changed
- (BOOL)valueChangedInConnector:(ZValueConnector *)aConnector;

/// the validation status of aConnector has changed
- (BOOL)validationStatusChangedInConnector:(ZValueConnector *)aConnector error:(NSError *)aError; // validation status has changed


/// @name Methods intended to be derived by subclasses

/// called when prepareForDisplay is called and needsUpdate is set
///
/// This is the place to implement everything which needs to be done before the subviews of the cell and the cell itself are redisplayed
- (void)updateForDisplay;

/// called when validation status changes (so subclasses can show/hide in-cell notices)
/// @note base class' default implementation is setting the descriptionLabel's text color to red when there is a validation error
- (void)updateValidationStatusError:(NSError *)aError;

/// should return true when cell is presenting an empty value (according to cell's own semantics),
/// such that empty cells can be automatically hidden when using a ZDetailDisplayModeXXXXXNonEmpty flag in showInModes
- (BOOL)presentingEmptyValue;

/// might be called by subclasses to signal start of in-cell editing (like focusing a text field)
- (BOOL)startedEditing;

/// might be called by subclasses to signal end of in-cell editing (like defocusing text field)
/// @param aGotoNext if set, the owner will try to move the focus to the next cell which can take a focus
- (BOOL)endedEditingWithGotoNext:(BOOL)aGotoNext;

/// Internal initialisation
///
/// This method is called by the public initXXX method(s).
/// Subclasses which don't need their own initXXX method(s) but just need to initialize some internals
/// can override this single method.
- (void)internalInit;


/// @name Services for subclasses (DO NOT OVERRIDE!)

/// call when updating visual representation (calling updateForDisplay) is needed
- (void)setNeedsUpdate;

/// call when reloading the table of which this cell is part of (e.g. due to cell height changes) is needed
- (void)setNeedsTableReload;

/// call when reloading this cell (re-fetching data from connected model) is needed
- (void)setNeedsReloadAnimated:(BOOL)aAnimated;

/// should be called to communicate that the editing rectangle has changed (such as for live resizing textView)
/// ZDetailTableViewController uses this information to scroll edited cells such that they are not obscured by
/// the keyboard or other input views.
/// @param aEditingRect rectangle in table view coords where editing occurs
- (void)changedEditingRect:(CGRect)aEditingRect;


@end
