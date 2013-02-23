//
//  ZDetailTableViewController.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZDetailViewBaseController.h"
#import "ZDetailViewBaseCell.h"
#import "ZDetailEditing.h"


@class ZDetailTableViewController;
@class ZDetailViewSection;

typedef BOOL (^ZDetailTableViewBuildContentHandler)(ZDetailTableViewController *aController);
typedef void (^ZDetailTableViewCellIterationHandler)(ZDetailTableViewController *aController, UITableViewCell *aCell, NSInteger aSectionNo);
typedef void (^ZDetailTableViewDetailViewCellIterationHandler)(ZDetailTableViewController *aController, UITableViewCell<ZDetailViewCell> *aCell, NSInteger aSectionNo);
typedef void (^ZDetailTableViewDetailBaseCellIterationHandler)(ZDetailTableViewController *aController, ZDetailViewBaseCell *aCell, NSInteger aSectionNo);



/// ZDetailTableViewController is a view controller managing a UITableView for displaying detail editors
/// consisting of ZDetailViewBaseCell objects. It can be used as a base class for custom detail editor
/// classes, but its design is such that full hierarchies of highly customized detail editing can be
/// set up without needing any subclassing, just by parametrizing the controller and its cells.
///
/// ZDetailTableViewController includes features such as
/// - different displayMode settings: basic/detail and viewing/editing which allow showing some
///   options/fields only in certain modes.
/// - cell grouping to expand/collapse subsections of a table depending on other settings, like a
///   switch.
/// - Managing the keyboard and smoothly moving editors in view when the keyboard appears
/// - Custom input views (e.g. date picker for ZDateTimeCell), sliding in and out in a keyboard-like fashion.
///
/// Simplest usage of ZDetailTableViewController is setting the buildDetailContentHandler property
/// with a block which creates some detail editing fields (cells) using the detailCell:withStyle: family of
/// methods, and then presenting the controller either by pushing it onto a UINavigationController, or
/// presenting it modally making use of viewControllerForModalPresentation or popoverControllerForPresentation
/// from ZDetailViewBaseController.
///
/// @note ZDetailTableViewController is _not_ a subclass of UITableViewController (but of UIViewController
///   via ZDetailViewBaseController).
@interface ZDetailTableViewController : ZDetailViewBaseController <ZDetailCellOwner>

/// convenience method to create a detail table view controller with a given title
+ (id)controllerWithTitle:(NSString *)aTitle;

/// @name building content

/// Outlet property for connecting the actual detail table view.
///
/// This can be used if the UITableView showing the detail editing cells is not the root view of the
/// controller (for example in subclasses that load other UI outside the table view from a nib, or
/// create other controls programmatically)
/// @note just leave this unassigned to have ZDetailTableViewController 
@property (strong, nonatomic) IBOutlet UITableView *detailTableView;

/// This block is called (if detailTableView method is not implemented and returning YES) to create
/// the contents (cells) of the detail table view.
///
/// This is the place to use startSection, startSectionWithText:asTitle: and endSection to create sections, and
/// detailCell:withStyle variants to create cells.
@property (copy,nonatomic) ZDetailTableViewBuildContentHandler buildDetailContentHandler;
- (void)setBuildDetailContentHandler:(ZDetailTableViewBuildContentHandler)buildDetailContentHandler; // declaration needed only for XCode autocompletion of block

/// for subclasses, this method can be overridden to build the content (instead of
/// assigning a block to buildDetailContentHandler.
/// Must return YES if 
- (BOOL)buildDetailContent;

/// @name adding editing sections and cells

/// Add a new section with a section header containing a text.
/// @param aText the text
/// @param aAsTitle if YES, the text is shown in a large font as a section title
- (void)startSectionWithText:(NSString *)aText asTitle:(BOOL)aAsTitle;

/// start a section without a header
- (void)startSection;

/// end the current section
- (void)endSection;

/// sort cells within a section by a property of the cells addressed by keyPath
- (void)sortSectionBy:(NSString *)aKeyPath ascending:(BOOL)aAscending;

/// sort cells within a section by a property of the cells addressed by keyPath
/// and also end the section
- (void)endSectionAndSortBy:(NSString *)aKeyPath ascending:(BOOL)aAscending;

/// create a detail cell of the given class and adds it to the current section
/// @param aClass class of the cell to be created
/// @param aStyle UITableViewCellStyle plus possibly some ZDetailViewCellStyleXXX flags
/// @param aNeededGroups a ORed mask of group bitmasks (see newGroupFlag) which must be enabled
///  in order to make the cell appear in the table view.
/// @param aNowEnabled set to YES if cell should be initially enabled (for cells where no other conditions
///  predetermined visibility anyway)
/// @note a section must be opened with startSection or startSectionWithText:asTitle: before
- (id)detailCell:(Class)aClass withStyle:(ZDetailViewCellStyle)aStyle neededGroups:(NSUInteger)aNeededGroups nowEnabled:(BOOL)aNowEnabled;

