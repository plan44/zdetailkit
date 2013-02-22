//
//  ZDVTViewController.m
//  ZDetailViewTest
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDVTViewController.h"

#import "ZOrientation.h"

#import "ZDetailKit.h"

#import <CoreLocation/CoreLocation.h>

@interface ZDVTViewController ()
{
  CLLocationCoordinate2D locationCoordinate;
}

@end


@implementation ZDVTViewController
@synthesize plan44linkLabel;
@synthesize presentationModeSegControl;


#define SEGINDEX_NAV 0
#define SEGINDEX_PAGE 1
#define SEGINDEX_SHEET 2
#define SEGINDEX_FULL 3
#define SEGINDEX_POPOVER 4

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Select default presentation mode
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    self.presentationModeSegControl.selectedSegmentIndex = SEGINDEX_NAV; // default for iPhone is pushing details onto navigation controller
  else
    self.presentationModeSegControl.selectedSegmentIndex = SEGINDEX_SHEET; // default for iPad is sheet
  // active link
  [self.plan44linkLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(plan44linkTapped)]];
}


- (void)viewDidUnload
{
  [self setPlan44linkLabel:nil];
  [self setPresentationModeSegControl:nil];
  [super viewDidUnload];
  // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // On iPhone, root controller is portrait-only
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    return interfaceOrientation==UIInterfaceOrientationPortrait;
  else
    return [ZOrientation supportsInterfaceOrientation:interfaceOrientation];
}


- (void)plan44linkTapped
{
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.plan44.ch"]];
}


#pragma mark - setting up the big sample dialog


// layout control section
- (void)setupLayoutControlSection:(ZDetailTableViewController *)c
{   
  [c startSectionWithText:@"Table Config" asTitle:YES];
  /* Cell content editing (toggle) */ {
    ZButtonCell *b = [c detailCell:[ZButtonCell class]];
    b.buttonStyle = ZButtonCellStyleCenterText;
    b.tableEditingStyle = UITableViewCellEditingStyleNone; 
    b.labelText = @"Editing on/off";
    [b setTapHandler:^(ZDetailViewBaseCell *aCell, BOOL aInAccessory) {
      [c setDisplayMode:c.displayMode ^ ZDetailDisplayModeEditing+ZDetailDisplayModeViewing animated:YES];
      return YES; // handled
    }];
  }
  /* layout: separation between description and text */ {
    ZSliderCell *sl = [c detailCell:[ZSliderCell class]];
    sl.valueConnector.autoSaveValue = YES;
    sl.sliderControl.maximumValue = 1.0; // label/value ratio
    sl.descriptionViewAdjustment = ZDetailCellItemAdjustHide; // hide
    sl.sliderControl.value = 1-sl.valueCellShare; // init with current default label/value ratio
    sl.valueCellShare = 1; // but myself, set full width slider, no label
    [sl.valueConnector setValueChangedHandler:^BOOL(ZValueConnector *aConnector) {
      [c forEachDetailViewBaseCell:^(ZDetailTableViewController *aController, ZDetailViewBaseCell *aCell, NSInteger aSectionNo) {
        // layout section itself is not changed
        if (aSectionNo>0) {
          aCell.valueCellShare = 1-[aConnector.value doubleValue];
          [aCell prepareForDisplay];
        }
      }];
      return YES; // fully handled value change
    }];
  }
  /* layout: cell indentation */ {
    ZSliderCell *sl = [c detailCell:[ZSliderCell class]];
    sl.valueConnector.autoSaveValue = YES;
    sl.labelText = @"Indent";
    sl.sliderControl.maximumValue = 150; // label/value ratio
    sl.sliderControl.value = sl.contentIndent; // init with current default content indent
    [sl.valueConnector setValueChangedHandler:^BOOL(ZValueConnector *aConnector) {
      [c forEachDetailViewBaseCell:^(ZDetailTableViewController *aController, ZDetailViewBaseCell *aCell, NSInteger aSectionNo) {
        // layout section itself is not changed
        if (aSectionNo>0) {
          aCell.contentIndent = [aConnector.value doubleValue];
          [aCell prepareForDisplay];
        }
      }];
      return YES; // fully handled value change
    }];
  }
  /* Details */ {
    ZSwitchCell *sw = [c detailCell:[ZSwitchCell class]];
    sw.labelText = @"Show more...";
    sw.valueConnector.autoSaveValue = YES;
    [sw.valueConnector setValueChangedHandler:^BOOL(ZValueConnector *aConnector) {
      if ([aConnector.value boolValue])
        [c setDisplayMode:c.displayMode | (ZDetailDisplayModeDetails+ZDetailDisplayModeBasics) animated:YES];
      else
        [c setDisplayMode:c.displayMode & ~(ZDetailDisplayModeDetails+ZDetailDisplayModeBasics) animated:YES];
      return YES; // fully handled value change
    }];
  }
  [c endSection];
}



