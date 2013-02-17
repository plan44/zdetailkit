//
//  ZDetailViewBaseController.m
//
//  Created by Lukas Zeller on 16.02.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseController.h"

#import "ZOrientation.h"
#import "ZString_utils.h"


#pragma mark - internal Helper classes declarations

@interface ZModalViewWrapper : UINavigationController

@end


#pragma mark - internal Helper classes implementation


@implementation ZModalViewWrapper

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  // reflect wish of wrapped controller
  if ([self.viewControllers count]==0) return NO;
  return [[self.viewControllers objectAtIndex:0] shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (BOOL)disablesAutomaticKeyboardDismissal
{
  // we want the keyboard to go away in all cases
  // (apple prevents it to disappear in UIModalPresentationFormSheet mode)
  return NO;
}

@end


#pragma mark - ZDetailViewBaseController


@interface ZDetailViewBaseController () {
  // controller level value connectors
  NSMutableArray *valueConnectors;
  // cause for view to disappear
  BOOL disappearsUnderPushed;
  // protection flag agains dismissing more than once
  BOOL dismissed; // set when view has been completely and successfully dismissed
  BOOL dismissing; // dismissing in process, but save exception could block it
  // set if editor was dismissed with cancel
  BOOL cancelled;
  // for modally displaying the detail view (instead of pushing on existing navigation stack)
  UIPopoverController *popoverWrapper;
}
@property(retain, nonatomic) id<ZDetailViewController> currentChildDetailViewController;
- (void)updateDisplayMode:(ZDetailDisplayMode)aMode animated:(BOOL)aAnimated;
- (void)updateNavigationButtonsAnimated:(BOOL)aAnimated;
@end



@implementation ZDetailViewBaseController

#pragma mark - initialisation and cleanup

@synthesize parentDetailViewController;
@synthesize currentChildDetailViewController;
@synthesize modalViewWrapper;
@synthesize hasAppeared;

- (void)internalInit
{
  // no referenced objects
  parentDetailViewController = nil;
  currentChildDetailViewController = nil;
  valueConnectors = [[NSMutableArray alloc] initWithCapacity:3];
  // not modally displayed
  modalViewWrapper = nil;
  popoverWrapper = nil;
  // flag to detect if view disappears because another one is pushed on top (no save then)
  disappearsUnderPushed = NO;
  hasAppeared = NO;
  dismissed = NO;
  dismissing = NO;
  cancelled = NO;
  // internal flags
  active = NO;
  // no handlers
  detailDidCloseHandler = nil;
  // default navigation
  navigationMode = ZDetailNavigationModeLeftButtonAuto; // no extra buttons, but left button automatically set to "done" for modally presented details
  // default mode: editing basics, scroll enabled
  displayMode = ZDetailDisplayModeBasics+ZDetailDisplayModeEditing; // no details, enabled for editing
}


// designated initializer for UIViewControllers
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  // UIViewController init loads
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    [self internalInit];
	}
	return self;
}


// when loaded as part of a nib (not the root nib)
- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
    [self internalInit];
	}
	return self;
}


// convenience initializer
- (id)init
{
  return [self initWithNibName:nil bundle:nil];
}


- (void) dealloc
{
  // disable all connections to make sure no KVO remains active to
  // embedded objects that might get destroyed before the embedded valueConnectors
  // (as we don't have any control over ARCs order of deallocation)
  self.active = NO;
}


#pragma mark - appearance and behaviour properties

@synthesize displayMode;

// Note: displayMode is readonly, must be set with this method!
- (void)setDisplayMode:(ZDetailDisplayMode)aDisplayMode animated:(BOOL)aAnimated
{
  if (aDisplayMode!=displayMode) {
    // mode changes
    BOOL editingEnds =
    (displayMode & ZDetailDisplayModeEditing) != 0 && // editing before
    (aDisplayMode & ZDetailDisplayModeEditing) == 0; // but not any more
    // - save if editing ends
    if (editingEnds) {
      [self save];
    }
    // - make sure we always have one of details/basic and one of editing/viewing flags set
    if ((displayMode & ZDetailDisplayModeBasics+ZDetailDisplayModeDetails)==0)
      displayMode |= ZDetailDisplayModeBasics; // if none set, use basic by default
    if ((displayMode & ZDetailDisplayModeViewing+ZDetailDisplayModeEditing)==0)
      displayMode |= ZDetailDisplayModeViewing; // if none set, use viewing by default
    // - set new
    displayMode = aDisplayMode;
    // - changing mode needs checking which cells are now active
    [self updateVisibilitiesAnimated:aAnimated];
    // - update cell modes
    [self updateDisplayMode:displayMode animated:aAnimated];
    // - update the editing button (if any)
    [self updateNavigationButtonsAnimated:aAnimated];
  }
}


