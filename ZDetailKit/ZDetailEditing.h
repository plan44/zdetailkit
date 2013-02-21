//
//  ZDetailEditing.h
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

// Cell Style (UITableViewCell styles enhanced with some flags)
typedef int ZDetailViewCellStyle;

// mask for separating basic UITableViewStyle from our option flags
#define ZDetailViewCellStyleBasicStyleMask 0x0FFF

// option flags
#define ZDetailViewCellStyleFlagCustomLayout 0x1000 // use ZDetailViewBaseCells custom layout mechanism for description and value views
#define ZDetailViewCellStyleFlagAutoStyle 0x2000 // allow cells to decide about matching style (most don't but some might)
#define ZDetailViewCellStyleFlagInherit 0x4000 // (only for defaultCellStyle in ZDetailTableViewController) inherit style from parent controller, if any

// predefined styles
#define ZDetailViewCellStyleEntryDetail (UITableViewCellStyleValue2+ZDetailViewCellStyleFlagCustomLayout+ZDetailViewCellStyleFlagAutoStyle)
#define ZDetailViewCellStylePrefs (UITableViewCellStyleValue1+ZDetailViewCellStyleFlagCustomLayout+ZDetailViewCellStyleFlagAutoStyle)

// the default style to be used in ZDetailTableViewControllers
#define ZDetailViewCellStyleDefault ZDetailViewCellStylePrefs+ZDetailViewCellStyleFlagAutoStyle // allow some cells to decide about their style


// localisation with hard-coded default value
#define ZLocalizedStringWithDefault(key, default) \
  [[NSBundle mainBundle] localizedStringForKey:(key) value:default table:nil]


/// display modes (visibility flags)
typedef enum {
  ZDetailDisplayModeNone = 0,
  ZDetailDisplayModeBasics = 0x01, // basic selection of properties
  ZDetailDisplayModeDetails = 0x02, // detailed selection of properties 
  ZDetailDisplayModeViewing = 0x04, // viewing
  ZDetailDisplayModeEditing = 0x08,  // editing cell contents (NOT UITableView editing mode!)
  // special flags
  ZDetailDisplayModeBasicsNonEmpty = 0x100,  // in neededModes: view only if not empty in basics mode
  ZDetailDisplayModeDetailsNonEmpty = 0x200,  // in neededModes: view only if not empty in detail mode
  ZDetailDisplayModeEditingNonEmpty = 0x400,  // in neededModes: view only if not empty in editing mode
} ZDetailDisplayMode;


@class ZDetailTableViewController;
@class ZDetailViewBaseCell;
@protocol ZDetailViewCell;
@protocol ZValueConnectorContainer;

// an object than can act as the parent of a detail view controller
@protocol ZDetailViewParent <NSObject>
- (void)childDetailEditingDoneWithCancel:(BOOL)aCancelled; // should be called by child detail editor when editing completes
@end


// an object than can act as a detail view controller
@protocol ZDetailViewController <NSObject>
/// will be called to establish link between master and detail
- (void)becomesDetailViewOfCell:(id<ZDetailViewCell>)aCell inController:(id<ZDetailViewParent>)aController;
/// returns parent (master) detail view controller
- (id<ZDetailViewParent>)parentDetailViewController;
@end


/// this protocol is for owners of ZDetailViewCell conformant table cells
@protocol ZDetailCellOwner <NSObject>
@optional
/// returns the tableview which displays the cell
- (UITableView *)detailTableView;
/// Called by cells when they themselves detect being tapped
- (void)cellTapped:(UITableViewCell *)aCell inAccessory:(BOOL)aInAccessory;
/// needed by some editor cells to block scrolling during certain periods as otherwise
/// touch tracking does not work
- (void)tempBlockScrolling:(BOOL)aBlockScrolling;
/// ask owner to refresh single cell (can be animated) or entire table (aCell=nil, not animated)
- (void)setNeedsReloadingCell:(UITableViewCell *)aCell animated:(BOOL)aAnimated;
/// start editing in next cell (pass nil to start editing in first cell that can edit)
- (void)beginEditingInNextCellAfter:(UITableViewCell *)aCell;
@end




/// this protocol is for UITableViewCells that want to be used fully featured in ZDetailTableViewControllers.
/// @note regular UITableViewCells (like pure info cells or controls with directly wired targets) can be used
/// as well, but don't get any editing support.
@protocol ZDetailViewCell <NSObject, ZValueConnectorContainer>
/// reference to the owning object.
///
/// Usually this is a ZDetailTableViewController, but
/// any other object implemenbe ting the ZDetailCellOwner protocol can be the owner
/// @note this property will automatically set when a cell is added using
/// one of the [ZDetailTableViewController detailCell:] factory method variants
@property (assign, nonatomic) id<ZDetailCellOwner> cellOwner;
/// set if cell is active (i.e. potentially connected to data and editing or displaying it)
/// @note this property is usually controlled by ZDetailTableViewController and should
/// normally not be modified directly
@property (assign, nonatomic) BOOL active; // cells should access data only when active
/// if set (default), tapping cell will claim focus
/// (i.e. defocus other cells, which will make input views like keyboard to disappear)
@property (assign, nonatomic) BOOL tapClaimsFocus;
/// editing style for native UITableView edit mode (delete/add/none)
@property (assign, nonatomic) UITableViewCellEditingStyle tableEditingStyle;


/// visibility check (to determine if cell should be visible in a particulat mode)
- (BOOL)nowVisibleInMode:(ZDetailDisplayMode)aMode; // true if cell should be visible in the passed mode

// appearance
- (void)prepareForDisplay; // - prepare for (re)display
- (void)defocusCell; // called to defocus cell (and contained controls)
- (BOOL)beginEditing; // called to try to begin editing (e.g. getting kbd focus) in this cell. Returns YES if possible (or already editing)
- (void)setDisplayMode:(ZDetailDisplayMode)aMode animated:(BOOL)aAnimated; // set cell presentation mode
// user interaction
- (BOOL)handleTapInAccessory:(BOOL)aInAccessory; // called to handle a tap in the cell (instead of in the cellOwner), return YES if handled
- (UIViewController *)editorForTapInAccessory:(BOOL)aInAccessory;
- (void)editorFinishedWithCancel:(BOOL)aCancelled; // called when detail editor for a cell (as obtained by editorForTapInAccessory:) has finished (i.e. closed)
- (BOOL)keepSelected; // if cell is selected (tapped) and this returns YES, the selection is kept after touch is released

@end
