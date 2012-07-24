//
//  ZDetailTableViewController.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailTableViewController.h"

#import "ZOrientation.h"


#pragma mark - internal Helper classes declarations

@interface ZModalViewWrapper : UINavigationController

@end


@interface ZDetailViewSection : NSObject
{
  NSMutableArray *cells;
	id titleTextOrView;
  NSUInteger overallSectionIndex;
}
@property(readonly) NSMutableArray *cells;
@property(assign) NSUInteger overallSectionIndex;
@property(retain,nonatomic) id titleTextOrView;
- (id)initFromTemplate:(ZDetailViewSection *)aDetailViewSection;
@end // ZDetailViewSection


@interface ZDetailViewCellHolder : NSObject
{
  UITableViewCell *cell;
}
@property(readonly) UITableViewCell *cell;
@property(assign) NSUInteger overallRowIndex;
@property(assign) NSUInteger neededGroups;
@property(assign) BOOL cellEnabled; // cell enabled (usually via groups, but cells with no group are standalone)

- (BOOL)nowVisibleInMode:(ZDetailDisplayMode)aMode; // true if cell should be visible in the passed mode
- (id)initWithCell:(UITableViewCell *)aCell neededGroups:(NSUInteger)aNeededGroups;

@end // ZDetailViewCellHolder


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


@implementation ZDetailViewSection

@synthesize cells,titleTextOrView,overallSectionIndex;