- (void)updateVisibilitiesAnimated:(BOOL)aAnimated
{
  // nop in base class
}


- (void)updateDisplayMode:(ZDetailDisplayMode)aDisplayMode animated:(BOOL)aAnimated
{
  // nop in base class
}



#pragma mark - controller level value connectors


// for subclasses to register connectors
- (ZDetailValueConnector *)registerConnector:(ZDetailValueConnector *)aConnector
{
  [valueConnectors addObject:aConnector];
  return aConnector;
}




#pragma mark - detailview data connection control


@synthesize active;

- (void)setActive:(BOOL)aActive
{
  if (aActive!=self.active) {
    // update status flag
    active = aActive;
    // propagate to controller level value connectors
    for (ZDetailValueConnector *connector in valueConnectors) {
      connector.active = active;
    }
  }
}



- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP
{
  BOOL validates = YES;
  if (self.active) {
    // controller level value connectors
    for (ZDetailValueConnector *connector in valueConnectors) {
      validates = validates && [connector validatesWithErrors:aErrorsP];
    }
  }
  return validates;
}



- (void)save
{
  // do not save if already inactive (e.g. because edits were cancelled)
  if (self.active) {
    for (ZDetailValueConnector *connector in valueConnectors) {
      [connector saveValue];
    }
    // mark saved
    cancelled = NO;
  }
}


- (void)revert
{
  for (ZDetailValueConnector *connector in valueConnectors) {
    [connector loadValue];
  }
}


- (void)defocus
{
  // NOP in base class
}



- (void)cancel
{
  // mark cancelled
  cancelled = YES;
  // deactivate connections (prevents further saves)
  self.active = NO;
}


- (void)cancelButtonAction
{
  [self dismissDetailViewWithSave:NO]; // dismiss view without save
}


- (void)saveButtonAction
{
  [self dismissDetailViewWithSave:YES]; // (try to) dismiss view with save
}


- (void)editDoneButtonAction
{
  // remove content editing mode
  [self setDisplayMode:self.displayMode & ~ZDetailDisplayModeEditing animated:YES];
}


- (void)editStartButtonAction
{
  // start content editing mode
  [self setDisplayMode:self.displayMode | ZDetailDisplayModeEditing animated:YES];
}


- (void)detailsDoneButtonAction
{
  // switch to basic mode
  [self setDisplayMode:(self.displayMode & ~ZDetailDisplayModeDetails) | ZDetailDisplayModeBasics animated:YES];
}


- (void)detailsStartButtonAction
{
  // switch to basic mode
  [self setDisplayMode:(self.displayMode & ~ZDetailDisplayModeDetails) | ZDetailDisplayModeBasics animated:YES];
}



- (void)updateNavigationButtonsAnimated:(BOOL)aAnimated
{
  // Left button
  UIBarButtonItem *leftButton = nil;
  ZDetailNavigationMode navMode = navigationMode;
  // check if we need automatic adjustments
  if (navMode & ZDetailNavigationModeLeftButtonAuto) {
    // make sure we can leave the modal (or popover) presentation
    if (modalViewWrapper && (modalViewWrapper.modalInPopover || !popoverWrapper)) {
      // non-popovers and modal popovers need a Done button
      navMode = navMode | ZDetailNavigationModeLeftButtonDone;
    }
  }
  // now apply
  if (navMode & ZDetailNavigationModeLeftButtonCancel) {
    // left side must be a cancel button
    leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonAction)];
  }
  else if (navMode & ZDetailNavigationModeLeftButtonDone) {
    // done button for root view controllers, saves content
    leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveButtonAction)];
  }
  else {
    // if it's a back button, intercept its action
    #warning "%%% tbd - intercept back button press"
  }
  [self.navigationItem setLeftBarButtonItem:leftButton animated:aAnimated];
  // Right button
  UIBarButtonItem *rightButton = nil;
  if (navMode & ZDetailNavigationModeRightButtonSave) {
    rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonAction)];
  }
  else if (navMode & ZDetailNavigationModeRightButtonEditViewing) {
    if (self.displayMode & ZDetailDisplayModeEditing) {
      // is editing, show "done"
      rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editDoneButtonAction)];
    }
    else {
      // is viewing, show "edit"
      rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editStartButtonAction)];
    }
  }
  else if (navMode & ZDetailNavigationModeRightButtonTableEditDone) {
    // use the standard editing button from UIViewController which is auto connected to the editing property
    rightButton = self.editButtonItem; // will be autoreleased below
  }
  else if (navMode & ZDetailNavigationModeRightButtonDetailsBasics) {
    if (self.displayMode & ZDetailDisplayModeDetails) {
      // is showing details, show "done"
      rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(detailsDoneButtonAction)];
    }
    else {
      // is showing basics, show "details"
      rightButton = [[UIBarButtonItem alloc] initWithTitle:detailsButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(detailsStartButtonAction)];
    }
  }
  [self.navigationItem setRightBarButtonItem:rightButton animated:aAnimated];
}