- (void)startGroup:(NSInteger)aGroup title:(NSString *)aTitle withSwitch:(BOOL)aWithSwitch inController:(ZDetailTableViewController *)c
{
  if (aWithSwitch) {
    /* Group on/off */ {
      ZSwitchCell *sw = [c detailCell:[ZSwitchCell class]];
      sw.labelText = aTitle;
      sw.valueConnector.autoSaveValue = YES;
      [sw.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:[@"show" stringByAppendingString:aTitle]];
      [sw.valueConnector setValueChangedHandler:^BOOL(ZValueConnector *aConnector) {
        [c changeDisplayedGroups:aGroup toVisible:[aConnector.value boolValue] animated:YES];
        return NO; // don't abort handling process
      }];
    }
  }
  else {
    [c changeGroups:aGroup toVisible:YES];
  }
}




#define GROUP_CONTROLS 0x0001
#define GROUP_TEXTEDIT 0x0002
#define GROUP_CHOOSERS 0x0004
#define GROUP_DATETIME 0x0008
#define GROUP_SPECIAL 0x0010



// cells with controls
- (void)setupControlCellSection:(ZDetailTableViewController *)c withGroupSwitch:(BOOL)aWithGroupSwitch
{
  [c startSection];
  // add group switch for showing / hiding the group when aWithGroupSwitch is YES
  [self startGroup:GROUP_CONTROLS title:@"Controls" withSwitch:aWithGroupSwitch inController:c];
  // Now the conditionally shown sample cells
  /* switch cell switch control */ {
    ZSwitchCell *sw = [c detailCell:[ZSwitchCell class] neededGroups:GROUP_CONTROLS];
    sw.labelText = @"Switch Bit 0";
    sw.bitMask = 0x01;
    [sw.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"controlsNumber"];
    sw.valueConnector.autoSaveValue = YES;
  }
  /* switch cell using checkmark toggle */ {
    ZSwitchCell *t = [c detailCell:[ZSwitchCell class] neededGroups:GROUP_CONTROLS];
    t.labelText = @"Switch Bit 1 inversed";
    t.inverse = YES;
    t.bitMask = 0x02;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"controlsNumber"];
    t.valueConnector.autoSaveValue = YES;
  }
  /* switch cell using checkmark toggle */ {
    ZSwitchCell *t = [c detailCell:[ZSwitchCell class] neededGroups:GROUP_CONTROLS];
    t.labelText = @"Boolean checkmark";
    t.checkMark = YES;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"controlsNumber"];
    t.valueConnector.autoSaveValue = YES;
  }
  /* slider showing value */ {
    ZSliderCell *sl = [c detailCell:[ZSliderCell class] neededGroups:GROUP_CONTROLS];
    sl.labelText = @"Slider";
    sl.valueConnector.autoSaveValue = YES;
    sl.sliderControl.maximumValue = 5; // label/value ratio
    sl.sliderControl.minimumValue = 0;
    [sl.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"controlsNumber"];
    sl.valueConnector.autoSaveValue = YES;
  }
  /* Numeric result in inplace number editing cell */ {
    ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class] neededGroups:GROUP_CONTROLS];
    t.labelText = @"Result";
    t.descriptionLabel.numberOfLines = 2;
    t.editInDetailView = NO;
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    fmt.numberStyle = NSNumberFormatterDecimalStyle;
    t.valueConnector.formatter = fmt;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"controlsNumber"];
    t.valueConnector.autoSaveValue = YES;
  }
  [c endSection];
  [c startSection];
  /* destructive button */ {
    ZButtonCell *b = [c detailCell:[ZButtonCell class] neededGroups:GROUP_CONTROLS];
    b.buttonStyle = ZButtonCellStyleDestructive;
    b.labelText = @"Reset number to zero";
    [b setTapHandler:^(ZDetailViewBaseCell *aCell, BOOL aInAccessory) {
      [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"controlsNumber"];
      return YES; // handled
    }];
  }
  [c endSection];
}