- (id)init
{
	if ((self = [super init])) {
    titleTextOrView = nil;
    cells = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initFromTemplate:(ZDetailViewSection *)aDetailViewSection;
{
	if ([self init]) {
  	titleTextOrView = [aDetailViewSection.titleTextOrView retain];
    overallSectionIndex = aDetailViewSection.overallSectionIndex;
  }
  return self;
}


- (void)dealloc
{
	[cells release];
  [titleTextOrView release];
  // done
  [super dealloc];
}

@end // ZDetailViewSection



@implementation ZDetailViewCellHolder

@synthesize cell,neededGroups,cellEnabled,overallRowIndex;

- (id)initWithCell:(UITableViewCell *)aCell neededGroups:(NSUInteger)aNeededGroups
{
	if ((self = [super init])) {
  	cell = [aCell retain];
    neededGroups = aNeededGroups;
    // these need to be updated later
    overallRowIndex = 0;
    cellEnabled = NO;
  }
  return self;
}


- (void)dealloc
{
	[cell release];
  // done
  [super dealloc];
}


// true if cell should be visible in the passed mode
- (BOOL)nowVisibleInMode:(ZDetailDisplayMode)aMode
{
  // cellEnabled determines basic visibility
	BOOL vis = cellEnabled;
  // additionally, cell itself might want to show or not depending on displayMode
  // and other properties
  if ([cell conformsToProtocol:@protocol(ZDetailViewCell)]) {
    // not just a ordinary cell, but one of our own, ask for visibility
    vis = [(id<ZDetailViewCell>)cell nowVisibleInMode:aMode];
  }
  return vis;
}

@end // ZDetailViewCellHolder



#pragma mark - ZDetailTableViewController private (class extension)

@interface ZDetailTableViewController ( /* class extension */ )
{
  // controller level value connectors
  NSMutableArray *valueConnectors;
  // all available table sections, including all available cells, each consisting of a DetailViewCellHolders
  NSMutableArray *allSectionsAndCells;
	// set of enabled groups (by number as NSNumbers)
  BOOL cellEnabledDirty; // enabled states of cells is dirty (groups need to be checked)
  // current view of the table
  BOOL currentSectionsAndCellsDirty;
  NSMutableArray *currentSectionsAndCells;
  // if set, updateData was called at least once already
  BOOL contentLoaded;
  // input view management 
  CGRect editRect; // navigation controller view coordinates of where next edit area is (needed to move it in view when input views show)
  CGSize inputViewSize;
  CGFloat topOfInputView; // if >=0, keyboard or custom input view is up and inputViewSize valid
  // auto tap cell
  id<ZDetailViewCell> autoTapCell;
  // cause for view to disappear
  BOOL disappearsUnderPushed;
  // protection flag agains dismissing more than once
  BOOL dismissed; // set when view has been completely and successfully dismissed
  BOOL dismissing; // dismissing in process, but save exception could block it
  // number of cells that have requested but not yet released the current input view
  NSInteger customInputViewUsers;
  // set if editor is visible (has appeared)
  BOOL hasAppeared;
  // set if editor was dismissed with cancel
  BOOL cancelled;
  // temporary for constructing sections
  ZDetailViewSection *sectionToAdd;
  // for modally displaying the detail view (instead of pushing on existing navigation stack)
  UINavigationController *modalViewWrapper;
}
@property (retain, nonatomic) UITableViewCell *cellThatOpenedChildDetail;
// private methods
- (void)addDetailCell:(UITableViewCell *)aCell neededGroups:(NSUInteger)aNeededGroups nowEnabled:(BOOL)aNowEnabled;
- (void)updateCellsDisplayMode:(ZDetailDisplayMode)aMode animated:(BOOL)aAnimated;
- (void)updateNavigationButtonsAnimated:(BOOL)aAnimated;
- (void)updateTableRepresentationWithAdjust:(BOOL)aWithTableAdjust animated:(BOOL)aAnimated;
- (void)defocusAllBut:(id)aFocusedCell;
- (NSIndexPath *)indexPathForCell:(UITableViewCell *)aCell;
@end


@implementation ZDetailTableViewController


#pragma mark - initialisation and cleanup

#define SECTION_HEADER_HEIGHT 8
#define SECTION_FOOTER_HEIGHT 3

@synthesize parentDetailViewController;
@synthesize currentChildDetailViewController;
@synthesize cellThatOpenedChildDetail;

- (void)internalInit
{
  // no referenced objects
  parentDetailViewController = nil;
  currentChildDetailViewController = nil;
  cellThatOpenedChildDetail = nil;
  valueConnectors = [[NSMutableArray alloc] initWithCapacity:3];
	// none configured yet
  allSectionsAndCells = nil;
  // only group 0 is enabled
  cellEnabledDirty = YES;
 	enabledGroups = 0; 
  // table not yet represented
  currentSectionsAndCells = nil;
  currentSectionsAndCellsDirty = YES;
  // default mode: editing basics, scroll enabled
  displayMode = ZDetailDisplayModeBasics+ZDetailDisplayModeEditing; // no details, enabled for editing
  navigationMode = ZDetailNavigationModeLeftButtonAuto; // no extra buttons, but left button automatically set to "done" for modally presented details
  scrollEnabled = YES;
  autoStartEditing = NO;
  // internal flags
  contentLoaded = NO;
  cellsActive = NO;
  // flag to detect if view disappears because another one is pushed on top (no save then)
  disappearsUnderPushed = NO;
  hasAppeared = NO;
  dismissed = NO;
  dismissing = NO;
  cancelled = NO;
  // section construction
  sectionToAdd = nil;
  defaultCellStyle = ZDetailViewCellStyleDefault;
  // not modally displayed
  modalViewWrapper = nil;
  // no custom input view
  customInputView = nil;
  customInputViewUsers = 0;
  // input view control
  topOfInputView = -1;
  inputViewSize = CGSizeZero;
  editRect = CGRectNull;
  // handlers
  cellSetupHandler = nil;
  buildDetailContentHandler = nil;
  detailDidCloseHandler = nil;
  // cell that needs automatic tap on viewDidAppear
  autoTapCell = nil;
  // popover display default size
  self.contentSizeForViewInPopover = CGSizeMake(320, 500);
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


// convenience initializer for default ZDetailTableView which is
// fullscreen detail table view
- (id)init
{
  return [self initWithNibName:nil bundle:nil];
}


+ (id)controllerWithTitle:(NSString *)aTitle
{
  ZDetailTableViewController *dvc = [[[self alloc] init] autorelease];
  dvc.title = aTitle;
  dvc.navigationItem.title = aTitle;
  return dvc;
}



// load view
- (void)loadView
{
  // if initialized w/o NIB, autocreate and connect fullscreen table view
  if (self.nibName==nil && self.detailTableView==nil) {
    // no nib AND detail table view not provided by a subclassed loadView already
    self.detailTableView = [[[UITableView alloc]
      initWithFrame:[[UIScreen mainScreen] applicationFrame]
      style:UITableViewStyleGrouped
    ] autorelease];
    // this is the one and only view
    self.view = detailTableView;
  }
  else {
    // expect nib to contain a UITableView and connect it into self.detailTableView
    // (using standard search path (loading from nib as specified in self.nibName))
    [super loadView];
  }
}


@synthesize detailTableView;

- (void)setDetailTableView:(UITableView *)aDetailTableView
{
  if (aDetailTableView!=detailTableView) {
    [detailTableView removeFromSuperview];
    [detailTableView release];
    detailTableView = [aDetailTableView retain];
    // I need to be datasource and delegate
    detailTableView.delegate = (id)self;
    detailTableView.dataSource = (id)self;
    // inherit some settings
    detailTableView.scrollEnabled = scrollEnabled;
  }
}



- (void) dealloc
{
  self.cellsActive = NO;
  self.currentChildDetailViewController = nil;
  self.cellThatOpenedChildDetail = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  // release handlers, important, as these may retain other objects!
  [buildDetailContentHandler release];
  [detailDidCloseHandler release];
  [cellSetupHandler release];
  // release other objects
  [valueConnectors release];
	[detailTableView release];
  [currentSectionsAndCells release];
  [allSectionsAndCells release];
  [sectionToAdd release];
  [modalViewWrapper release];
  // done
  [super dealloc];
}


#if 0

static NSInteger numObjs = 0;

+ (id)alloc
{
  numObjs++;
  DBGNSLOG(@"++++ [retain=1, objs=%d] %@", numObjs, [self description]);
  return [super alloc];
}


- (id)retain
{
  DBGNSLOG(@"++++ [retain=%d, objs=%d] %@", [self retainCount]+1, numObjs, [self description]);
  return [super retain];
}


- (oneway void)release
{
  if ([self retainCount]==1) numObjs--; // will go to 0 and get deleted now
  DBGNSLOG(@"---- [retain=%d, objs=%d] %@", [self retainCount]-1, numObjs, [self description]);
  [super release];
}

#endif


#pragma mark - building the contents

@synthesize buildDetailContentHandler;


// This can be overridden in subclasses to create content
- (BOOL)buildDetailContent
{
  BOOL built = NO;
  if (self.buildDetailContentHandler) {
    // if we have a build handler, call it
    built = buildDetailContentHandler(self);
  }
  return built;
}



#pragma mark - adding editing sections and cells



- (void)startSectionWithText:(NSString *)aText asTitle:(BOOL)aAsTitle
{
	[self startSection];
	if (aAsTitle) {
  	// simple title text
  	sectionToAdd.titleTextOrView = aText;
  }
  else {
  	// as description text view
    CGRect hr = [detailTableView rectForHeaderInSection:0];
    UIView *sectionHdrView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, hr.size.width, 120)];
    CGFloat inset = hr.size.width>480 ? 45+10 : 10+10; // %%% hardcoded insets, iPad has larger one. +10 is to match extra title text inset
    UILabel *biglbl = [[UILabel alloc] initWithFrame:CGRectMake(inset, 5, hr.size.width-inset*2, 110)];
    biglbl.text = aText;
    biglbl.numberOfLines = 0;
    biglbl.font = [UIFont systemFontOfSize:14];
    biglbl.textColor = [UIColor darkGrayColor];
    biglbl.shadowColor = [UIColor whiteColor];
    biglbl.shadowOffset = CGSizeMake(0, 1);
    biglbl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    // adjust sizes
    // - adjust frame of label to fit all text
    CGRect f = biglbl.frame;
    f.size = [aText sizeWithFont:biglbl.font constrainedToSize:CGSizeMake(f.size.width,1000) lineBreakMode:UILineBreakModeWordWrap];
    biglbl.frame = f;
    // - adjust frame of section header view to fit label
    sectionHdrView.frame = CGRectMake(0, 0, hr.size.width, f.size.height+10);
    // add views
    [sectionHdrView addSubview:biglbl];
    sectionToAdd.titleTextOrView = sectionHdrView;
    [sectionHdrView release];
    [biglbl release];
  }
}


- (void)startSection
{
	if (sectionToAdd) [sectionToAdd release];
  sectionToAdd = [[ZDetailViewSection alloc] init];
  sectionToAdd.titleTextOrView = nil;
}


- (void)endSection
{
	if (!allSectionsAndCells)
  	allSectionsAndCells = [[NSMutableArray alloc] init];
  [allSectionsAndCells addObject:sectionToAdd];
  [sectionToAdd release];
	sectionToAdd = nil;	
  currentSectionsAndCellsDirty = YES;
}


- (void)sortSectionBy:(NSString *)aKey ascending:(BOOL)aAscending
{
  [sectionToAdd.cells sortUsingComparator:
    ^NSComparisonResult(id ch1, id ch2) {
      ZDetailViewCellHolder *hch1 = aAscending ? ch1 : ch2;
      ZDetailViewCellHolder *hch2 = aAscending ? ch2 : ch1;
      return [[hch1.cell valueForKey:aKey] compare:[hch2.cell valueForKey:aKey]];
    }
  ];
}


- (void)endSectionAndSortBy:(NSString *)aKey ascending:(BOOL)aAscending
{
  // sort
  [self sortSectionBy:aKey ascending:aAscending];
  // now add section to array
  [self endSection];
}




// Add a new detail cell (private methods, basis for the the nicer APIs below)
- (void)addDetailCell:(UITableViewCell *)aCell neededGroups:(NSUInteger)aNeededGroups nowEnabled:(BOOL)aNowEnabled
{
  NSAssert(sectionToAdd!=nil,@"Start a section before adding cells!");
	// create cellholder
  ZDetailViewCellHolder *ch = [[ZDetailViewCellHolder alloc] initWithCell:aCell neededGroups:aNeededGroups];
  ch.cellEnabled = aNowEnabled;
  [sectionToAdd.cells addObject:ch];
  [ch release];
  // configure if it is a ZDetailViewCell
  if ([aCell conformsToProtocol:@protocol(ZDetailViewCell)]) {
    id<ZDetailViewCell> dvc = (id<ZDetailViewCell>)aCell;
    // configure
    dvc.active = NO; // not yet active
    dvc.cellOwner = self; // weak link to owner
    [dvc setDisplayMode:self.displayMode animated:NO]; // same mode as entire table has
  }
}


- (void)addDetailCell:(UITableViewCell *)aCell enabled:(BOOL)aEnabled
{
	[self addDetailCell:aCell neededGroups:0 nowEnabled:aEnabled];  
}


- (void)addDetailCell:(UITableViewCell *)aCell
{
	[self addDetailCell:aCell enabled:YES];
}


@synthesize defaultCellStyle;
@synthesize cellSetupHandler;


- (id)detailCell:(Class)aClass withStyle:(ZDetailViewCellStyle)aStyle neededGroups:(NSUInteger)aNeededGroups nowEnabled:(BOOL)aNowEnabled
{
  NSAssert([aClass isSubclassOfClass:[UITableViewCell class]], @"cells must be UITableViewCell descendants");
  UITableViewCell *newCell = [[aClass alloc] initWithStyle:aStyle reuseIdentifier:nil];
  [self addDetailCell:newCell neededGroups:aNeededGroups nowEnabled:aNowEnabled];
  // apply the default configurator
  if (cellSetupHandler) {
    cellSetupHandler(self,newCell);
  }
  // return the cell for further configuration
  return [newCell autorelease];
}


- (id)detailCell:(Class)aClass neededGroups:(NSUInteger)aNeededGroups
{
  return [self detailCell:aClass withStyle:self.defaultCellStyle neededGroups:aNeededGroups nowEnabled:NO];
}


- (id)detailCell:(Class)aClass enabled:(BOOL)aEnabled
{
  return [self detailCell:aClass withStyle:self.defaultCellStyle neededGroups:0 nowEnabled:aEnabled];
}


- (id)detailCell:(Class)aClass withStyle:(ZDetailViewCellStyle)aStyle
{
  return [self detailCell:aClass withStyle:aStyle neededGroups:0 nowEnabled:NO];
}


- (id)detailCell:(Class)aClass
{
  return [self detailCell:aClass enabled:YES];
}


#pragma mark - controller level value connectors


// for subclasses to register connectors
- (ZDetailValueConnector *)registerConnector:(ZDetailValueConnector *)aConnector
{
  [valueConnectors addObject:aConnector];
  return aConnector;
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
    [self updateCellVisibilitiesAnimated:aAnimated];
    // - update cell modes
    [self updateCellsDisplayMode:displayMode animated:aAnimated];
    // - update the editing button (if any)
    [self updateNavigationButtonsAnimated:aAnimated];
  }
}