#pragma mark - appearance management

@synthesize detailDidCloseHandler;


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	// return YES for all globally supported orientations (essential even if not being rotated myself)
  return [ZOrientation supportsInterfaceOrientation:toInterfaceOrientation];
}


- (void)viewWillAppear:(BOOL)aAnimated
{
  // activate (load content) if not already active
  self.active = YES;
  if (!disappearsUnderPushed) {
  	// was not only hidden under pushed detail
    // - let subclasses know
    [self detailViewWillOpen:aAnimated];
    self.currentChildDetailViewController = nil;
    cancelled = NO;
    dismissed = NO;
  }
  [super viewWillAppear:aAnimated];
}


- (void)viewDidAppear:(BOOL)aAnimated
{
  // has appeared (again), next disappear is not push unless the flag is set again explicitly
  hasAppeared = YES;
  disappearsUnderPushed = NO;
  // make sure we have a title view, in case something is pushed on top
  if ([self.navigationItem.title length]==0)
    self.navigationItem.title = self.title;
  // update/install navigation buttons
  [self updateNavigationButtonsAnimated:NO];
  // super
	[super viewDidAppear:aAnimated];
}


- (void)viewWillDisappear:(BOOL)aAnimated
{
	if (!disappearsUnderPushed) {
    // save if not cancelled before
    [self save];
    // Forget possibly left-over child editor links (should be nil, but just in case)
    self.currentChildDetailViewController = nil;
  	// let descendants know
    [self detailViewWillClose:aAnimated];
  	// view will disappear definitely, disable editors
    self.active = NO; // deactivate now
  }
  [super viewWillDisappear:aAnimated];
}


- (void)viewDidDisappear:(BOOL)aAnimated
{
	if (!disappearsUnderPushed || !hasAppeared) {
    // Note: if we see a disappear while not hasAppeared, this apparently means that the view stack is being
    //       emptied without re-showing views that are under pushed views, so we still need to do cleanup.
    // Deactivate and forget all content (needed HERE because otherwise we'll get saved when detail view is
    // re-opened with a new object, which can be the wrong thing)
    self.active = NO;
  }
  if (!disappearsUnderPushed) {
    hasAppeared = NO;
    // inform parent
    if (self.parentDetailViewController) {
      [self.parentDetailViewController childDetailEditingDoneWithCancel:cancelled];
    }
    // let descendants know
    [self detailViewDidClose:aAnimated];
    // call user handler for end-of-editing
    if (self.detailDidCloseHandler) {
      detailDidCloseHandler(self,cancelled);
    }
    // unload the table data such that cells are deallocated and release their possible hold on me
    // (mostly through handler blocks)
    self.active = NO;
    // apparently, we got dismissed (might be set long before here, but if not, now it's certain)
    dismissed = YES;
    dismissing = NO;
  }
  [super viewDidDisappear:aAnimated];
}


- (void)detailViewWillOpen:(BOOL)aAnimated
{
  // Nop in base class
}

- (void)detailViewWillClose:(BOOL)aAnimated
{
  // Nop in base class
}


- (void)detailViewDidClose:(BOOL)aAnimated
{
  // Nop in base class
}




#pragma mark - presentation and navigation

@synthesize navigationMode;

- (void)setNavigationMode:(ZDetailNavigationMode)aNavigationMode
{
  if (aNavigationMode!=navigationMode) {
    navigationMode = aNavigationMode;
    [self updateNavigationButtonsAnimated:NO];
  }
}

@synthesize detailsButtonTitle;

- (NSString *)detailsButtonTitle
{
  // return specific text if any
  if (detailsButtonTitle) return detailsButtonTitle;
  // return sensible default instead
  return ZLocalizedStringWithDefault(@"ZDetailButtonTitle", @"Details");
}

- (void)setDetailsButtonTitle:(NSString *)aDetailsButtonTitle
{
  if (!samePropertyString(&aDetailsButtonTitle, detailsButtonTitle)) {
    detailsButtonTitle = aDetailsButtonTitle;
    [self updateNavigationButtonsAnimated:NO];
  }
}



