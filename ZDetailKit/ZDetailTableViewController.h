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

/// This can be set to a ZDetailViewCellStyle to define the default cell style used when
/// creating cells with detailCell: methods that don't have a withStyle parameter.
/// ZDetailViewCellStyle consists of one of the standard UITableViewCellStyle values, plus
/// optionally some ZDetailViewCellStyleXXX flags for extended style options for ZDetailViewBaseCell
/// (such as automatic label layout etc.)
@property (assign, nonatomic) ZDetailViewCellStyle defaultCellStyle; // style to be used to create default cells

/// This can be set to define the relative amount (0...1.0) of horizontal space the value part of the
/// cells will occupy. 
@property (assign, nonatomic) double defaultValueCellShare;


@property (copy, nonatomic) ZDetailTableViewCellIterationHandler cellSetupHandler; // called on every cell added by detailCell:... method
- (void)setCellSetupHandler:(ZDetailTableViewCellIterationHandler)cellSetupHandler; // declaration needed only for XCode autocompletion of block
- (id)detailCell:(Class)aClass withStyle:(ZDetailViewCellStyle)aStyle neededGroups:(NSUInteger)aNeededGroups nowEnabled:(BOOL)aNowEnabled;
- (id)detailCell:(Class)aClass neededGroups:(NSUInteger)aNeededGroups;
- (id)detailCell:(Class)aClass enabled:(BOOL)aEnabled;
- (id)detailCell:(Class)aClass withStyle:(ZDetailViewCellStyle)aStyle;
- (id)detailCell:(Class)aClass;
- (void)addDetailCell:(UITableViewCell *)aCell neededGroups:(NSUInteger)aNeededGroups nowEnabled:(BOOL)aNowEnabled;
- (void)addDetailCell:(UITableViewCell *)aCell enabled:(BOOL)aEnabled;
- (void)addDetailCell:(UITableViewCell *)aCell;
- (void)forEachCell:(ZDetailTableViewCellIterationHandler)aIterationBlock;
- (void)forEachDetailViewCell:(ZDetailTableViewDetailViewCellIterationHandler)aIterationBlock;
- (void)forEachDetailViewBaseCell:(ZDetailTableViewDetailBaseCellIterationHandler)aIterationBlock;



/// @name cell groups

/// convenience method to generate group bitmasks
///
/// returns a new bit mask (starting with Bit 0) every time it is called. The generator is reset
/// before buildDetailContent method or the buildDetailContentHandler block is called.
/// @note group bitmasks can be used with detailCell:neededGroups: to add serveral cells
/// in a group, which can then be expanded/collapsed depending on other settings by changeGroups:toVisible:
- (NSUInteger)newGroupFlag;

// groups
@property (assign, nonatomic) NSUInteger enabledGroups;
- (void)changeGroups:(NSUInteger)aGroupMask toVisible:(BOOL)aVisible;
- (void)changeDisplayedGroups:(NSUInteger)aGroupMask toVisible:(BOOL)aVisible animated:(BOOL)aAnimated;
- (void)applyGroupChangesAnimated:(BOOL)aAnimated;





/// @name appearance and behaviour properties

@property (assign, nonatomic) BOOL scrollEnabled; // controls if table may scroll
@property (assign, nonatomic) BOOL autoStartEditing; // if set, first editable field will receive eding focus when detailview appears

// input views (keyboard-alike, for example date chooser)
@property (readonly, nonatomic) UIView *customInputView;
- (void)requireCustomInputView:(UIView *)aCustomInputView;
- (void)releaseCustomInputView:(UIView *)aNilOrCustomInputView;

// utilities for subclasses
- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)aIndexPath;
- (ZDetailViewBaseCell *)detailCellForRowAtIndexPath:(NSIndexPath *)aIndexPath;
- (BOOL)moveRowFromIndexPath:(NSIndexPath *)aFromIndexPath toIndexPath:(NSIndexPath *)aToIndexPath;


@end