/// convenience method: create and add a detail cell using the defaultCellStyle
/// @note see detailCell:withStyle:neededGroups:nowEnabled: for details
- (id)detailCell:(Class)aClass neededGroups:(NSUInteger)aNeededGroups;

/// convenience method: create and add a detail cell using the defaultCellStyle and set enabled flag
/// @note see detailCell:withStyle:neededGroups:nowEnabled: for details
- (id)detailCell:(Class)aClass enabled:(BOOL)aEnabled;

/// convenience method: create and add a detail cell with given style which is always visible
/// @note see detailCell:withStyle:neededGroups:nowEnabled: for details
- (id)detailCell:(Class)aClass withStyle:(ZDetailViewCellStyle)aStyle;

/// convenience method: create and add a detail cell with defaultCellStyle which is always visible
/// @note see detailCell:withStyle:neededGroups:nowEnabled: for details
- (id)detailCell:(Class)aClass;

/// add a already created cell (must be a UITableViewCell, but use ZDetailViewBaseCell or at least
/// cells conforming to ZDetailViewCell protocol for full functionality)
/// @param the cell
/// @param aNeededGroups a ORed mask of group bitmasks (see newGroupFlag) which must be enabled
///  in order to make the cell appear in the table view.
/// @param aNowEnabled set to YES if cell should be initially enabled (for cells where no other conditions
///  predetermined visibility anyway)
/// @note a section must be opened with startSection or startSectionWithText:asTitle: before
- (void)addDetailCell:(UITableViewCell *)aCell neededGroups:(NSUInteger)aNeededGroups nowEnabled:(BOOL)aNowEnabled;
/// convenience method: add existing cell and set enabled flag
- (void)addDetailCell:(UITableViewCell *)aCell enabled:(BOOL)aEnabled;
/// convenience method: add existing cell which is always visible
- (void)addDetailCell:(UITableViewCell *)aCell;

/// @name apply common styling and setting to all cells

/// This can be set to a ZDetailViewCellStyle to define the default cell style used when
/// creating cells with detailCell: methods that don't have a withStyle parameter.
/// ZDetailViewCellStyle consists of one of the standard UITableViewCellStyle values, plus
/// optionally some ZDetailViewCellStyleXXX flags for extended style options for ZDetailViewBaseCell
/// (such as automatic label layout etc.)
/// @note if defaultCellStyle has the ZDetailViewCellStyleFlagInherit set, actual style will
/// be inherited from the parent (master) ZDetailTableViewController
@property (assign, nonatomic) ZDetailViewCellStyle defaultCellStyle; // style to be used to create default cells

/// This can be set to define the relative amount (0...1.0) of horizontal space the value part of the
/// cells will occupy. 
/// @note if defaultCellStyle has the ZDetailViewCellStyleFlagInherit set, defaultValueCellShare will
/// be inherited from the parent (master) ZDetailTableViewController
@property (assign, nonatomic) double defaultValueCellShare;


/// @note if defaultCellStyle has the ZDetailViewCellStyleFlagInherit set, cellSetupHandler will
/// be inherited from the parent (master) ZDetailTableViewController
@property (copy, nonatomic) ZDetailTableViewCellIterationHandler cellSetupHandler; // called on every cell added by detailCell:... method
- (void)setCellSetupHandler:(ZDetailTableViewCellIterationHandler)cellSetupHandler; // declaration needed only for XCode autocompletion of block

/// convenience iterator to iterate over all cells (UITableViewCell and subclasses)
- (void)forEachCell:(ZDetailTableViewCellIterationHandler)aIterationBlock;
/// convenience iterator to iterate over all cells conforming to the ZDetailViewCell protocol
/// (which are not necessarily ZDetailViewBaseCell s)
- (void)forEachDetailViewCell:(ZDetailTableViewDetailViewCellIterationHandler)aIterationBlock;
/// convenience iterator to iterate over all ZDetailViewBaseCell (and subclasses thereof)
/// (but no regular UITableViewCell that may also be part of the table)
- (void)forEachDetailViewBaseCell:(ZDetailTableViewDetailBaseCellIterationHandler)aIterationBlock;

/// @name cell groups

/// convenience method to generate group bitmasks
///
/// returns a new bit mask (starting with Bit 0) every time it is called. The generator is reset
/// before buildDetailContent method or the buildDetailContentHandler block is called.
/// @note group bitmasks can be used with detailCell:neededGroups: to add serveral cells
/// in a group, which can then be expanded/collapsed depending on other settings by changeGroups:toVisible:
- (NSUInteger)newGroupFlag;

