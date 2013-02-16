//
//  ZDetailViewBaseController.h
//
//  Created by Lukas Zeller on 16.02.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZDetailEditing.h"
#import "ZDetailValueConnector.h"

@class ZDetailViewBaseController;

typedef void (^ZDetailViewDidCloseHandler)(ZDetailViewBaseController *aController, BOOL cancelled);

// navigation button mode
typedef enum {
  ZDetailNavigationModeNone = 0, // no automatic navigation management
  ZDetailNavigationModeLeftButtonAuto = 0x01, // show back button normally, and "done" in case view is modally presented
  ZDetailNavigationModeLeftButtonCancel = 0x02, // show a left button which cancels detail editor (normal)
  ZDetailNavigationModeLeftButtonDone = 0x04, // show a left buttin which closes (and saves) detail editor
  ZDetailNavigationModeRightButtonSave = 0x100, // show a right button which saves detail editor (bright blue)
  ZDetailNavigationModeRightButtonEditViewing = 0x200, // show a right button which toggles cells (not table) between edit and view modes
  ZDetailNavigationModeRightButtonTableEditDone = 0x400, // show a right button which toggles table editing mode on/off
  ZDetailNavigationModeRightButtonDetailsBasics = 0x800, // show a right button which toggles cells (not table) between basic and details mode
} ZDetailNavigationMode;


@interface ZDetailViewBaseController : UIViewController <ZDetailViewController, ZDetailViewParent>


// operating
- (void)internalInit;
- (id)init;

/// returns the wrapper navigation controller if presented modally
@property(readonly) UINavigationController *modalViewWrapper;

/// returns YES if controller has appeared (is visible)
@property(assign,readonly) BOOL hasAppeared;

/// detailview data connection active
@property (assign, nonatomic) BOOL active; // data connection activation

// ZDetailViewController protocol
@property(weak, nonatomic) id<ZDetailViewParent> parentDetailViewController;


- (void)cancel; // abort editing, prevent further saves (even if save is called)
- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP; // test if all cells validate and collect NSErrors in array (if array exists, errors will be appended)
- (void)save; // save edits from all cells
- (void)revert; // revert all cells to saved data

// Presentation and navigation
- (UIPopoverController *)popoverControllerForPresentation;
- (UIViewController *)viewControllerForModalPresentation;
- (void)pushViewControllerForDetail:(UIViewController *)aViewController animated:(BOOL)aAnimated;
- (BOOL)dismissDetailViewWithSave:(BOOL)aWithSave;
- (void)dismissDetailStack;
@property (assign, nonatomic) ZDetailNavigationMode navigationMode;
@property (strong, nonatomic) NSString *detailsButtonTitle;
// - convenience property - returns root of ZDetailViewController protocol conforming controller chain
@property (unsafe_unretained, readonly, nonatomic) id<ZDetailViewController> rootDetailViewController;


/// @name appearance and behaviour properties

/// The display mode (basics, details, editing)
@property (readonly, nonatomic) ZDetailDisplayMode displayMode;

/// set displayMode with this method
- (void)setDisplayMode:(ZDetailDisplayMode)aDisplayMode animated:(BOOL)aAnimated;

/// update display mode
- (void)updateDisplayMode:(ZDetailDisplayMode)aMode animated:(BOOL)aAnimated;



/// will be called after closing a detail editor
@property (copy,nonatomic) ZDetailViewDidCloseHandler detailDidCloseHandler;
- (void)setDetailDidCloseHandler:(ZDetailViewDidCloseHandler)detailDidCloseHandler; // declaration needed only for XCode autocompletion of block


/// register connectors (usually in the subclass' internalInit)
- (ZDetailValueConnector *)registerConnector:(ZDetailValueConnector *)aConnector;

/// update valueConnectors on controller level
- (void)updateData;
/// unload data on controller level 
- (void)unloadData;
/// update visibilities of UI elements
- (void)updateVisibilitiesAnimated:(BOOL)aAnimated;
/// prepare for possible termination of the app
- (void)prepareForPossibleTermination;


/// save valueConnectors on controller level
- (void)save;

/// revert valueConnectors on controller level
- (void)revert;

/// defocus editing fields, if any
- (void)defocus;


/// @name methods to override in subclasses

/// called when the detail view will open
/// @note this is similar to viewWillAppear, but is only called when view appears first
/// on the navigation stack. It is not called when the view re-appears due to a more recently pushed
/// view is popped from the navigation stack
- (void)detailViewWillOpen:(BOOL)aAnimated;

/// called when the detail view will close
/// @note this is similar to viewWillDisappear, but is only called when view disappears from the
/// navigation stack. It is not called when the view just disappears under an other view pushed
/// onto the navigation stack
- (void)detailViewWillClose:(BOOL)aAnimated;

/// called when the detail view did close
/// @note this is similar to viewDidDisappear, but is only called when view has disappeared from the
/// navigation stack. It is not called when the view just disappeared under an other view pushed
/// onto the navigation stack
- (void)detailViewDidClose:(BOOL)aAnimated;



@end