- (void)setupTextCellSection:(ZDetailTableViewController *)c withGroupSwitch:(BOOL)aWithGroupSwitch
{
  [c startSection];
  // add group switch for showing / hiding the group when aWithGroupSwitch is YES
  [self startGroup:GROUP_TEXTEDIT title:@"Text" withSwitch:aWithGroupSwitch inController:c];
  /* inplace editing cell */ {
    ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class] neededGroups:GROUP_TEXTEDIT];
    t.labelText = @"Text field";
    t.editInDetailView = NO;
    t.returnKeyType = UIReturnKeyNext;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testText"];
    t.valueConnector.autoSaveValue = YES;
  }
  /* password editing cell */ {
    ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class] neededGroups:GROUP_TEXTEDIT];
    t.labelText = @"Secure Entry";
    t.editInDetailView = NO;
    t.returnKeyType = UIReturnKeyNext;
    t.secureTextEntry = YES;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testText"];
    t.valueConnector.autoSaveValue = YES;
  }
  /* separate editor */ {
    ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class] neededGroups:GROUP_TEXTEDIT];
    t.labelText = @"Separate Editor";
    t.descriptionLabel.numberOfLines = 0;
    t.editInDetailView = YES;
    t.largeEditor = YES;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testText"];
    t.valueConnector.autoSaveValue = YES;
  }
  /* inplace textView editing cell */ {
    ZTextViewCell *t = [c detailCell:[ZTextViewCell class] neededGroups:GROUP_TEXTEDIT];
    t.labelText = @"Autosizing text view";
    t.descriptionLabel.numberOfLines = 0;
    t.editInDetailView = NO;
    t.multiline = YES;
    t.returnKeyType = UIReturnKeyNext;
    t.descriptionViewAdjustment = ZDetailCellItemAdjustTop;
    t.valueViewAdjustment = ZDetailCellItemAdjustTop;
    t.autoAdjustHeight = YES;
    t.adjustWhileTyping = YES;
    t.standardCellHeight = 88;
    t.maxCellHeight = 300;
    t.textView.dataDetectorTypes = UIDataDetectorTypeAll;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"longTestText"];
    t.valueConnector.autoSaveValue = YES;
  }
  /* textView editing cell with separate editor */ {
    ZTextViewCell *t = [c detailCell:[ZTextViewCell class] neededGroups:GROUP_TEXTEDIT];
    t.labelText = @"text view with separate editor";
    t.descriptionLabel.numberOfLines = 0;
    t.editInDetailView = YES;
    t.multiline = YES;
    t.descriptionViewAdjustment = ZDetailCellItemAdjustTop;
    t.valueViewAdjustment = ZDetailCellItemAdjustTop;
    t.autoAdjustHeight = YES;
    t.standardCellHeight = 88;
    t.maxCellHeight = 120;
    t.textView.dataDetectorTypes = UIDataDetectorTypeAll;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"longTestText"];
    t.valueConnector.autoSaveValue = YES;
  }
  [c endSection];
}