@synthesize autoStartEditing;

@synthesize scrollEnabled;

- (void)setScrollEnabled:(BOOL)aScrollEnabled
{
  scrollEnabled = aScrollEnabled;
  if (detailTableView) {
    detailTableView.scrollEnabled = scrollEnabled;
  }
}



- (void)setEditing:(BOOL)aEditing animated:(BOOL)aAnimated
{
  [super setEditing:aEditing animated:aAnimated];
  if (detailTableView) {
    [detailTableView setEditing:aEditing animated:aAnimated];
  }
}




#pragma mark - detailview data connection control


@synthesize cellsActive;

- (void)setCellsActive:(BOOL)aCellsActive
{
  if (aCellsActive!=cellsActive) {
    cellsActive = aCellsActive;
    // controller level value connectors
    for (ZDetailValueConnector *connector in valueConnectors) {
      connector.active = aCellsActive;
    }    
    // cells
    for (ZDetailViewSection *section in allSectionsAndCells) {
      for (ZDetailViewCellHolder *dvch in section.cells) {
        // set active/inactive state
        if ([dvch.cell conformsToProtocol:@protocol(ZDetailViewCell)]) {
          [(id<ZDetailViewCell>)dvch.cell setActive:cellsActive];
        }
      }
    }
  }
}


- (void)cancel
{
  // mark cancelled
  cancelled = YES;
  // deactivate the cell connections (prevents further saves)
  self.cellsActive = NO;
}



- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP
{
  BOOL validates = YES;
  if (self.cellsActive) {
    // collect validation status from all cells
    for (ZDetailViewSection *section in allSectionsAndCells) {
      for (ZDetailViewCellHolder *dvch in section.cells) {
        if ([dvch.cell conformsToProtocol:@protocol(ZDetailViewCell)]) {
          validates = validates && [(id<ZDetailViewCell>)dvch.cell validatesWithErrors:aErrorsP];
        }
      }
    }
    // controller level value connectors
    for (ZDetailValueConnector *connector in valueConnectors) {
      validates = validates && [connector validatesWithErrors:aErrorsP];
    }
  }
  return validates;
}



- (void)save
{
	[self defocusAllBut:nil]; // defocus all cells
  if (self.cellsActive) {
    // let all cells save their data first (controller level values might depend)
    for (ZDetailViewSection *section in allSectionsAndCells) {
      for (ZDetailViewCellHolder *dvch in section.cells) {
        if ([dvch.cell conformsToProtocol:@protocol(ZDetailViewCell)]) {
          [(id<ZDetailViewCell>)dvch.cell saveCell];
        }
      }
    }
    // let controller level value connectors save now (might depend on cells)
    for (ZDetailValueConnector *connector in valueConnectors) {
      [connector saveValue];
    }
    // mark saved
    cancelled = NO;
  }
  // subclass might save the master object after calling this super
}


- (void)revert
{
  // subclass might reload the master object before calling this super,
  // (but note that autoupdating connections might get activated)
	[self defocusAllBut:nil]; // defocus all cells
  if (self.cellsActive) {
    // let all cells reload their data
    for (ZDetailViewSection *section in allSectionsAndCells) {
      for (ZDetailViewCellHolder *dvch in section.cells) {
        if ([dvch.cell conformsToProtocol:@protocol(ZDetailViewCell)])
          [(id<ZDetailViewCell>)dvch.cell loadCell]; // reload data into cell
      }
    }
    // let controller level value connectors revert
    for (ZDetailValueConnector *connector in valueConnectors) {
      [connector loadValue];
    }
  }
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
    [detailsButtonTitle release];
    detailsButtonTitle = [aDetailsButtonTitle retain];
    [self updateNavigationButtonsAnimated:NO];
  }
}