/// bitmask of currently enabled groups
/// @note the integer values used for representing groups must be single bits (i.e. integer values 1,2,4,8...)
/// The newGroupFlag convenience method can be used to generate these bitmasks.
/// @note just setting this property does not automatically cause the changes to be applied to the table
/// use applyGroupChangesAnimated: for that.
@property (assign, nonatomic) NSUInteger enabledGroups;

/// apply current enabledGroups to the table, which will cause cells to animate in and out according
/// to their visibility
- (void)applyGroupChangesAnimated:(BOOL)aAnimated;

/// convenience method to make one or multiple groups visible or invisible
/// @param aGroupMask single group mask ORed combination of multiple groups
/// @param aVisible set YES to make the groups(s) visible, NO to make them invisible
- (void)changeGroups:(NSUInteger)aGroupMask toVisible:(BOOL)aVisible;

/// convenience method to make one or multiple groups visible or invisible and then apply it to the table
/// @param aGroupMask single group mask ORed combination of multiple groups
/// @param aVisible set YES to make the groups(s) visible, NO to make them invisible
- (void)changeDisplayedGroups:(NSUInteger)aGroupMask toVisible:(BOOL)aVisible animated:(BOOL)aAnimated;


/// @name appearance and behaviour properties

/// Set this to NO to prevent scrolling in the detail view (e.g. when it only contains a few fields). Default is YES.
@property (assign, nonatomic) BOOL scrollEnabled;

/// if set, first editable field will receive eding focus when detailview appears. Default is NO.
@property (assign, nonatomic) BOOL autoStartEditing;

/// @name custom input view management (keyboard-alike, for example date chooser)

/// editor cells can call this method to request presentation of a custom input view, which is
/// then animated into the screen (or page/sheet in iPad modal views) similar to the keyboard
/// @param aCustomInputView the view that should be presented as input view. It should be a UIView
/// which can be horizontally resized (for landscape views and for iPad). For example a UIPicker view
/// with autoresizeMask set to flexible right and left margins.
/// @note calls to requireCustomInputView: need to be matched by calls to releaseCustomInputView:
/// @note requireCustomInputView is usually called from beginEditing in a ZDetailViewBaseCell subclass
///  (see ZDateTimeCell for an example)
/// @note ZDetailTableViewController can manage a single input view shared by multiple cells.
///  To use this feature, cells should first check the customInputView property to see if the needed
///  view is already set, and if so, call requireCustomInputView with it. This prevents the same input view
///  to animate out and in again when focus moves to the next cell.
- (void)requireCustomInputView:(UIView *)aCustomInputView;

/// editors that present a custom input view with requireCustomInputView: must call releaseCustomInputView:
/// when editing is done to make the custom input view disappear.
/// @param aNilOrCustomInputView pass the same view as for requireCustomInputView: here. It is possible
///  to pass nil to just release the current input view, however this is not recommended in situations where
///  other cells might have installed another inputView in the meantime.
/// @note releaseCustomInputView is usually called from defocusCell in a ZDetailViewBaseCell subclass
///  (see ZDateTimeCell for an example)
- (void)releaseCustomInputView:(UIView *)aNilOrCustomInputView;

/// returns currently visible custom input view, or nil when there is none.
/// @note see requireCustomInputView: for information how to use this for shared input views.
@property (readonly, nonatomic) UIView *customInputView;


/// @name utilities for subclasses

/// returns the cell currently at given index path. All types of UITableViewCell are returned.
- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)aIndexPath;

/// returns the ZDetailViewBaseCell currently at given index path, or nil if none. Only ZDetailViewBaseCell and subclasses are returned.
- (ZDetailViewBaseCell *)detailCellForRowAtIndexPath:(NSIndexPath *)aIndexPath;

/// moves a cell from one index to another (only within same section)
/// @note this is a utility method to help implementing tableView:moveRowAtIndexPath:toIndexPath: UITableViewDelegate method
///  in subclasses (like ZChoiceListeController)
- (BOOL)moveRowFromIndexPath:(NSIndexPath *)aFromIndexPath toIndexPath:(NSIndexPath *)aToIndexPath;

@end

#pragma mark - ZDetailViewBaseCell (ZDetailTableViewControllerUtils)

/// category on ZDetailViewBaseCell providing ZDetailTableViewController related methods
@interface ZDetailViewBaseCell (ZDetailTableViewControllerUtils)

/// returns the owning ZDetailTableViewController (if not owned by another type of UIViewController)
- (ZDetailTableViewController *)detailTableViewController;

@end