- (void)setupChoicesCellSection:(ZDetailTableViewController *)c withGroupSwitch:(BOOL)aWithGroupSwitch
{
  [c startSection];
  [self startGroup:GROUP_CHOOSERS title:@"Choosers" withSwitch:aWithGroupSwitch inController:c];
  /* segment choice cell */ {
    ZSegmentChoicesCell *sg = [c detailCell:[ZSegmentChoicesCell class] neededGroups:GROUP_CHOOSERS];
    sg.labelText = @"Segmented";
    [sg.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"choicesNumber"];
    [sg.choicesManager addChoice:@"0" order:1 key:[NSNumber numberWithInt:0]];
    [sg.choicesManager addChoice:@"1" order:2 key:[NSNumber numberWithInt:1]];
    [sg.choicesManager addChoice:@"3" order:3 key:[NSNumber numberWithInt:3]];
    sg.valueConnector.autoSaveValue = YES;
  }
  /* single choice list */ {
    ZChoiceListCell *cl = [c detailCell:[ZChoiceListCell class] neededGroups:GROUP_CHOOSERS];
    cl.labelText = @"Single Choice";
    [cl.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"choicesNumber"];
    [cl.choicesManager addChoice:@"Zero" order:1 key:[NSNumber numberWithInt:0]];
    [cl.choicesManager addChoice:@"One" order:2 key:[NSNumber numberWithInt:1]];
    [cl.choicesManager addChoice:@"Two" order:3 key:[NSNumber numberWithInt:2]];
    [cl.choicesManager addChoice:@"Three" order:4 key:[NSNumber numberWithInt:3]];
    [cl.choicesManager addChoice:@"Four" order:5 key:[NSNumber numberWithInt:4]];
    [cl.choicesManager addChoice:@"Five" order:6 key:[NSNumber numberWithInt:5]];
    cl.choicesManager.mode = ZChoicesManagerModeSingleKey;
    cl.choicesManager.multipleChoices = NO;
    cl.valueConnector.autoSaveValue = YES;
  }
  /* multiple choice list */ {
    ZChoiceListCell *cl = [c detailCell:[ZChoiceListCell class] neededGroups:GROUP_CHOOSERS];
    cl.labelText = @"Multiple Choice";
    [cl.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"choicesSet"];
    [cl.choicesManager addChoice:@"Albatross" order:2 key:[NSNumber numberWithInt:1]];
    [cl.choicesManager addChoice:@"Baer" order:3 key:[NSNumber numberWithInt:2]];
    [cl.choicesManager addChoice:@"Cheetah" order:4 key:[NSNumber numberWithInt:3]];
    [cl.choicesManager addChoice:@"Duck" order:5 key:[NSNumber numberWithInt:4]];
    [cl.choicesManager addChoice:@"Elephant" order:6 key:[NSNumber numberWithInt:5]];
    cl.choicesManager.mode = ZChoicesManagerModeKeySet;
    cl.choicesManager.multipleChoices = YES;
    cl.valueConnector.autoSaveValue = YES;
  }
  /* orderable list with enable/disable */ {
    ZChoiceListCell *cl = [c detailCell:[ZChoiceListCell class] neededGroups:GROUP_CHOOSERS];
    cl.labelText = @"Orderable";
    [cl.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"choicesDict"];
    [cl.choicesManager addChoice:@"Eleven" summary:@"11" order:1 key:[NSNumber numberWithInt:11]];
    [cl.choicesManager addChoice:@"Twentytwo" summary:@"22" order:2 key:[NSNumber numberWithInt:22]];
    [cl.choicesManager addChoice:@"Thirthythree" summary:@"33" order:3 key:[NSNumber numberWithInt:33]];
    [cl.choicesManager addChoice:@"Fortytwo" summary:@"42" order:4 key:[NSNumber numberWithInt:42]];
    [cl.choicesManager addChoice:@"Fiftyfive"  summary:@"55" order:5 key:[NSNumber numberWithInt:55]];
    cl.choicesManager.mode = ZChoicesManagerModeDictArray;
    cl.choicesManager.multipleChoices = YES;
    cl.choicesManager.reorderable = YES;
    cl.valueConnector.autoSaveValue = NO;
  }
  [c endSection];
}


