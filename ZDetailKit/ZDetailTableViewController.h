//
//  ZDetailTableViewController.h
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZDetailViewBaseCell.h"
#import "ZDetailEditing.h"


// navigation button mode
typedef enum {
  ZDetailNavigationModeNone = 0, // no automatic navigation management
  ZDetailNavigationModeLeftButtonCancel = 0x01, // show a left button which cancels detail editor (normal)
  ZDetailNavigationModeRightButtonSave = 0x02, // show a right button which saves detail editor (bright blue)
  ZDetailNavigationModeRightButtonEditViewing = 0x04, // show a right button which toggles cells (not table) between edit and view modes 
  ZDetailNavigationModeRightButtonTableEditDone = 0x08, // show a right button which toggles table editing mode on/off 
  ZDetailNavigationModeRightButtonDetailsBasics = 0x10, // show a right button which toggles cells (not table) between basic and details mode 
} ZDetailNavigationMode;


@class ZDetailTableViewController;
@class ZDetailViewSection;

typedef BOOL (^ZDetailTableViewBuildContentHandler)(ZDetailTableViewController *aController);
typedef void (^ZDetailTableViewCellSetupHandler)(ZDetailTableViewController *aController, UITableViewCell *aNewCell);



@interface ZDetailTableViewController : UIViewController <ZDetailViewController, ZDetailCellOwner, ZDetailViewParent>


// Outlet property for connecting the actual detail table view. 
@property (retain, nonatomic) IBOutlet UITableView *detailTableView;

// content building
@property (copy,nonatomic) ZDetailTableViewBuildContentHandler buildDetailContentHandler;
- (BOOL)buildDetailContent; // can be overridden in subclasses, returns YES if actually built content

// adding editing sections and cells
// - sections
- (void)startSectionWithText:(NSString *)aText asTitle:(BOOL)aAsTitle;
- (void)startSection;
- (void)endSection;
- (void)sortSectionBy:(NSString *)aKey ascending:(BOOL)aAscending;
- (void)endSectionAndSortBy:(NSString *)aKey ascending:(BOOL)aAscending;
// - cells
@property (assign, nonatomic) ZDetailViewCellStyle defaultCellStyle; // style to be used to create default cells
@property (copy, nonatomic) ZDetailTableViewCellSetupHandler cellSetupHandler; // called on every cell added by detailCell:... method
- (id)detailCell:(Class)aClass withStyle:(ZDetailViewCellStyle)aStyle inGroup:(NSUInteger)aGroup nowEnabled:(BOOL)aNowEnabled;
- (id)detailCell:(Class)aClass inGroup:(NSUInteger)aGroup;
- (id)detailCell:(Class)aClass enabled:(BOOL)aEnabled;
- (id)detailCell:(Class)aClass withStyle:(ZDetailViewCellStyle)aStyle;
- (id)detailCell:(Class)aClass;
- (void)addDetailCell:(UITableViewCell *)aCell inGroup:(NSUInteger)aGroup nowEnabled:(BOOL)aNowEnabled;
- (void)addDetailCell:(UITableViewCell *)aCell enabled:(BOOL)aEnabled;
- (void)addDetailCell:(UITableViewCell *)aCell;


// appearance and behaviour properties
@property (readonly, nonatomic) ZDetailDisplayMode displayMode; // The display mode (basics, details, editing)
- (void)setDisplayMode:(ZDetailDisplayMode)aDisplayMode animated:(BOOL)aAnimated; // set displayMode with this method
@property (assign, nonatomic) BOOL scrollEnabled; // controls if table may scroll
@property (assign, nonatomic) BOOL autoStartEditing; // if set, first editable field will receive eding focus when detailview appears

// detailview data connection control
@property (assign, nonatomic) BOOL cellsActive; // cell data connection activation
- (void)cancel; // abort editing, prevent further saves (even if save is called)
- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP; // test if all cells validate and collect NSErrors in array (if array exists, errors will be appended)
- (void)save; // save edits from all cells
- (void)revert; // revert all cells to saved data

// Presentation and navigation
- (UIViewController *)viewControllerForModalPresentation;
- (void)pushViewControllerForDetail:(UIViewController *)aViewController animated:(BOOL)aAnimated;
- (BOOL)dismissDetailViewWithSave:(BOOL)aWithSave;
- (void)dismissDetailStack;
@property (assign, nonatomic) ZDetailNavigationMode navigationMode;
@property (retain, nonatomic) NSString *detailsButtonTitle;
// - convenience property - returns root of ZDetailViewController protocol conforming controller chain
@property (readonly, nonatomic) id<ZDetailViewController> rootDetailViewController;

// operating
- (void)internalInit;
- (id)init;
+ (id)controllerWithTitle:(NSString *)aTitle;
- (void)prepareForPossibleTermination;
- (void)updateData;
- (void)updateCellVisibilitiesAnimated:(BOOL)aAnimated;

// groups
- (void)setGroup:(NSUInteger)aGroupNo visible:(BOOL)aVisible;
- (void)displayGroup:(NSUInteger)aGroupNo visible:(BOOL)aVisible animated:(BOOL)aAnimated;
// internal events
- (void)detailViewWillOpen:(BOOL)aAnimated;
- (void)detailViewWillClose:(BOOL)aAnimated;
- (void)detailViewDidClose:(BOOL)aAnimated;

// controller-level (rather than cell-level) value connectors
// - register connectors (usually in the subclass' internalInit)
- (ZDetailValueConnector *)registerConnector:(ZDetailValueConnector *)aConnector;

// utilities for subclasses
- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)aIndexPath;
- (ZDetailViewBaseCell *)detailCellForRowAtIndexPath:(NSIndexPath *)aIndexPath;
- (BOOL)moveRowFromIndexPath:(NSIndexPath *)aFromIndexPath toIndexPath:(NSIndexPath *)aToIndexPath;


@end