- (UIPopoverController *)popoverControllerForPresentation
{
  // special case, create popover
  popoverWrapper = [[UIPopoverController alloc] initWithContentViewController:[self viewControllerForModalPresentation]];
  return popoverWrapper;
}



- (UIViewController *)viewControllerForModalPresentation
{
	// need to wrap in a navigation controller of my own
  modalViewWrapper = [[ZModalViewWrapper alloc] initWithRootViewController:self];
  modalViewWrapper.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  // inherit styles
  modalViewWrapper.modalTransitionStyle = self.modalTransitionStyle;
  modalViewWrapper.modalPresentationStyle = self.modalPresentationStyle;
  modalViewWrapper.modalInPopover = self.modalInPopover;
  // return the wrapper
  return modalViewWrapper;
}


- (void)pushViewControllerForDetail:(UIViewController *)aViewController animated:(BOOL)aAnimated
{
  disappearsUnderPushed = YES;
  // defocus edit fields
  [self defocus];
  // inherit default content size for popovers
  if (self.navigationController) {
    aViewController.contentSizeForViewInPopover = self.navigationController.contentSizeForViewInPopover;
  }
  // extras for ZDetailViewControllers
  if ([aViewController conformsToProtocol:@protocol(ZDetailViewController)]) {
    // make myself the parent of this controller
    ((id<ZDetailViewController>)aViewController).parentDetailViewController = self; // weak
    // remember opened child
    self.currentChildDetailViewController = (id<ZDetailViewController>)aViewController; // strong
  }
  [self.navigationController pushViewController:aViewController animated:YES];
}



// dismiss myself - save if selected. Returns NO if dismissal is not possible (save throws exception, validation error usually)
- (BOOL)dismissDetailViewWithSave:(BOOL)aWithSave
{
  // Protect against dismissing more than once
  if (!dismissed && !dismissing) {
    // save or cancel
    dismissing = YES;
    if (!aWithSave) {
      // cancel
      [self cancel];
    }
    else {
      // validate
      NSMutableArray *errors = nil;
      if ([self validatesWithErrors:&errors]) {
        // ok, save
        [self save];
      }
      else {
        // validation error, can't save
        #warning "%%% Simple Alert only for now"
        NSMutableString *errMsg = [NSMutableString string];
        for (NSError *err in errors) {
          if (errMsg.length>0) [errMsg appendString:@"\n"];
          [errMsg appendString:err.localizedDescription];
        }
        // show alert
        UIAlertView *alert = [[UIAlertView alloc]
          initWithTitle:@"Cannot save"
          message:errMsg
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil
        ];
        [alert show];
        // cannot dismiss!
        dismissing = NO; // not dismissing any more, but still not dismissed
        return NO;           
      }
      // save successful, dismissed, disconnect cells
      self.active = NO;
    }
    // allowed, block further attempts to do it again
    dismissing = NO; // dismissing done
    dismissed = YES;    
    @try {
      if (popoverWrapper) {
        // dismiss popover
        [popoverWrapper dismissPopoverAnimated:YES];
      }
      else if (modalViewWrapper) {
        // was modally presented, dismiss it
        [self.parentViewController dismissModalViewControllerAnimated:YES];
      }
      else {
        // assume part of a navigation stack, pop it
        [self.navigationController popViewControllerAnimated:YES];
      }
    }
    @catch (NSException *exception) {
      // swallow exceptions that may happen - readyForDismissal should handle validation and alert users beforehand!
      NSLog(@"Exception dismissing %@ : %@",self.description, exception.description);
    }
  }
  // dismissed
  return YES;
}



// dismiss entire open stack, and then myself
- (void)dismissDetailStack
{
  #warning "%%% needs work"
  // close stack on top of me
  [self.navigationController popToViewController:self animated:NO];
  // ...and myself
  [self dismissDetailViewWithSave:NO];
}


// root detail view controller
- (id<ZDetailViewController>)rootDetailViewController
{
  id<ZDetailViewController> dvc = self; // start at myself
  while (dvc.parentDetailViewController!=nil) {
    id dvcp = dvc.parentDetailViewController;
    if (dvcp && [dvcp conformsToProtocol:@protocol(ZDetailViewController)]) {
      dvc = (id<ZDetailViewController>)dvcp;
    }
  }
  return dvc;
}


- (void)prepareForPossibleTermination
{
  [self save];
}



#pragma mark - ZDetailViewParent protocol


// should be called by child detail editor when editing completes
- (void)childDetailEditingDoneWithCancel:(BOOL)aCancelled
{
  self.currentChildDetailViewController = nil; // forget it
  // re-evaluate visibilities of cells
  [self updateVisibilitiesAnimated:YES];
}






@end