- (UIViewController *)viewControllerForModalPresentation
{
	// need to wrap in a navigation controller of my own
  [modalViewWrapper release];
  modalViewWrapper = [[ZModalViewWrapper alloc] initWithRootViewController:self];
  modalViewWrapper.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  // done button needed
  if (self.navigationMode & ZDetailNavigationModeLeftButtonAuto) {
    // nothing specified, make sure we can leave the modal
    self.navigationMode = self.navigationMode | ZDetailNavigationModeLeftButtonDone; 
  }
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
  [self defocusAllBut:nil];
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
        [alert release];
        // cannot dismiss!
        dismissing = NO; // not dismissing any more, but still not dismissed
        return NO;           
      }
      // save successful, dismissed, disconnect cells
      self.cellsActive = NO;
    }
    // allowed, block further attempts to do it again
    dismissing = NO; // dismissing done
    dismissed = YES;    
    @try {
      if (modalViewWrapper) {
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
  if (self.cellThatOpenedChildDetail) {
    // inform the cell that the editor has closed
    if ([self.cellThatOpenedChildDetail conformsToProtocol:@protocol(ZDetailViewCell)]) {
      [(id<ZDetailViewCell>)(self.cellThatOpenedChildDetail) editorFinishedWithCancel:aCancelled];
    }
    // done
    self.cellThatOpenedChildDetail = nil;
  }
  // re-evaluate visibilities of cells
  [self updateCellVisibilitiesAnimated:YES];
}


#pragma mark - ZDetailCellOwner protocol


// called by cells or by table view delegate methods to perform actions
- (void)cellTapped:(UITableViewCell *)aCell inAccessory:(BOOL)aInAccessory
{
  if ([aCell conformsToProtocol:@protocol(ZDetailViewCell)]) {
    id<ZDetailViewCell> dvc = (id<ZDetailViewCell>)aCell;
    // let cell check for a non-default action before trying to open standard editor
    BOOL handled = [dvc handleTapInAccessory:aInAccessory];
    if (!handled) {
      // ask cell for editor to push to handle the tap
      UIViewController *editController = [dvc editorForTapInAccessory:aInAccessory];
      if (editController) {
        // remember cell that caused opening a detail editor
        self.cellThatOpenedChildDetail = aCell;
        // open the detail
        [self pushViewControllerForDetail:editController animated:YES];
      }
      else {
        // ask cell to begin in-cell editing (and claim focus!)
        handled = [dvc beginEditing];
      }
      [self defocusAllBut:aCell]; // defocus all other cells
    }
  }
}





// needed by some editor cells to block scrolling during certain periods as otherwise
// touch tracking does not work
- (void)tempBlockScrolling:(BOOL)aBlockScrolling
{
  self.detailTableView.scrollEnabled = !aBlockScrolling && self.scrollEnabled;
}



// ask for owner refresh (e.g. for dynamic cell heights)
- (void)setNeedsReloadingCell:(UITableViewCell *)aCell animated:(BOOL)aAnimated
{
  if (aCell==nil || !aAnimated) {
    // refresh entire table
    [self.detailTableView reloadData];	
  }
  else {
    // refresh single cell, possibly animated
    [self.detailTableView beginUpdates];
    [self.detailTableView endUpdates];
  }
}


// start editing in next cell (pass nil to start editing in first cell that can edit)
- (void)beginEditingInNextCellAfter:(UITableViewCell *)aCell
{
  BOOL startCellFound = aCell==nil; // found already when no start cell passed
  for (ZDetailViewSection *section in allSectionsAndCells) {
    for (ZDetailViewCellHolder *dvch in section.cells) {
      if (startCellFound) {
        // check if we can start editing here
        if (
          [dvch nowVisibleInMode:self.displayMode] &&
          [dvch.cell conformsToProtocol:@protocol(ZDetailViewCell)]
        ) {
          id<ZDetailViewCell> c = (id<ZDetailViewCell>)dvch.cell;
          // try starting editing here
          if ([c beginEditing]) {
            // visible, and successfully started editing
            if ([c keepSelected]) {
              // - get indexpath
              NSIndexPath *ip = [self.detailTableView indexPathForCell:dvch.cell];
              // - select it
              [self.detailTableView selectRowAtIndexPath:ip animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
            return; // done
          }
        }
      }
      else {
        // start cell not yet found, check if this one is it
        if (dvch.cell==aCell)
          startCellFound = YES; // from now on, next cell can be one that starts editing
      }
    }
  }  
}


/* %%% should no longer be needed. If cells need to do table level actions, this
   should be done in handler blocks, in the table level source code.

// entire table should be rebuilt (called from cells)
- (void)tableNeedsRebuild
{
  // have the list of cells reconstructed
  [self updateData];
}

*/



#pragma mark - subclassable notification methods


// called before detail view opens
- (void)detailViewWillOpen:(BOOL)aAnimated
{
  // NOP in base class
}


// called before detail view closes
- (void)detailViewWillClose:(BOOL)aAnimated
{
  // NOP in base class
}


// called after detail view has closed (already unloaded data etc.)
- (void)detailViewDidClose:(BOOL)aAnimated
{
  // NOP in base class
}



#pragma mark - Table view updates management

@synthesize enabledGroups;


- (void)setEnabledGroups:(NSUInteger)aEnabledGroups
{
  if (aEnabledGroups!=enabledGroups) {
    enabledGroups = aEnabledGroups;
    cellEnabledDirty = YES;
    currentSectionsAndCellsDirty = YES;
  }
}


// enable or disable groups of cells to show
- (void)changeGroups:(NSUInteger)aGroupMask toVisible:(BOOL)aVisible
{
  NSUInteger newMask = self.enabledGroups;
	if (aVisible) {
    newMask |= aGroupMask;
  }
  else {
    newMask &= ~aGroupMask;
  }
  self.enabledGroups = newMask;
}
  
  
- (void)resetGroups
{
  self.enabledGroups = 0;
  // rebuild anyway
	cellEnabledDirty = YES;
}



// convenience method to show/hide members of a group, e.g. in a valueChangeHandler of a switch cell etc.)
- (void)changeDisplayedGroups:(NSUInteger)aGroupMask toVisible:(BOOL)aVisible animated:(BOOL)aAnimated
{
  [self changeGroups:aGroupMask toVisible:aVisible];
  [self applyGroupChangesAnimated:aAnimated];
}



- (void)applyGroupChangesAnimated:(BOOL)aAnimated
{
  // prevent updating table when we are still building contents (i.e. maybe not all dependent cells are already loaded)
  if (!sectionToAdd) {
	  [self updateTableRepresentationWithAdjust:YES animated:aAnimated];
  }
}



// can be called to force visibility update when based on empty/nonempty state
- (void)updateCellVisibilitiesAnimated:(BOOL)aAnimated
{
  currentSectionsAndCellsDirty = YES; // check cells, as empty status might have changed
  [self updateTableRepresentationWithAdjust:aAnimated animated:aAnimated];
  if (!aAnimated) [self.detailTableView reloadData];
}



// Internal: update cellEnabled state of cells according to groups
- (void)updateCellEnabledStates
{
  for (ZDetailViewSection *section in allSectionsAndCells) {
    for (ZDetailViewCellHolder *cellholder in section.cells) {
      // for cells not assigned to any group, enabled state is independent and must not be modified here 
      if (cellholder.neededGroups) {
        // cell needs least one group to be enabled
        BOOL en = (cellholder.neededGroups & self.enabledGroups) == cellholder.neededGroups;
        if (en!=cellholder.cellEnabled) {
          // this is a change
          cellholder.cellEnabled = en;
          currentSectionsAndCellsDirty = YES;
        }
      }
		}  
  }
	cellEnabledDirty = NO;
}


#define TRACK_ADJUSTS 0

#if TRACK_ADJUSTS
#define TDBGNSLOG(...) DBGNSLOG(__VA_ARGS__)
#else
#define TDBGNSLOG(...)
#endif



// Internal: update current sections and cells to show according to nowVisible status
- (void)updateTableRepresentationWithAdjust:(BOOL)aWithTableAdjust animated:(BOOL)aAnimated
{
	// check if we need to update cellEnabled first
  if (cellEnabledDirty) {
  	[self updateCellEnabledStates];
  }
  if (currentSectionsAndCellsDirty) {
    // create current cells array
    if (!currentSectionsAndCells)
      currentSectionsAndCells = [[NSMutableArray alloc] init];
    // animation to use
    UITableViewRowAnimation rowAnimation = aAnimated ? UITableViewRowAnimationTop : UITableViewRowAnimationNone;
    // iterate through all sections
    NSUInteger sidx_src = 0; // section source index
    NSUInteger sidx_target = 0; // section target index
    NSUInteger sectionCorr = 0; // section index correction for table adjustment operations
    // run through our inventary and calculate delta to what we currently display
    for (ZDetailViewSection *section in allSectionsAndCells) {
      // make sure index is ok
      section.overallSectionIndex = sidx_src;
      // check if this section is visible at all
      BOOL sectionVisible = [section.cells count]==0; // fully empty sections are always visible (usually these are pure title-only sections)
      for (ZDetailViewCellHolder *cellholder in section.cells) {
        if ([cellholder nowVisibleInMode:self.displayMode]) {
          sectionVisible = YES;
          break;
        }   
      }
      // get possibly corresponding old section
      ZDetailViewSection *oldSection = nil;
      if ([currentSectionsAndCells count]>sidx_target)
        oldSection = [currentSectionsAndCells objectAtIndex:sidx_target];
      // check if source and target sections correspond
      if (oldSection && oldSection.overallSectionIndex!=sidx_src)
        oldSection = nil;
      if (oldSection) {
        // we had that same section visible before
        if (!sectionVisible) {
          // it has to disappear now
          [currentSectionsAndCells removeObjectAtIndex:sidx_target];
          // from the table as well
          if (aWithTableAdjust) {
            // deletes are relative to the original table state, so apply index correction
            TDBGNSLOG(@"deleting section #%d",sidx_target);
            [detailTableView deleteSections:[NSIndexSet indexSetWithIndex:sidx_target] withRowAnimation:rowAnimation];
          }
          sectionCorr++; // further deletes in the table need to use one index higher than what is left in currentSectionsAndCells
        }
        else {
          // update cells in that section
          NSUInteger cidx_src = 0; // cell source index
          NSUInteger cidx_target = 0; // cell target index
          NSUInteger rowCorr = 0; // row index correction for table adjustment operations
          for (ZDetailViewCellHolder *cellholder in section.cells) {
          	TDBGNSLOG(@"Cell #%d in section #%d has nowVisible=%d, group=%d",cidx_src,section.overallSectionIndex,cellholder.nowVisible,cellholder.groupNumber);
            // make sure index is ok
            cellholder.overallRowIndex = cidx_src;
            // get possibly corresponding old cell
            ZDetailViewCellHolder *oldCellholder = nil;
            if ([oldSection.cells count]>cidx_target)
              oldCellholder = [oldSection.cells objectAtIndex:cidx_target];
            // check if source and target cells correspond
            if (oldCellholder && oldCellholder.overallRowIndex!=cidx_src)
              oldCellholder = nil;
            if (oldCellholder) {
              // corresponding row was shown in table before
              if (![cellholder nowVisibleInMode:self.displayMode]) {
                // but not any more - remove it
                [oldSection.cells removeObjectAtIndex:cidx_target];
                // from the table as well
                if (aWithTableAdjust) {
                  // deletes are relative to the original table state, so apply index correction
	                TDBGNSLOG(@"deleting row #%d in section #%d",cidx_target,sidx_target);
                  [detailTableView deleteRowsAtIndexPaths:
                  	//[NSArray arrayWithObject:[NSIndexPath indexPathForRow:cidx_target+rowCorr inSection:sidx_target+sectionCorr]]
                  	[NSArray arrayWithObject:[NSIndexPath indexPathForRow:cidx_target inSection:sidx_target]]
                    withRowAnimation:rowAnimation
                  ];
                }
                rowCorr++; // further deletes in the table need to use one index higher than what is left in currentSectionsAndCells              
              }
              else {
                // cell is and remains visible, just go to next one
                cidx_target++;
              }
            }  
            else {
              // row was not shown before, add it now
              if ([cellholder nowVisibleInMode:self.displayMode]) {
                [oldSection.cells insertObject:cellholder atIndex:cidx_target];
                // insert into the table as well
                if (aWithTableAdjust) {
                  // inserts are relative to state of table with already deleted rows, so it's just the new target index
                  TDBGNSLOG(@"inserting row #%d into section #%d",cidx_target,sidx_target);
                  [detailTableView insertRowsAtIndexPaths:
                    [NSArray arrayWithObject:[NSIndexPath indexPathForRow:cidx_target inSection:sidx_target]]
                    withRowAnimation:rowAnimation
                  ];
                }
	              cidx_target++;
              }
            }
            cidx_src++; // next source row
          }
          // updated this section, next target is next section
          sidx_target++;
        }
      }
      else {
        // no corresponding section existed before
        if (sectionVisible) {
          // it has to appear now, add empty copy of original section (no cells yet)
          ZDetailViewSection *newSection = [[ZDetailViewSection alloc] initFromTemplate:section];
          [currentSectionsAndCells insertObject:newSection atIndex:sidx_target];
          // add all the enabled cells
          NSUInteger cidx_src = 0; // cell source index
          for (ZDetailViewCellHolder *cellholder in section.cells) {
          	// assign the overall index (important for later diff checking)
          	cellholder.overallRowIndex = cidx_src++;
            // add cell if now visible
            if ([cellholder nowVisibleInMode:self.displayMode]) {
              // this cell is visible, add it to the section's cell array
              [newSection.cells addObject:cellholder];
            }
          }
          [newSection release];
          // insert section in the table as well
          if (aWithTableAdjust) {
            // inserts are relative to state of table with already deleted sections, so it's just the new target index
            TDBGNSLOG(@"inserting section #%d with %d cells",sidx_target,[newSection.cells count]);
            [detailTableView insertSections:[NSIndexSet indexSetWithIndex:sidx_target] withRowAnimation:rowAnimation];
          }
          // target next section
          sidx_target++;
        }
      }
      sidx_src++; // next section
    } // for all possible sections
    // updated now
    currentSectionsAndCellsDirty = NO;
  }
}



- (void)forgetTableData
{
	// empty arrays
  // - section array
	if (allSectionsAndCells) {
  	// first save to objects (unless already deactivated)
    [self save];
    self.cellsActive = NO; // deactivate all cells already to make no undisplayed one remains active
    // then remove
  	[allSectionsAndCells removeAllObjects];
    [allSectionsAndCells release];
    allSectionsAndCells = nil;
  }
  // - currently visible cells
  self.cellsActive = NO; // deactivate all cells again (in case we had no allSectionsAndCells above)
	if (currentSectionsAndCells) {
    // remove as well
  	[currentSectionsAndCells removeAllObjects];
    [currentSectionsAndCells release];
    currentSectionsAndCells = nil;
  }
}



- (void)unloadData
{
	// forget the data
	[self forgetTableData];
  // important to prevent tableview to try fetching cells that don't exist any more
  [detailTableView reloadData];
}


- (void)updateData
{
  // we're loading now, prevent later auto-loading again
  contentLoaded = YES;
	// set table options
  detailTableView.sectionHeaderHeight = SECTION_HEADER_HEIGHT;
  detailTableView.sectionFooterHeight = SECTION_FOOTER_HEIGHT;
	// prepare arrays
  // - clear if already existing
  [self forgetTableData]; // Note: deactivates cells in the process
  // - reset groups (do it before building content, as building content might already add/remove groups)
  [self resetGroups];
  autoTapCell = nil;
  // activate controller-level value connectors already here before building cells,
  // as these might be needed during build (will be done again at cellsActive)
  for (ZDetailValueConnector *connector in valueConnectors) {
    connector.active = YES;
  }  
  // Note: subclasses build the content here (by adding sections and cells)
 	BOOL built = [self buildDetailContent];
  NSAssert(built, @"detail content was not built");
  NSAssert(sectionToAdd==nil,@"unterminated section at end of build");
  // activate the cells, so they can check their values (for detecting empty values that might not need to be shown)
  self.cellsActive = YES; // activate them now  
  // create array of currently visible sections and cells
  [self updateTableRepresentationWithAdjust:NO animated:NO];
	// now reload data
  [detailTableView reloadData]; // have table show them
}



#pragma mark - private methods and properties


// get current indexPath for given cell (nil if cell is not currently visible)
- (NSIndexPath *)indexPathForCell:(UITableViewCell *)aCell
{
  NSUInteger sec = 0;
  NSUInteger row = 0;
  for (ZDetailViewSection *section in currentSectionsAndCells) {
    row = 0;
    for (ZDetailViewCellHolder *dvch in section.cells) {
    	if (dvch.cell==aCell) {
        // found cell return indexPath
        return [NSIndexPath indexPathForRow:row inSection:sec];
      }
      row++;
    }
    sec++;
  }
  return nil;
}



- (void)defocusAllBut:(id)aFocusedCell
{
  // TODO: there's a UIView method endEditing: which finds any first responder
  //   subview and have it resign first responder status (Dave's Tip 2011-07-14)
  //   Might be an option instead of this one
  for (ZDetailViewSection *section in allSectionsAndCells) {
    for (ZDetailViewCellHolder *dvch in section.cells) {
    	// defocus if it's not the specified cell
    	if (dvch.cell!=aFocusedCell && [dvch.cell conformsToProtocol:@protocol(ZDetailViewCell)])
      	[(id<ZDetailViewCell>)dvch.cell defocusCell];
    }
  }
}


// update cell display modes
- (void)updateCellsDisplayMode:(ZDetailDisplayMode)aMode animated:(BOOL)aAnimated
{
  for (ZDetailViewSection *section in allSectionsAndCells) {
    for (ZDetailViewCellHolder *dvch in section.cells) {
    	// set the new mode
      if ([dvch.cell conformsToProtocol:@protocol(ZDetailViewCell)]) {
        [(id<ZDetailViewCell>)dvch.cell setDisplayMode:aMode animated:aAnimated];
      }
    }
  }  
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
  if (navigationMode & ZDetailNavigationModeLeftButtonCancel) {
    // left side must be a cancel button
    leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonAction)];
  }
  else if (navigationMode & ZDetailNavigationModeLeftButtonDone) {
    // done button for root view controllers, saves content
    leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveButtonAction)];
  }
  else {
    // if it's a back button, intercept its action
    #warning "%%% tbd - intercept back button press"
  }
  [self.navigationItem setLeftBarButtonItem:[leftButton autorelease] animated:aAnimated];
  // Right button
  UIBarButtonItem *rightButton = nil;
  if (navigationMode & ZDetailNavigationModeRightButtonSave) {
    rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonAction)];
  }
  else if (navigationMode & ZDetailNavigationModeRightButtonEditViewing) {
    if (self.displayMode & ZDetailDisplayModeEditing) {
      // is editing, show "done"
      rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editDoneButtonAction)];
    }
    else {
      // is viewing, show "edit"
      rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editStartButtonAction)];
    }
  }
  else if (navigationMode & ZDetailNavigationModeRightButtonTableEditDone) {
    // use the standard editing button from UIViewController which is auto connected to the editing property
    rightButton = [self.editButtonItem retain]; // will be autoreleased below
  }
  else if (navigationMode & ZDetailNavigationModeRightButtonDetailsBasics) {
    if (self.displayMode & ZDetailDisplayModeDetails) {
      // is showing details, show "done"
      rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(detailsDoneButtonAction)];
    }
    else {
      // is showing basics, show "details"
      rightButton = [[UIBarButtonItem alloc] initWithTitle:detailsButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(detailsStartButtonAction)];
    }
  }
  [self.navigationItem setRightBarButtonItem:[rightButton autorelease] animated:aAnimated];
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
  // auto-load content if not already done so
  if (!contentLoaded) {
    // nothing has loaded the content so far, so let's do it automatically now
    [self updateData];
  }
  if (!disappearsUnderPushed) {
  	// was not only hidden under pushed detail
    // - forget possibly left-over child editor links (should be nil, but just in case)
    self.cellThatOpenedChildDetail = nil;
    self.currentChildDetailViewController = nil;
    cancelled = NO;
    dismissed = NO;
    // let subclasses know
    [self detailViewWillOpen:aAnimated];
  	@try {
      // appears new on top of stack: scroll to top
      [detailTableView scrollToRowAtIndexPath:
        [NSIndexPath indexPathForRow:0 inSection:0]
        atScrollPosition:UITableViewScrollPositionTop
        animated:NO
      ];
    }
    @catch (NSException *e) {
      DBGNSLOG(@"Detailview scroll exception: %@",[e description]);
    }
    // focus first editable field?
    if (autoStartEditing) {
      [self beginEditingInNextCellAfter:nil];
    }
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
  // install editing start notification handler
	[[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(editingInRect:)
    name:@"EditingInRect"
    object:nil
  ];
  // install keyboard hide/show handlers
	[[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(keyboardWillShow:)
    name:UIKeyboardWillShowNotification
    object:nil
  ];
	[[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(keyboardDidShow:)
    name:UIKeyboardDidShowNotification
    object:nil
  ];
	[[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(keyboardWillHide:)
    name:UIKeyboardWillHideNotification
    object:nil
  ];
	[[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(keyboardDidHide:)
    name:UIKeyboardDidHideNotification
    object:nil
  ];
  // super
	[super viewDidAppear:aAnimated];
  // bring up custom input view in case we have one already now
  if (customInputView) {
    [self showCustomInputViewAnimated:NO];
  }
  //%%% finally, issue auto-tap if one is set up
  //[self checkAutoTap];
}


- (void)viewWillDisappear:(BOOL)aAnimated
{
  // remove those I DID register, but no others!
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"EditingStartedInRect" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
	if (!disappearsUnderPushed) {
    // save if not cancelled before
    [self save];
    // Forget possibly left-over child editor links (should be nil, but just in case)
    self.cellThatOpenedChildDetail = nil;
    self.currentChildDetailViewController = nil;
  	// view will disappear definitely, disable editors
    self.cellsActive = NO; // deactivate now
  	// let descendants know
    [self detailViewWillClose:aAnimated];
  }
  [super viewWillDisappear:aAnimated];
}


- (void)viewDidDisappear:(BOOL)aAnimated
{
	if (!disappearsUnderPushed || !hasAppeared) {
    // Note: if we see a disappear while not hasAppeared, this apparently means that the view stack is being
    //       emptied without re-showing views that are under pushed views, so we still need to do cleanup.
    // Forget all cells (needed HERE because otherwise we'll get saved when detail view is re-opened with a new object, which
    // can be the wrong thing, namely when the object is a TTEntry intentionally not-saved+not-dirty - then it would get deleted
    // BEFORE the user actually sees it the first time)
  	[self unloadData];
  }
  if (!disappearsUnderPushed) {
    hasAppeared = NO;
    // close custom input view in case we have any
    [self removeCustomInputViewAnimated:NO];
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
    [self unloadData];
    // apparently, we got dismissed (might be set long before here, but if not, now it's certain)
    dismissed = YES;
    dismissing = NO;
  }
  [super viewDidDisappear:aAnimated];
}


#pragma mark - Input view management (keyboard, custom)


#define MIN_SPACE_ABOVE_KBD 10
#define MIN_MARGIN_ABOVE_EDITRECT 5

- (void)bringEditRectInView
{
  if (!CGRectIsNull(editRect)) {
    // edit rect is in coordinates of the navigation controller, which might have been moved already by
    // iOS keyboard appearance logic (e.g. form sheets or popovers are moved up)
    // - convert edit rect from tableview coordinates to now-current (possibly already moved) root view controller coordinates 
    CGRect er = [self.detailTableView convertRect:editRect toView:self.view.window.rootViewController.view];
    // see if keyboard will obscure the rectangle being edited
    CGFloat minYthatMustBeVisible = er.origin.y+er.size.height+MIN_SPACE_ABOVE_KBD;
    // also check if possibly detailview itself has been moved/resized such that we need to scroll even further
    CGRect nv = [self.view.superview convertRect:self.view.frame toView:self.view.window.rootViewController.view];
    CGFloat bottomOfDetailView = nv.origin.y+nv.size.height;
    DBGNSLOG(@"Start: minYthatMustBeVisible=%f, bottomOfDetailView=%f, topOfInputView=%f", minYthatMustBeVisible, bottomOfDetailView, topOfInputView);
    // calculate how much to scroll to make sure we see the editRect above the input view
    CGFloat up = minYthatMustBeVisible-topOfInputView;
    if (up>0) {
      // adjust for what "up" already corrects
      minYthatMustBeVisible = topOfInputView;
    }
    // check if that's enough, possibly we need more because bottom of detail view is even higher
    if (bottomOfDetailView < minYthatMustBeVisible) {
      // actual detail view ends above what keyboard restriction is -> move up even further
      up += minYthatMustBeVisible-bottomOfDetailView;
    }
    DBGNSLOG(@"End: minYthatMustBeVisible=%f, up=%f", minYthatMustBeVisible, up);
    // scroll if not high enough above keyboard
    if (up>0) {
      // animate content offset to move edited cell above keyboard
      CGPoint co = detailTableView.contentOffset;
      co.y += up;
      [detailTableView setContentOffset:co animated:YES];
    }
    else {
      // check if upper end of edit rectangle is currently visible
      CGFloat ymin = er.origin.y-MIN_MARGIN_ABOVE_EDITRECT;
      // relative to content
      CGFloat yrel = [self.detailTableView convertPoint:CGPointMake(0, ymin) fromView:self.detailTableView.window.rootViewController.view].y;
      // relative to top of visible part
      CGPoint co = detailTableView.contentOffset;
      yrel -= co.y;
      if (yrel<0) {
        // we can scroll down -(up) maximally before lower end of rect scrolls 
        co.y += yrel > up ? yrel : up;
        [detailTableView setContentOffset:co animated:YES];
      }
    }
    // consumed now
    editRect = CGRectNull;
  }
}


- (void)editingInRect:(NSNotification *)aNotification
{
	// save the rectangle where we are editing
  editRect = [[aNotification object] CGRectValue]; // in table view coordinates
  DBGSHOWRECT(@"editingInRect (tableView coords)",editRect);
  if (topOfInputView>0) {
    // input view is already determined
    [self bringEditRectInView];
  }
}


- (void)makeRoomForInputViewOfSize:(CGSize)aInputViewSize
{
  // get root view controller's bounds, which should be fullscreen, but rotated to current orientation 
  CGRect rvcb = detailTableView.window.rootViewController.view.bounds;
  topOfInputView = rvcb.size.height-aInputViewSize.height; // in root view coords
  // always add a table footer with the size of the input view plus min space - this makes the table scrollable up to show last cell above the input view
	if (detailTableView.tableFooterView==nil) {
    UIView *fv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, aInputViewSize.width, aInputViewSize.height+MIN_SPACE_ABOVE_KBD)];
    detailTableView.tableFooterView = fv;
    [fv release];
  }
  [self bringEditRectInView];
}


- (void)releaseRoomForInputView
{
  topOfInputView = -1; // invalid again
  if (detailTableView && detailTableView.tableFooterView) {
    // move down if we are scrolled such that extra footer is under the keyboard
    CGSize cs = [detailTableView contentSize];
    CGPoint co = detailTableView.contentOffset; // current content offset
    CGRect b = detailTableView.bounds;
    CGFloat down =
      b.size.height -
      (cs.height - co.y - detailTableView.tableFooterView.frame.size.height);
    if (down>0) {
      co.y -= down; // move table down (=scroll up)
      if (co.y<0) co.y = 0; // but not beyond top
	    [detailTableView setContentOffset:co animated:YES];
    }
  }  
}



- (void)keyboardWillShow:(NSNotification *)aNotification
{
  // dismiss other input view that might be present
  [self removeCustomInputViewAnimated:YES];
  // get info about keyboard and window (received in screen coordinates)
  // - keyboard frame
  CGRect kf = [[[aNotification userInfo] valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]; // keyboard frame in windows coords
  kf = [detailTableView convertRect:kf fromView:nil]; // keyboard frame in tableview coordinates
  DBGSHOWRECT(@"UIKeyboardFrameEndUserInfoKey (in tableview coords)",kf);
  inputViewSize = kf.size;
  // in modal views on iPad, don't make room yet, as we need to wait until all keyboard magic is done
  if (modalViewWrapper==nil || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self makeRoomForInputViewOfSize:inputViewSize];    
  }
}


- (void)keyboardDidShow:(NSNotification *)aNotification
{
  // in modal views on iPad, we need to wait until here, because only now all keyboard magic is done
  if (modalViewWrapper && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self makeRoomForInputViewOfSize:inputViewSize];
  }
}


- (void)keyboardWillHide:(NSNotification *)aNotification
{
  [self releaseRoomForInputView];
}


- (void)keyboardDidHide:(NSNotification *)aNotification
{
	// always remove the extra footer
  detailTableView.tableFooterView = nil;    
}


@synthesize customInputView;


- (void)showCustomInputViewAnimated:(BOOL)aAnimated
{
  if (customInputView) {
    CGRect rvb = detailTableView.window.rootViewController.view.bounds; // in root view controller coords
    CGRect vf = customInputView.frame;
    // size input view to root view width
    vf.size.width = rvb.size.width;
    vf.origin.x = rvb.origin.x;
    // have table adjust for showing input view
    [self makeRoomForInputViewOfSize:vf.size];
    // starts off-screen at bottom
    vf.origin.y = rvb.origin.y+rvb.size.height;
    // figure out view to add input view to
    #warning "%%% works on iPhone, not yet in all modal/popover cases on iPad.
  
    // %%% show view hierarchy and some special views
    UIView *dddv = self.view;
    while (dddv) {
      DBGNSLOG(@"View: %@",dddv.description);
      if (dddv==dddv.superview)
        break;
      dddv = dddv.superview;
    }
    DBGNSLOG(@"navigationController.presentingViewController.view: %@",self.navigationController.presentingViewController.view.description);
    DBGNSLOG(@"parentViewController.view: %@",self.parentViewController.view.description);
    DBGNSLOG(@"navigationController.parentViewController.view: %@",self.navigationController.parentViewController.view.description);
    DBGNSLOG(@"modalViewWrapper.view: %@",modalViewWrapper.view.description);
    DBGNSLOG(@"modalViewWrapper.presentingViewController.view: %@",modalViewWrapper.presentingViewController.view.description);

    UIView *viewToAddInputView = nil;
    if (modalViewWrapper==nil) {
      // not modally presented, just use my parent
      viewToAddInputView = self.parentViewController.view;
    }
    else {
      viewToAddInputView = modalViewWrapper.presentingViewController.view;
    
//      // presented modally, use superview of wrapper 
//      viewToAddInputView = modalViewWrapper.view.superview;
//      // hack for iPad - make sure we get a non-clipped view
//      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//        if (modalViewWrapper.modalPresentationStyle==UIModalPresentationFormSheet) {
//          if (viewToAddInputView.clipsToBounds) {
//            viewToAddInputView = viewToAddInputView.superview;
//          }
//        }
//      }
    }
    // bring input view frame into coordinates of view where it is being added
    DBGNSLOG(@"viewToAddInputView: %@",viewToAddInputView.description);
    vf = [detailTableView.window.rootViewController.view convertRect:vf toView:viewToAddInputView];
    DBGSHOWRECT(@"customInputView.frame (viewToAddInputView coords)",vf);
    // slide up from below like keyboard
    if (aAnimated) {
      // add in off-window position
      customInputView.frame = vf;
      [viewToAddInputView addSubview:customInputView];
      // animate in
      [UIView animateWithDuration:0.25 animations:^{
        CGRect avf = vf;
        avf.origin.y -= avf.size.height;
        customInputView.frame = avf;
      }];
    }
    else {
      // add in final position
      vf.origin.y -= vf.size.height; // calc final position
      customInputView.frame = vf;
      [viewToAddInputView addSubview:customInputView];
    }
  }
}


- (void)removeCustomInputViewAnimated:(BOOL)aAnimated
{
  if (customInputView) {
    if (aAnimated) {
      // have table re-adjust to no input view shown
      [self releaseRoomForInputView];
      // slide out
      UIView *civ = [customInputView retain];
      [UIView animateWithDuration:0.25 animations:^{
        CGRect avf = civ.frame;
        avf.origin.y += avf.size.height;
        civ.frame = avf;
      }
      completion:^(BOOL finished) {
        if (finished) {
          [civ removeFromSuperview];
          [civ release];
        }
      }];
    }
    else {
      // just remove
      [customInputView removeFromSuperview];
    }
    // forget
    [customInputView release];
    customInputView = nil;
    customInputViewUsers = 0;
    // finally, always remove the extra footer
    if (detailTableView) {
      detailTableView.tableFooterView = nil;
    }
  }
}


- (void)requireCustomInputView:(UIView *)aCustomInputView
{
  if (aCustomInputView==customInputView) {
    // same input view as before, increase usage count only
    customInputViewUsers++;
  }
  else {
    // different input view
    if (customInputView) {
      [self removeCustomInputViewAnimated:YES];
    }
    else {
      // we had no custom input view, but possibly the keyboard
      // - dismiss it
      [self.detailTableView endEditing:NO]; // not forced
    }
    customInputView = [aCustomInputView retain];
    customInputViewUsers = 1;
    // present at bottom of current window
    if (hasAppeared) {
      // already appeared - do it now
      [self showCustomInputViewAnimated:YES];
    }    
  }
}


- (void)releaseCustomInputView:(UIView *)aNilOrCustomInputView
{
  // if view passed, check if it's really ours - protection against late defocusing
  if (!customInputView || (aNilOrCustomInputView && aNilOrCustomInputView!=customInputView))
    return; // no current input view, or view has nothing todo with caller's
  // one user less
  if (customInputViewUsers>0)
    customInputViewUsers--;
  if (customInputViewUsers==0) {
    // last user gone - remove it
    [self removeCustomInputViewAnimated:YES];
  }
}




#pragma mark - helper/utility methods for UITableView delegate and datasource methods


- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	return ((ZDetailViewCellHolder *)[((ZDetailViewSection *)
    [currentSectionsAndCells objectAtIndex:aIndexPath.section]).cells
      objectAtIndex:aIndexPath.row
    ]
  ).cell;
}


- (ZDetailViewBaseCell *)detailCellForRowAtIndexPath:(NSIndexPath *)aIndexPath
{
  UITableViewCell *cell = [self cellForRowAtIndexPath:aIndexPath];
  if ([cell isKindOfClass:[ZDetailViewBaseCell class]])
    return (ZDetailViewBaseCell *)cell;
  else
    return nil;
}


- (BOOL)moveRowFromIndexPath:(NSIndexPath *)aFromIndexPath toIndexPath:(NSIndexPath *)aToIndexPath
{
  NSAssert(aFromIndexPath.section==aToIndexPath.section, @"Cannot move rows between sections");
  // volatile - rebuilding currentSectionsAndCells will destroy the new order
  NSMutableArray *cells = ((ZDetailViewSection *)[currentSectionsAndCells objectAtIndex:aFromIndexPath.section]).cells;
  id movedCell = [[cells objectAtIndex:aFromIndexPath.row] retain];
  [cells removeObjectAtIndex:aFromIndexPath.row];
  [cells insertObject:movedCell atIndex:aToIndexPath.row];
  [movedCell release];
  return YES; // could be moved
}



#pragma mark - UITableView delegate and datasource methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// return 1 even if we have no sections, as we need section 0 before table is completely set up (in startSectionWithText via rectForHeaderInSection)
  return currentSectionsAndCells.count>0 ? currentSectionsAndCells.count : 1;
}



- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (section<currentSectionsAndCells.count) {
  	ZDetailViewSection *sect = [currentSectionsAndCells objectAtIndex:section];
    if (![sect.titleTextOrView isKindOfClass:[NSString class]]) {
    	// custom header view
    	return ((UIView *)sect.titleTextOrView).frame.size.height;
    }
  }
  // default
	return 37.0;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if (section<currentSectionsAndCells.count) {
  	ZDetailViewSection *sect = [currentSectionsAndCells objectAtIndex:section];
    if (![sect.titleTextOrView isKindOfClass:[NSString class]]) {
    	// custom header view
    	return sect.titleTextOrView;
    }
  }
	return nil;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section<currentSectionsAndCells.count) {
  	ZDetailViewSection *sect = [currentSectionsAndCells objectAtIndex:section];
    if ([sect.titleTextOrView isKindOfClass:[NSString class]]) {
    	// title
    	return sect.titleTextOrView;
    }
  }
  return nil;
}





- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (currentSectionsAndCells.count==0) return 0;
	return ((ZDetailViewSection *)[currentSectionsAndCells objectAtIndex:section]).cells.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
  if ([cell conformsToProtocol:@protocol(ZDetailViewCell)]) {
  	id<ZDetailViewCell>dvc = (id<ZDetailViewCell>)cell;
    // configure ZDetailViewCell specifics
    dvc.cellOwner = self; // to make sure, but should be set already
    [dvc prepareForDisplay]; // make sure it is up-to-date
  }
	return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
	CGFloat h = -1;
  // ask cell if it supports it
  if ([cell respondsToSelector:@selector(cellHeight)]) {
	  h = [(id)cell cellHeight]; // can be dynamically calculated
  }
  // use default height if cell does not have its own
  if (h<=0) h = tableView.rowHeight;
  return h;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
  [self cellTapped:cell inAccessory:NO];
  BOOL keepSelected = NO;
  if ([cell conformsToProtocol:@protocol(ZDetailViewCell)]) {
  	id<ZDetailViewCell>dvc = (id<ZDetailViewCell>)cell;
    keepSelected = [dvc keepSelected];
  }
  return keepSelected ? indexPath : nil; // return nil to prevent selecting row
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
  [self cellTapped:cell inAccessory:YES];
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
  if ([cell conformsToProtocol:@protocol(ZDetailViewCell)]) {
  	id<ZDetailViewCell>dvc = (id<ZDetailViewCell>)cell;
    return dvc.tableEditingStyle;
  }
  return UITableViewCellEditingStyleNone;
}



@end