- (void)setupDateCellSection:(ZDetailTableViewController *)c withGroupSwitch:(BOOL)aWithGroupSwitch
{
  [c startSection];
  // add group switch for showing / hiding the group when aWithGroupSwitch is YES
  [self startGroup:GROUP_DATETIME title:@"Dates" withSwitch:aWithGroupSwitch inController:c];
  /* All-day (date only) switch cell switch control */ {
    ZSwitchCell *sw = [c detailCell:[ZSwitchCell class] neededGroups:GROUP_DATETIME];
    sw.labelText = @"Allday";
    [sw.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"dateOnly"];
    sw.valueConnector.autoSaveValue = YES;
  }
  /* inplace dateTime cell */ {
    ZDateTimeCell *d = [c detailCell:[ZDateTimeCell class] neededGroups:GROUP_DATETIME];
    d.startDateLabelText = @"Start Date";
    d.editInDetailView = NO;
    d.startDateConnector.nilAllowed = YES;
    [d.startDateConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"startDate"];
    [d.dateOnlyConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"dateOnly"];
    d.startDateConnector.autoSaveValue = YES;
    d.dateOnlyConnector.autoSaveValue = YES;
  }
  /* inplace dateTime cell */ {
    ZDateTimeCell *d = [c detailCell:[ZDateTimeCell class] neededGroups:GROUP_DATETIME];
    d.startDateLabelText = @"Start Date";
    d.dateOnlyLabelText = @"Allday";
    d.clearDateButtonText = @"No date";
    d.editInDetailView = YES;
    d.startDateConnector.nilAllowed = YES;
    [d.startDateConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"startDate"];
    [d.dateOnlyConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"dateOnly"];
    d.startDateConnector.autoSaveValue = YES;
    d.dateOnlyConnector.autoSaveValue = YES;
  }
  /* dateTime cell with start+end and external editor */ {
    ZDateTimeCell *d = [c detailCell:[ZDateTimeCell class] neededGroups:GROUP_DATETIME];
    d.startDateLabelText = @"Start";
    d.endDateLabelText = @"End";
    d.dateOnlyLabelText = @"Allday";
    d.minuteInterval = 5;
    d.descriptionLabel.numberOfLines = 2;
    d.valueLabel.numberOfLines = 2;
    d.editInDetailView = YES;
    d.startDateConnector.nilAllowed = NO;
    d.endDateConnector.nilAllowed = NO;
    [d.startDateConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"startDate"];
    [d.endDateConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"endDate"];
    [d.dateOnlyConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"dateOnly"];
    d.startDateConnector.autoSaveValue = YES;
    d.endDateConnector.autoSaveValue = YES;
    d.dateOnlyConnector.autoSaveValue = YES;
  }
  [c endSection];
}


- (void)setupSpecialCellSection:(ZDetailTableViewController *)c withGroupSwitch:(BOOL)aWithGroupSwitch
{
  [c startSection];
  // add group switch for showing / hiding the group when aWithGroupSwitch is YES
  [self startGroup:GROUP_SPECIAL title:@"Special" withSwitch:aWithGroupSwitch inController:c];
  /* color represented as int */ {
    ZColorChooserCell *co = [c detailCell:[ZColorChooserCell class] neededGroups:GROUP_SPECIAL];
    [co.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"colorNumber"];
    co.valueConnector.valueTransformer = [NSValueTransformer valueTransformerForName:@"ZIntToUIColorTransformer"];
    co.valueConnector.autoSaveValue = YES;
  }
  /* slider for number */ {
    ZSliderCell *sl = [c detailCell:[ZSliderCell class] neededGroups:GROUP_SPECIAL];
    [sl.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"colorNumber"];
    sl.valueConnector.autoSaveValue = YES;
    sl.sliderControl.maximumValue = 0xFFFFFF; // 24bit color range
  }
  /* inplace number editing cell */ {
    ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class] neededGroups:GROUP_SPECIAL];
    t.labelText = @"24bit Color";
    t.descriptionLabel.numberOfLines = 2;
    t.editInDetailView = NO;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"colorNumber"];
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    fmt.numberStyle = kCFNumberFormatterNoStyle;
    t.valueConnector.formatter = fmt;
    t.valueConnector.autoSaveValue = YES;
  }
  /* location editor */ {
    ZLocationCell *l = [c detailCell:[ZLocationCell class] neededGroups:GROUP_SPECIAL];
    l.labelText = @"Geolocation";
    [l.textValueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"locationText"];
    [l.coordinateValueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"latCommaLong"];
    l.coordinateValueConnector.valueTransformer = [NSValueTransformer valueTransformerForName:@"ZStringToCoordinate2DTransformer"];
  }
  [c endSection];
}




