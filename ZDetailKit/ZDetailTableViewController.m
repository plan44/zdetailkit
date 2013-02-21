//
//  ZDetailTableViewController.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailTableViewController.h"

#pragma mark - internal Helper classes declarations


@interface ZDetailViewSection : NSObject
{
  NSMutableArray *cells;
	id titleTextOrView;
  NSUInteger overallSectionIndex;
}
@property(readonly) NSMutableArray *cells;
@property(assign) NSUInteger overallSectionIndex;
@property(strong,nonatomic) id titleTextOrView;
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
  	titleTextOrView = aDetailViewSection.titleTextOrView;
    overallSectionIndex = aDetailViewSection.overallSectionIndex;
  }
  return self;
}



@end // ZDetailViewSection



@implementation ZDetailViewCellHolder

@synthesize cell,neededGroups,cellEnabled,overallRowIndex;

- (id)initWithCell:(UITableViewCell *)aCell neededGroups:(NSUInteger)aNeededGroups
{
	if ((self = [super init])) {
  	cell = aCell;
    neededGroups = aNeededGroups;
    // these need to be updated later
    overallRowIndex = 0;
    cellEnabled = NO;
  }
  return self;
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
    vis = vis && [(id<ZDetailViewCell>)cell nowVisibleInMode:aMode];
  }
  return vis;
}

@end // ZDetailViewCellHolder



#pragma mark - ZDetailTableViewController

@interface ZDetailTableViewController ( /* class extension */ )
{
  // all available table sections, including all available cells, each consisting of a DetailViewCellHolders
  NSMutableArray *allSectionsAndCells;
	// set of enabled groups (by number as NSNumbers)
  BOOL cellEnabledDirty; // enabled states of cells is dirty (groups need to be checked)
  // current view of the table
  BOOL currentSectionsAndCellsDirty;
  NSMutableArray *currentSectionsAndCells;
  // input view management
  CGRect editRect; // navigation controller view coordinates of where next edit area is (needed to move it in view when input views show)
  BOOL focusedEditing; // set during focused editing
  CGSize inputViewSize;
  CGFloat topOfInputView; // if >=0, keyboard or custom input view is up and inputViewSize valid
  NSInteger customInputViewUsers; // number of cells that have requested but not yet released the current input view
  // temporary for constructing sections
  ZDetailViewSection *sectionToAdd;
  BOOL buildingContent;
  // temporary for generating group bitmasks
  NSUInteger nextGroupFlag;
  // flag for table reload
  BOOL needsReloadTable;
}
@property (strong, nonatomic) UITableViewCell *cellThatOpenedChildDetail;
@property(assign, nonatomic) BOOL cellsActive;
// private methods
- (void)addDetailCell:(UITableViewCell *)aCell neededGroups:(NSUInteger)aNeededGroups nowEnabled:(BOOL)aNowEnabled;
- (void)updateTableRepresentationWithAdjust:(BOOL)aWithTableAdjust animated:(BOOL)aAnimated;
- (void)defocusAllBut:(id)aFocusedCell;
- (NSIndexPath *)indexPathForCell:(UITableViewCell *)aCell;
@end


@implementation ZDetailTableViewController


#pragma mark - initialisation and cleanup

#define SECTION_HEADER_HEIGHT 8
#define SECTION_FOOTER_HEIGHT 3

@synthesize cellThatOpenedChildDetail;

- (void)internalInit
{
  [super internalInit];
  // no referenced objects
  cellThatOpenedChildDetail = nil;
	// none configured yet
  allSectionsAndCells = nil;
  // only group 0 is enabled
  cellEnabledDirty = YES;
 	enabledGroups = 0; 
  // table not yet represented
  currentSectionsAndCells = nil;
  currentSectionsAndCellsDirty = YES;
  scrollEnabled = YES;
  needsReloadTable = NO;
  autoStartEditing = NO;
  // section construction
  sectionToAdd = nil;
  nextGroupFlag = 0x1;
  defaultCellStyle = ZDetailViewCellStyleDefault|ZDetailViewCellStyleFlagInherit;
  buildingContent = NO;
  // no custom input view
  customInputView = nil;
  customInputViewUsers = 0;
  // input view control
  topOfInputView = -1;
  inputViewSize = CGSizeZero;
  editRect = CGRectNull;
  focusedEditing = NO;
  // handlers
  cellSetupHandler = nil;
  buildDetailContentHandler = nil;
  // popover display default size
  self.contentSizeForViewInPopover = CGSizeMake(320, 500);
}


