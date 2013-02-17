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

/// returns YES if controller has appeared (is visible)
@property(assign,readonly) BOOL hasAppeared;

/// this property must be set to YES to activate the controller.
///
/// When activated, the controller connects it to its data by activating valueConnectors
/// and builds up its content to present the data.
@property (assign, nonatomic) BOOL active;

/// abort editing, prevent further saves (even if save is called)
- (void)cancel;

/// test if all editable content validates ok and collect NSErrors for validation failures.
/// @param aErrorsP can be passed an existing mutable array, if errors are encountered these are appened to it.
///   If passed nil, a NSMutableArray is automatically created when the first error occurs.
- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP;
- (void)save; // save edits from all cells
- (void)revert; // revert all cells to saved data

/// @name Presentation and navigation

/// returns the wrapper navigation controller if presented modally
@property(readonly) UINavigationController *modalViewWrapper;

/// returns a popover controller for presenting this detail view
///
/// The returned controller wraps a navigation controller which in turn contains this controller
/// as its root controller. The wrapper controllers inherit the relevant modal presentation
/// properties from this controller.
- (UIPopoverController *)popoverControllerForPresentation;


/// returns a controller for presenting this detail view modally
///
/// The returned controller is a navigation controller and inherits the relevant modal presentation
/// properties from this controller.
- (UIViewController *)viewControllerForModalPresentation;

/// pushes a view controller as a detail editor
///
/// This method can be used to push ordinary UIViewControllers (in this case the functionality of
/// this method is just defocusing of current edits, passing the content size for popovers
/// followed by pushViewController:animated:)
///
/// However, when used with controllers conforming to the ZDetailViewController protocol,
/// the pushed controller's parentDetailViewController and this controller's
/// currentChildDetailViewController are automatically set. This allows this controller to get
/// notified automatically when the detail editor is closed.
///
/// @note it is recommended to always use this method to push detail editors to make sure all
/// features of ZDetailKit work properly.
- (void)pushViewControllerForDetail:(UIViewController *)aViewController animated:(BOOL)aAnimated;


- (BOOL)dismissDetailViewWithSave:(BOOL)aWithSave;
- (void)dismissDetailStack;
@property (assign, nonatomic) ZDetailNavigationMode navigationMode;
@property (strong, nonatomic) NSString *detailsButtonTitle;
// - convenience property - returns root of ZDetailViewController protocol conforming controller chain
@property (unsafe_unretained, readonly, nonatomic) id<ZDetailViewController> rootDetailViewController;


// ZDetailViewController protocol
@property(weak, nonatomic) id<ZDetailViewParent> parentDetailViewController;


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