- (void)setupSubMenu:(ZDetailTableViewController *)c withTitle:(NSString *)aTitle sectionBuilder:(void (^)(ZDetailTableViewController *c))aSectionBuilder
{
  /* Button */ {
    ZButtonCell *b = [c detailCell:[ZButtonCell class]];
    b.labelText = aTitle;
    [b setTapHandler:^(ZDetailViewBaseCell *aCell, BOOL aInAccessory) {
      // open subdetail
      ZDetailTableViewController *dtvc2 = [ZDetailTableViewController controllerWithTitle:aTitle];
      [dtvc2 setBuildDetailContentHandler:^(ZDetailTableViewController *c2) {
        aSectionBuilder(c2);
        return YES; // built
      }];
      [c pushViewControllerForDetail:dtvc2 fromCell:aCell animated:YES];
      return YES; // handled
    }]; // tapHandler
  } // button
}


- (void)setupSubMenus:(ZDetailTableViewController *)c
{
  // include all the demo sections above again, but this time each one as a submenu
  [c startSectionWithText:@"Same as Sub-Details" asTitle:YES];
  // create a button cell for each of the demo categories
  [self setupSubMenu:c withTitle:@"Controls" sectionBuilder:^(ZDetailTableViewController *c){ [self setupControlCellSection:c withGroupSwitch:NO]; }];
  [self setupSubMenu:c withTitle:@"Text" sectionBuilder:^(ZDetailTableViewController *c){ [self setupTextCellSection:c withGroupSwitch:NO]; }];
  [self setupSubMenu:c withTitle:@"Choosers" sectionBuilder:^(ZDetailTableViewController *c){ [self setupChoicesCellSection:c withGroupSwitch:NO]; }];
  [self setupSubMenu:c withTitle:@"Dates" sectionBuilder:^(ZDetailTableViewController *c){ [self setupDateCellSection:c withGroupSwitch:NO]; }];
  [self setupSubMenu:c withTitle:@"Special" sectionBuilder:^(ZDetailTableViewController *c){ [self setupSpecialCellSection:c withGroupSwitch:NO]; }];
  [c endSection];
}


- (void)setupDetails:(ZDetailTableViewController *)dtvc
{
  [dtvc setBuildDetailContentHandler:^(ZDetailTableViewController *c) {
    // IMPORTANT: do not use "dtvc" in blocks, as it would create a retain cycle!
    // configuration split into sections for clarity
    // - important: don't use etched when there are indented cells!
    c.detailTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    // Create a section with controls allowing live manipulation of the layout
    [self setupLayoutControlSection:c];
    // intermediate title
    [c startSectionWithText:@"Samples" asTitle:YES];
    [c endSection];
    // sample sections
    // - cells with controls
    [self setupControlCellSection:c withGroupSwitch:YES];
    // - cells for text editing
    [self setupTextCellSection:c withGroupSwitch:YES];
    // - choosers
    [self setupChoicesCellSection:c withGroupSwitch:YES];
    // - dates
    [self setupDateCellSection:c withGroupSwitch:YES];
    // - special
    [self setupSpecialCellSection:c withGroupSwitch:YES];
    // - all the same stuff as submenues
    [self setupSubMenus:c];
    // built ok
    return YES;
  }];
}




#pragma mark - demonstrate presentation in different ways