// load view
- (void)loadView
{
  // if initialized w/o NIB, autocreate and connect fullscreen table view
  if (self.nibName==nil && self.detailTableView==nil) {
    // no nib AND detail table view not provided by a subclassed loadView already
    self.detailTableView = [[UITableView alloc]
      initWithFrame:[[UIScreen mainScreen] applicationFrame]
      style:UITableViewStyleGrouped
    ];
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
    detailTableView = aDetailTableView;
    // I need to be datasource and delegate
    detailTableView.delegate = (id)self;
    detailTableView.dataSource = (id)self;
    // inherit some settings
    detailTableView.scrollEnabled = scrollEnabled;
  }
}



- (void) dealloc
{
  self.active = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


+ (id)controllerWithTitle:(NSString *)aTitle
{
  ZDetailTableViewController *dvc = [[self alloc] init];
  dvc.title = aTitle;
  dvc.navigationItem.title = aTitle;
  return dvc;
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



#pragma mark - configuring sections and cells


- (NSUInteger)newGroupFlag
{
  NSUInteger flag = nextGroupFlag;
  nextGroupFlag <<= 1;
  return flag;
}


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
  }
}


- (void)startSection
{
  sectionToAdd = [[ZDetailViewSection alloc] init];
  sectionToAdd.titleTextOrView = nil;
}


- (void)endSection
{
	if (!allSectionsAndCells)
  	allSectionsAndCells = [[NSMutableArray alloc] init];
  [allSectionsAndCells addObject:sectionToAdd];
  sectionToAdd.overallSectionIndex = allSectionsAndCells.count-1;
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


- (ZDetailTableViewController *)parentDetailTableViewController
{
  if (self.parentDetailViewController && [self.parentDetailViewController isKindOfClass:[ZDetailTableViewController class]])
    return (ZDetailTableViewController *)(self.parentDetailViewController);
  return nil;
}





@synthesize cellSetupHandler;


- (id)detailCell:(Class)aClass withStyle:(ZDetailViewCellStyle)aStyle neededGroups:(NSUInteger)aNeededGroups nowEnabled:(BOOL)aNowEnabled
{
  NSAssert([aClass isSubclassOfClass:[UITableViewCell class]], @"cells must be UITableViewCell descendants");
  UITableViewCell *newCell = [[aClass alloc] initWithStyle:aStyle reuseIdentifier:nil];
  [self addDetailCell:newCell neededGroups:aNeededGroups nowEnabled:aNowEnabled];
  // apply the default configurator
  if (cellSetupHandler) {
    cellSetupHandler(self,newCell,sectionToAdd.overallSectionIndex);
  }
  // return the cell for further configuration
  return newCell;
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


- (void)forEachCell:(ZDetailTableViewCellIterationHandler)aIterationBlock
{
  for (ZDetailViewSection *section in allSectionsAndCells) {
    for (ZDetailViewCellHolder *dvch in section.cells) {
      aIterationBlock(self,dvch.cell,section.overallSectionIndex);
    }
  }
}


- (void)forEachDetailViewCell:(ZDetailTableViewDetailViewCellIterationHandler)aIterationBlock
{
  [self forEachCell:^(ZDetailTableViewController *aController, UITableViewCell *aCell, NSInteger aSectionNo) {
    if ([aCell conformsToProtocol:@protocol(ZDetailViewCell)]) {
      aIterationBlock(self,(UITableViewCell<ZDetailViewCell> *)aCell, aSectionNo);
    }
  }];
}


- (void)forEachDetailViewBaseCell:(ZDetailTableViewDetailBaseCellIterationHandler)aIterationBlock
{
  [self forEachCell:^(ZDetailTableViewController *aController, UITableViewCell *aCell, NSInteger aSectionNo) {
    if ([aCell isKindOfClass:[ZDetailViewBaseCell class]]) {
      aIterationBlock(self,(ZDetailViewBaseCell *)aCell, aSectionNo);
    }
  }];
}





#pragma mark - appearance and behaviour properties

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

- (void)setCellsActive:(BOOL)aActive
{
  if (self.cellsActive!=aActive) {
    // cells
    [self forEachDetailViewCell:^(ZDetailTableViewController *aController, UITableViewCell<ZDetailViewCell> *aCell, NSInteger aSectionNo) {
      // set active/inactive state
      [aCell setActive:self.active];
    }];
  }
}



- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP
{
  BOOL validates = YES;
  if (self.active) {
    // collect validation status from all cells
    for (ZDetailViewSection *section in allSectionsAndCells) {
      for (ZDetailViewCellHolder *dvch in section.cells) {
        if ([dvch.cell conformsToProtocol:@protocol(ZDetailViewCell)]) {
          validates = validates && [(id<ZDetailViewCell>)dvch.cell connectorsValidateWithErrors:aErrorsP];
        }
      }
    }
    validates = validates && [super validatesWithErrors:aErrorsP];
  }
  return validates;
}



- (void)save
{
	[self defocusAllBut:nil]; // defocus all cells
  // do not save if already inactive (e.g. because edits were cancelled)
  if (self.active) {
    // let all cells save their data first (controller level values might depend)
    [self forEachDetailViewCell:^(ZDetailTableViewController *aController, UITableViewCell<ZDetailViewCell> *aCell, NSInteger aSectionNo) {
      [aCell saveValueConnectors];
    }];
    // let controller level value connectors save now (might depend on cells)
    [super save];
  }
  // subclass might save the master object after calling this super
}


- (void)revert
{
  // subclass might reload the master object before calling this super,
  // (but note that autoupdating connections might get activated)
	[self defocusAllBut:nil]; // defocus all cells
  if (self.active) {
    // let all cells reload their data
    [self forEachDetailViewCell:^(ZDetailTableViewController *aController, UITableViewCell<ZDetailViewCell> *aCell, NSInteger aSectionNo) {
      [aCell loadValueConnectors];
    }];
    // let controller level value connectors revert
    [super revert];
  }
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
        [self pushViewControllerForDetail:editController fromCell:dvc animated:YES];
      }
      else {
        // ask cell to begin (or continue) in-cell editing and claim focus
        handled = [dvc beginEditing];
      }
      if (dvc.tapClaimsFocus) {
        // This will make input views to get removed.
        [self defocusAllBut:aCell]; // defocus all other cells
      }
    }
  }
}





