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



/// Base class for implementing detail view editors
///
/// @note for classic detail editors consisting of a table view with cells representing detail values,
/// use the ZDetailTableViewController sublcass. This class can be used by non table based editors
/// (see ZMapLocationEdit for an example).
@interface ZDetailViewBaseController : UIViewController <ZDetailViewController, ZDetailViewParent>


/// @name Initializing

- (id)init;


/// @name data connection

/// this property must be set to YES to activate the controller.
///
/// When activated, the controller connects it to its data by activating valueConnectors
/// and builds up its content to present the data.
@property (assign, nonatomic) BOOL active;

/// abort editing, prevent further saves (even if save is called)
/// @note this also sets active = NO
- (void)cancel;

/// test if all editable content validates ok and collect NSErrors for validation failures.
/// @param aErrorsP can be passed an existing mutable array, if errors are encountered these are appened to it.
///   If passed nil, a NSMutableArray is automatically created when the first error occurs.
- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP;

/// save all data represented by the controller and its contained objects (table cells, controls, etc.)
/// to the model objects connected by the valueConnectors.
/// @note this can be overridden in subclasses to perform additional actions after all edits are saved
/// to the connected data objects/fields (such as dumping out the data to a DB etc.) 
- (void)save;

/// revert controller, forget all edits and again show the data connected to by valueConnectors
- (void)revert;


/// @name Presentation and navigation

/// returns the wrapper navigation controller if presented modally
@property(readonly) UINavigationController *modalViewWrapper;

/// returns YES if controller has appeared (is visible)
@property(assign,readonly) BOOL hasAppeared;

/// returns YES if controller is dismissing now
@property(assign,readonly) BOOL dismissing;

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
/// the pushed controller's becomesDetailViewOfCell will be called and this controller's
/// currentChildDetailViewController are automatically set. This allows this controller to get
/// notified automatically when the detail editor is closed.
///
/// @param aCell can be nil, but when ZDetailTableViewController calls this method, it will pass
///   the originating cell here.
///
/// @note it is recommended to always use this method to push detail editors to make sure all
/// features of ZDetailKit work properly.
- (void)pushViewControllerForDetail:(UIViewController *)aViewController fromCell:(id<ZDetailViewCell>)aCell animated:(BOOL)aAnimated;

/// explicitly dismiss the current detail view with optionally saving edits
/// @param aWithSave if YES, edits will be saved (by calling save on all valueConnectors) 
/// @return YES if detail view could be dismissed
/// NO if validation errors prevented detail view to be dismissed
///
/// This is usually automatically called from back, cancel and edit buttons as configured with
/// navigationMode. When the detail view was presented modally or within a popover, these wrapper
/// controllers are automatically removed and disposed of.
/// @note value connectors that have autoSaveValue set will immediately save values during editing,
/// so these values will propagate even if aWithSave is NO. So if you need save/cancel semantics for
/// a detail editor, make sure to have autoSaveValue NO (the default) in all connectors.
/// @note If the controller is dismissed using another method (like directly poping it from the
/// navigation stack or by terminating the app, values will always be saved unless a previous
/// call to cancel has been made.
- (BOOL)dismissDetailViewWithSave:(BOOL)aWithSave animated:(BOOL)aAnimated;

/// dismiss all open details on top of and including this controller
- (void)dismissDetailStack;

/// set the navigation mode (what left and right buttons to show in the toolbar)
/// @note See ZDetailNavigationMode enum for available options
@property (assign, nonatomic) ZDetailNavigationMode navigationMode;

/// title text for the "Details" button (when navigationMode includes ZDetailNavigationModeRightButtonDetailsBasics)
@property (strong, nonatomic) NSString *detailsButtonTitle;

/// can be overridden by subclasses to set a custom left navigation button
/// @note setting this disabled left button configuration set with navigationMode
- (UIBarButtonItem *)customLeftNavigationButton;
/// can be overridden by subclasses to set a custom right navigation button
/// @note setting this disabled right button configuration set with navigationMode
- (UIBarButtonItem *)customRightNavigationButton;


/// convenience property - returns root of ZDetailViewController protocol conforming controller chain
@property (unsafe_unretained, readonly, nonatomic) id<ZDetailViewController> rootDetailViewController;



/// @name appearance and behaviour properties

/// The current display mode (basics, details, editing)
/// @note use setDisplayMode:animated: to change the display mode
@property (readonly, nonatomic) ZDetailDisplayMode displayMode;

/// set the display mode (basics, details, editing)
///
/// ZDetailViewBaseController and ZDetailTableViewController support view-only and edit modes, as well
/// as a standard and a detailed view. In the standard view, some less important information might be hidden
/// or only shown when not empty.
///
/// @note see ZDetailDisplayMode enum for available options
- (void)setDisplayMode:(ZDetailDisplayMode)aDisplayMode animated:(BOOL)aAnimated;


/// will be called after closing a detail editor
@property (copy,nonatomic) ZDetailViewDidCloseHandler detailDidCloseHandler;
- (void)setDetailDidCloseHandler:(ZDetailViewDidCloseHandler)detailDidCloseHandler; // declaration needed only for XCode autocompletion of block



/// @name utilities

/// register connectors (usually in the subclass' internalInit)
- (ZDetailValueConnector *)registerConnector:(ZDetailValueConnector *)aConnector;

/// update visibilities of UI elements
- (void)updateVisibilitiesAnimated:(BOOL)aAnimated;

/// defocus editing fields, if any
- (void)defocus;


/// @name methods to override in subclasses


/// this is called from any of the standard init method variations (withCoder, withNibName)
///
/// If a subclass needs to initialize some internals, but does not need
/// a special init method signature, this is the method to override
/// @note always call [super internalInit]
- (void)internalInit;

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

/// called to activate or deactivate the detail view, which includes activating/deactivation embedded
/// value connectors.
///
/// This can be overridden in subclasses when additional action is needed before/after activating/deactivating
/// data connections.
/// @note always call [super setActive:]
- (void)setActive:(BOOL)active;

/// called to prepare for possible termination of the app
- (void)prepareForPossibleTermination;

@end