- (void)presentDetails:(ZDetailTableViewController *)dtvc
{
  if (self.presentationModeSegControl.selectedSegmentIndex==SEGINDEX_NAV) {
    // push onto main navigation controller (iPhone style)
    [self.navigationController pushViewController:dtvc animated:YES];
  }
  else {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
      // only one modal style for iPhone, just present
      [self presentViewController:[dtvc viewControllerForModalPresentation] animated:YES completion:nil];
    }
    else {
      // iPad has variants
      if (self.presentationModeSegControl.selectedSegmentIndex==SEGINDEX_POPOVER) {
        // show in popover
        UIPopoverController *pop = [dtvc popoverControllerForPresentation];
        [pop presentPopoverFromRect:presentationModeSegControl.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
      }
      else {
        // present modally
        // - set presentation mode
        if (self.presentationModeSegControl.selectedSegmentIndex==SEGINDEX_SHEET)
          dtvc.modalPresentationStyle = UIModalPresentationFormSheet;
        else if (self.presentationModeSegControl.selectedSegmentIndex==SEGINDEX_PAGE)
          dtvc.modalPresentationStyle = UIModalPresentationPageSheet;
        else
          dtvc.modalPresentationStyle = UIModalPresentationFullScreen;
        // - present
        [self presentViewController:[dtvc viewControllerForModalPresentation] animated:YES completion:nil];
      }
    }
  }
}


#pragma mark - main view button handlers

- (IBAction)prefDetails:(id)sender
{
  // create the detail view controller
  ZDetailTableViewController *dtvc = [ZDetailTableViewController controllerWithTitle:@"Prefs Style"];
  // set the cell style (essentially UITableViewCellStyleValue1, but with ZDetailKit autostyling)
  dtvc.defaultCellStyle = UITableViewCellStyleValue1+ZDetailViewCellStyleFlagAutoStyle;
  // set the navigation mode
  dtvc.navigationMode = ZDetailNavigationModeRightButtonTableEditDone|ZDetailNavigationModeLeftButtonAuto;
  dtvc.modalInPopover = NO; // dismiss by tapping outside, no done button by default
  // common setup of the contents
  [self setupDetails:dtvc];
  // show it
  [self presentDetails:dtvc];
}


- (IBAction)entryEditDetails:(id)sender
{
  // create the detail view controller
  ZDetailTableViewController *dtvc = [ZDetailTableViewController controllerWithTitle:@"Contacts Style"];
  // set the cell style (essentially UITableViewCellStyleValue2, but with ZDetailKit autolayout and styling)
  dtvc.defaultCellStyle = ZDetailViewCellStyleEntryDetail;
  // set the navigation mode
  dtvc.navigationMode = ZDetailNavigationModeRightButtonTableEditDone|ZDetailNavigationModeLeftButtonAuto;
  // common setup of the contents
  [self setupDetails:dtvc]; 
  // show it
  [self presentDetails:dtvc];
}


- (IBAction)taskZDetails:(id)sender
{
  // create the detail view controller
  ZDetailTableViewController *dtvc = [ZDetailTableViewController controllerWithTitle:@"TaskZ style"];
  // set the cell style (essentially UITableViewCellStyleValue2, but with ZDetailKit autolayout and styling)
  dtvc.defaultCellStyle = ZDetailViewCellStyleEntryDetail;
  // set the navigation mode
  dtvc.navigationMode = ZDetailNavigationModeRightButtonTableEditDone|ZDetailNavigationModeLeftButtonAuto;
  // this handler is called to apply non-standard styling for every cell
  [dtvc setCellSetupHandler:^(ZDetailTableViewController *aController, UITableViewCell *aNewCell, NSInteger aSectionNo) {
    // specific styling applied to every cell
    if ([aNewCell isKindOfClass:[ZDetailViewBaseCell class]]) {
      ZDetailViewBaseCell *cell = (ZDetailViewBaseCell *)aNewCell;
      cell.descriptionLabel.textAlignment = UITextAlignmentLeft; // we want description labels left aligned
      cell.valueLabel.textAlignment = UITextAlignmentLeft; // as well as values
      cell.descriptionViewAdjustment = cell.descriptionViewAdjustment | ZDetailCellItemAdjustExtend; // if value is short (i.e. a switch), allow for longer description text
    }
  }];
  // common setup of the contents
  [self setupDetails:dtvc]; 
  // show it
  [self presentDetails:dtvc];
}



- (IBAction)navModeChanged:(id)sender {
}
@end