// needed by some editor cells to block scrolling during certain periods as otherwise
// touch tracking does not work
- (void)tempBlockScrolling:(BOOL)aBlockScrolling
{
  self.detailTableView.scrollEnabled = !aBlockScrolling && self.scrollEnabled;
}



- (void)checkReloadTable
{
  // only reload when not editing, because reload causes loosing focus
  if (needsReloadTable && !focusedEditing) {
    needsReloadTable = NO;
    [self.detailTableView reloadData];
  }
}



// ask for owner refresh (e.g. for dynamic cell heights)
- (void)setNeedsReloadingCell:(UITableViewCell *)aCell animated:(BOOL)aAnimated
{
  if (aCell==nil || !aAnimated) {
    // schedule refresh for entire table
    needsReloadTable = YES;
    [self checkReloadTable];
  }
  else {
    @try {
      // refresh single cell, possibly animated
      [self.detailTableView beginUpdates];
      [self.detailTableView endUpdates];
    }
    @catch (NSException *exception) {
      DBGNSLOG(@"setNeedsReloadingCell: calling begin/endUpdates threw exception: %@",exception);
    }
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


#pragma mark - subclassable notification methods


// called before detail view opens
- (void)detailViewWillOpen:(BOOL)aAnimated
{
  [super detailViewWillOpen:aAnimated];
  // - forget possibly left-over child editor links (should be nil, but just in case)
  self.cellThatOpenedChildDetail = nil;
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


// called before detail view closes
- (void)detailViewWillClose:(BOOL)aAnimated
{
  [super detailViewWillClose:aAnimated];
  // Forget possibly left-over child editor links (should be nil, but just in case)
  self.cellThatOpenedChildDetail = nil;
}


// called after detail view has closed (already unloaded data etc.)
- (void)detailViewDidClose:(BOOL)aAnimated
{
  [super detailViewDidClose:aAnimated];
  // close custom input view in case we have any
  [self removeCustomInputViewAnimated:NO];
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
  if (!sectionToAdd && !buildingContent) {
	  [self updateTableRepresentationWithAdjust:YES animated:aAnimated];
  }
}



// can be called to force visibility update when based on empty/nonempty state
- (void)updateVisibilitiesAnimated:(BOOL)aAnimated
{
  if (!buildingContent) {
    [super updateVisibilitiesAnimated:aAnimated];
    currentSectionsAndCellsDirty = YES; // check cells, as empty status might have changed
    [self updateTableRepresentationWithAdjust:aAnimated animated:aAnimated];
    if (!aAnimated) [self.detailTableView reloadData];
  }
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
    self.cellsActive = NO; // deactivate all cells already to make sure no undisplayed one remains active
    // then remove
  	[allSectionsAndCells removeAllObjects];
    allSectionsAndCells = nil;
  }
  // - currently visible cells
  self.cellsActive = NO; // deactivate all cells again (in case we had no allSectionsAndCells above)
	if (currentSectionsAndCells) {
    // remove as well
  	[currentSectionsAndCells removeAllObjects];
    currentSectionsAndCells = nil;
  }
}



#pragma mark - activation/deactivation

- (void)setActive:(BOOL)aActive
{
  if (aActive!=self.active) {
    if (aActive) {
      // set table options
      detailTableView.sectionHeaderHeight = SECTION_HEADER_HEIGHT;
      detailTableView.sectionFooterHeight = SECTION_FOOTER_HEIGHT;
      // prepare arrays
      // - clear if already existing
      [self forgetTableData]; // Note: deactivates cells in the process
      // - reset groups (do it before building content, as building content might already add/remove groups)
      [self resetGroups];
      // - reset group bitmask generator
      nextGroupFlag = 0x1; // start with Bit 0
      // activate controller-level value connectors already here before building cells,
      // as these might be needed during build (will be done again at cellsActive)
      [super setActive:YES];
      // Note: subclasses build the content here (by adding sections and cells)
      buildingContent = YES;
      BOOL built = [self buildDetailContent];
      buildingContent = NO;
      NSAssert(built, @"detail content was not built");
      NSAssert(sectionToAdd==nil,@"unterminated section at end of build");
      // activate the cells, so they can check their values (for detecting empty values that might not need to be shown)
      self.cellsActive = YES; // activate them now
      // create array of currently visible sections and cells
      [self updateTableRepresentationWithAdjust:NO animated:NO];
      // now reload data
      [detailTableView reloadData]; // have table show them
    }
    else {
      // deactivate controller level first
      [super setActive:NO];
      // now deactivate my own cells
      self.cellsActive = NO; // deactivate all cells
      // Remove table date right now if not (any more) appeared...
      // ...but not otherwise, as during disappearing animation, we still want to see the table
      if (!self.hasAppeared) {
        [self forgetTableData];
      }
    }
  }
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


- (void)defocus
{
  [self defocusAllBut:nil];
  [super defocus];
}


- (void)setDisplayMode:(ZDetailDisplayMode)aDisplayMode animated:(BOOL)aAnimated
{
  [super setDisplayMode:aDisplayMode animated:aAnimated];
  // - update cell modes
  [self forEachDetailViewCell:^(ZDetailTableViewController *aController, UITableViewCell<ZDetailViewCell> *aCell, NSInteger aSectionNo) {
    [aCell setDisplayMode:self.displayMode animated:aAnimated];
  }];
}


#pragma mark - Input view management (keyboard, custom)


#define MIN_SPACE_ABOVE_KBD 10
#define MIN_MARGIN_ABOVE_EDITRECT 5


- (void)viewDidAppear:(BOOL)aAnimated
{
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
    [self showCustomInputViewAnimated:YES];
  }
}


- (void)viewWillDisappear:(BOOL)aAnimated
{
  // remove those I DID register, but no others!
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"EditingStartedInRect" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
  [super viewWillDisappear:aAnimated];
}


- (void)viewDidDisappear:(BOOL)animated
{
  if (!self.active) {
    // forget table cells now (we left them intact to avoid visual effects of them going away during disappearing phase)
    [self forgetTableData];
  }
  [super viewDidDisappear:animated];
}



- (void)bringEditRectInView
{
  if (!CGRectIsNull(editRect)) {
    // edit rect is in coordinates of the navigation controller, which might have been moved already by
    // iOS keyboard appearance logic (e.g. form sheets or popovers are moved up)
    // - convert edit rect from tableview coordinates to now-current (possibly already moved) root view controller coordinates 
    CGRect er = [self.detailTableView convertRect:editRect toView:self.currentRootViewController.view];
    // see if keyboard will obscure the rectangle being edited
    CGFloat minYthatMustBeVisible = er.origin.y+er.size.height+MIN_SPACE_ABOVE_KBD;
    // also check if possibly detailview itself has been moved/resized such that we need to scroll even further
    CGRect nv = [self.view.superview convertRect:self.view.frame toView:self.currentRootViewController.view];
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
      CGFloat yrel = [self.detailTableView convertPoint:CGPointMake(0, ymin) fromView:self.currentRootViewController.view].y;
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
  id obj = [aNotification object];
  if (obj) {
    editRect = [obj CGRectValue]; // in table view coordinates
    focusedEditing = YES;
    DBGSHOWRECT(@"editingInRect (tableView coords)",editRect);
    if (topOfInputView>0) {
      // input view is already determined
      [self bringEditRectInView];
    }
  }
  else {
    // editing done
    editRect = CGRectNull; // note: usually this was already reset before by bringEditRectInView
    focusedEditing = NO; // but receiving this notification means that focused editing is over now
    // now execute pending reloads
    [self checkReloadTable];
  }
}


- (void)makeRoomForInputViewOfSize:(CGSize)aInputViewSize
{
  // get root view controller's bounds, which should be fullscreen, but rotated to current orientation 
  CGRect rvcb = self.currentRootViewController.view.bounds;
  topOfInputView = rvcb.size.height-aInputViewSize.height; // in root view coords
  // always add a table footer with the size of the input view plus min space - this makes the table scrollable up to show last cell above the input view
	if (detailTableView.tableFooterView==nil) {
    UIView *fv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, aInputViewSize.width, aInputViewSize.height+MIN_SPACE_ABOVE_KBD)];
    detailTableView.tableFooterView = fv;
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
  // dismiss other input view that might be present (not yet in iPad modal views)
  if (self.modalViewWrapper==nil || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self removeCustomInputViewAnimated:YES];
  }
  // get info about keyboard and window (received in screen coordinates)
  // - keyboard frame
  CGRect kf = [[[aNotification userInfo] valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]; // keyboard frame in windows coords
  kf = [detailTableView convertRect:kf fromView:nil]; // keyboard frame in tableview coordinates
  DBGSHOWRECT(@"UIKeyboardFrameEndUserInfoKey (in tableview coords)",kf);
  inputViewSize = kf.size;
  // in modal views on iPad, don't make room yet, as we need to wait until all keyboard magic is done
  if (self.modalViewWrapper==nil || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self makeRoomForInputViewOfSize:inputViewSize];    
  }
}


- (void)keyboardDidShow:(NSNotification *)aNotification
{
  // in modal views on iPad, we need to wait until here, because only now all view resizing
  // magic caused by keyboard appearance is done
  if (self.modalViewWrapper && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self removeCustomInputViewAnimated:NO];
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


- (UIViewController *)currentRootViewController
{
  //%%% alternative:
  //UIWindow *w = self.view.window;
  UIWindow *w = detailTableView.window;
  if (w==nil) {
    return nil;
  }
  UIViewController *v = w.rootViewController;
  return v;
}


- (UIView *)parentViewForInputView
{
  // find the first non-scrollview superview of my own view
  // Note: - without special setup, my view is the UITableView, and its superView is a wrapper
  //       - but my view might be a regular view that holds the table plus some other stuff
  UIView *v = self.view;
  while (v && [v isKindOfClass:[UIScrollView class]]) {
    v = v.superview;
  }
  if (v) {
    // Now v is a non-scrolling view. The target for the input view is its superview
    v = v.superview;
  }
  return v;
}


- (void)showCustomInputViewAnimated:(BOOL)aAnimated
{
  if (customInputView) {
    customInputView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin+UIViewAutoresizingFlexibleWidth; // keep at bottom of view we place it in, and full width
    UIView *viewToAddInputView = self.parentViewForInputView; // input view needs to be anchored in non-scrolling superview of the table
    CGRect appearanceRect = viewToAddInputView.frame;
    CGRect vf = customInputView.frame; // viewToAddInputView coords
    // size input view to root view width
    vf.size.width = appearanceRect.size.width;
    vf.origin.x = appearanceRect.origin.x;
    // starts off-screen at bottom
    vf.origin.y = appearanceRect.origin.y+appearanceRect.size.height;
    // have table adjust for showing input view
    // - relative to rootviewcontroller
    CGRect gf = self.currentRootViewController.view.bounds; // rootViewController frame
    CGPoint lowerLeftCorner = [viewToAddInputView convertPoint:vf.origin toView:self.currentRootViewController.view];
    CGSize sizeFromBottom = vf.size;
    sizeFromBottom.height += gf.origin.y+gf.size.height-lowerLeftCorner.y;
    [self makeRoomForInputViewOfSize:sizeFromBottom];
    // now present
    DBGNSLOG(@"viewToAddInputView: %@",viewToAddInputView.description);
    DBGSHOWRECT(@"customInputView.frame (viewToAddInputView coords)",vf);
    // slide up from below like keyboard
    if (aAnimated) {
      // add in off-window position
      customInputView.frame = vf;
      [viewToAddInputView addSubview:customInputView];
      // animate in
      [UIView animateWithDuration:0.25
        animations:^{
          CGRect avf = vf;
          avf.origin.y -= avf.size.height;
          customInputView.frame = avf;
        }
      ];
    }
    else {
      // add in final position
      vf.origin.y -= vf.size.height; // calc final position
      customInputView.frame = vf;
      [viewToAddInputView addSubview:customInputView];
    }
  }
}


- (void)reanchorInputView
{
  if (customInputView) {
    CGRect f = [self.view convertRect:customInputView.frame fromView:customInputView.superview];
    [customInputView removeFromSuperview];
    customInputView.frame = f;
    [self.view addSubview:customInputView];
  }
}


- (void)removeCustomInputViewAnimated:(BOOL)aAnimated
{
  if (customInputView) {
    [self reanchorInputView];
    customInputView.autoresizingMask = UIViewAutoresizingNone; // prevent autresizing magic for disappearing
    // Note: animation behaviour is very strange (animation gets aborted and customInputView is
    // animated to 0,0 origin without a reason I see) during dismissal, so we just suppress
    // animation for that case.
    if (aAnimated) {
      // have table re-adjust to no input view shown
      [self releaseRoomForInputView];
      // slide out
      UIView *civ = customInputView;
      [UIView animateWithDuration:0.25 animations:^{
        CGRect avf = civ.frame;
        avf.origin.y += avf.size.height;
        civ.frame = avf;
      }
      completion:^(BOOL finished) {
        if (finished) {
          [civ removeFromSuperview];
        }
      }];
    }
    else {
      // just remove
      [customInputView removeFromSuperview];
    }
    // forget
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
    customInputView = aCustomInputView;
    customInputViewUsers = 1;
    // present at bottom of current window
    if (self.hasAppeared) {
      // already appeared - do it now
      [self showCustomInputViewAnimated:YES];
    }    
  }
  DBGNSLOG(@"Requested custom input view, current users now = %d",customInputViewUsers);
}


- (void)releaseCustomInputView:(UIView *)aNilOrCustomInputView
{
  // if view passed, check if it's really ours - protection against late defocusing
  if (!customInputView || (aNilOrCustomInputView && aNilOrCustomInputView!=customInputView))
    return; // no current input view, or view has nothing todo with caller's
  // one user less
  if (customInputViewUsers>0)
    customInputViewUsers--;
  DBGNSLOG(@"Released custom input view, remaining users = %d",customInputViewUsers);
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
  id movedCell = [cells objectAtIndex:aFromIndexPath.row];
  [cells removeObjectAtIndex:aFromIndexPath.row];
  [cells insertObject:movedCell atIndex:aToIndexPath.row];
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


#pragma mark - ZDetailViewParent protocol


// should be called by child detail editor when editing completes
- (void)childDetailEditingDoneWithCancel:(BOOL)aCancelled
{
  if (self.cellThatOpenedChildDetail) {
    // inform the cell that the editor has closed
    if ([self.cellThatOpenedChildDetail conformsToProtocol:@protocol(ZDetailViewCell)]) {
      [(id<ZDetailViewCell>)(self.cellThatOpenedChildDetail) editorFinishedWithCancel:aCancelled];
    }
    // done
    self.cellThatOpenedChildDetail = nil;
  }
  // let superclass handle it as well
  [super childDetailEditingDoneWithCancel:aCancelled];
}


#pragma mark - ZDetailViewController


// will be called to establish link between master and detail
- (void)becomesDetailViewOfCell:(id<ZDetailViewCell>)aCell inController:(id<ZDetailViewParent>)aController
{
  // check if we should inherit styling from parent
  if ((self.defaultCellStyle & ZDetailViewCellStyleFlagInherit) && [aController isKindOfClass:[ZDetailTableViewController class]]) {
    ZDetailTableViewController *dtvc = (ZDetailTableViewController *)aController;
    // inherit style
    self.defaultCellStyle = dtvc.defaultCellStyle | ZDetailViewCellStyleFlagInherit; // keep inherit flag, even if parent did not have it
    // inherit cell setup block (for additional table-wide styling) if I don't have one myself already
    if (self.cellSetupHandler==nil) {
      // I don't have a setup handler, take my parent's
      self.cellSetupHandler = dtvc.cellSetupHandler;
    }
  }
  // table specifics done
  [super becomesDetailViewOfCell:aCell inController:aController];
}





@end


