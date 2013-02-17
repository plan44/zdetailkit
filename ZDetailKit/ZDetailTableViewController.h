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



@interface ZDetailTableViewController : ZDetailViewBaseController <ZDetailCellOwner>

/// convenience method to create a detail table view controller with a given title
+ (id)controllerWithTitle:(NSString *)aTitle;

// Outlet property for connecting the actual detail table view. 
@property (strong, nonatomic) IBOutlet UITableView *detailTableView;

// content building
@property (copy,nonatomic) ZDetailTableViewBuildContentHandler buildDetailContentHandler;
- (void)setBuildDetailContentHandler:(ZDetailTableViewBuildContentHandler)buildDetailContentHandler; // declaration needed only for XCode autocompletion of block
- (BOOL)buildDetailContent; // can be overridden in subclasses, returns YES if actually built content

// adding editing sections and cells
// - sections
- (void)startSectionWithText:(NSString *)aText asTitle:(BOOL)aAsTitle;
- (void)startSection;
- (void)endSection;
- (void)sortSectionBy:(NSString *)aKey ascending:(BOOL)aAscending;
- (void)endSectionAndSortBy:(NSString *)aKey ascending:(BOOL)aAscending;
// - groups
/// convenience method to generate group bitmasks
///
/// returns a new bit mask (starting with Bit 0) every time it is called. The generator is reset
/// before buildDetailContent method or the buildDetailContentHandler block is called.
- (NSUInteger)newGroupFlag;
// - cells
@property (assign, nonatomic) ZDetailViewCellStyle defaultCellStyle; // style to be used to create default cells
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


/// @name appearance and behaviour properties

@property (assign, nonatomic) BOOL scrollEnabled; // controls if table may scroll
@property (assign, nonatomic) BOOL autoStartEditing; // if set, first editable field will receive eding focus when detailview appears

// groups
@property (assign, nonatomic) NSUInteger enabledGroups;
- (void)changeGroups:(NSUInteger)aGroupMask toVisible:(BOOL)aVisible;
- (void)changeDisplayedGroups:(NSUInteger)aGroupMask toVisible:(BOOL)aVisible animated:(BOOL)aAnimated;
- (void)applyGroupChangesAnimated:(BOOL)aAnimated;

// input views (keyboard-alike, for example date chooser)
@property (readonly, nonatomic) UIView *customInputView;
- (void)requireCustomInputView:(UIView *)aCustomInputView;
- (void)releaseCustomInputView:(UIView *)aNilOrCustomInputView;

// utilities for subclasses
- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)aIndexPath;
- (ZDetailViewBaseCell *)detailCellForRowAtIndexPath:(NSIndexPath *)aIndexPath;
- (BOOL)moveRowFromIndexPath:(NSIndexPath *)aFromIndexPath toIndexPath:(NSIndexPath *)aToIndexPath;


@end
