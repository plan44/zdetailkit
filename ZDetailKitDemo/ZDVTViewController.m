//
//  ZDVTViewController.m
//  ZDetailViewTest
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDVTViewController.h"

#import "ZOrientation.h"

#import "ZDetailTableViewController.h"

#import "ZButtonCell.h"
#import "ZTextFieldCell.h"
#import "ZTextViewCell.h"
#import "ZSwitchCell.h"
#import "ZSliderCell.h"
#import "ZSegmentChoicesCell.h"
#import "ZChoiceListCell.h"
#import "ZDateTimeCell.h"
#import "ZColorChooserCell.h"
#import "ZIntToUIColorTransformer.h"

@interface ZDVTViewController ()

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
	// Do any additional setup after loading the view, typically from a nib.
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    self.presentationModeSegControl.selectedSegmentIndex = SEGINDEX_NAV; // default for iPhone is pushing details onto navigation controller
  else
    self.presentationModeSegControl.selectedSegmentIndex = SEGINDEX_SHEET; // default for iPad is sheet  
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


- (void)dealloc
{
  [plan44linkLabel release];
  [presentationModeSegControl release];
  [super dealloc];
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
    [sl.valueConnector setValueChangedHandler:^BOOL(ZDetailValueConnector *aConnector) {
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
    [sl.valueConnector setValueChangedHandler:^BOOL(ZDetailValueConnector *aConnector) {
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
    [sw.valueConnector setValueChangedHandler:^BOOL(ZDetailValueConnector *aConnector) {
      if ([aConnector.value boolValue])
        [c setDisplayMode:c.displayMode | (ZDetailDisplayModeDetails+ZDetailDisplayModeBasics) animated:YES];
      else
        [c setDisplayMode:c.displayMode & ~(ZDetailDisplayModeDetails+ZDetailDisplayModeBasics) animated:YES];
      return YES; // fully handled value change
    }];
  }
  [c endSection];
}


#define GROUP_CONTROLS 0x0001
#define GROUP_TEXTEDIT 0x0002
#define GROUP_CHOOSERS 0x0004
#define GROUP_DATETIME 0x0008




// cells with controls
- (void)setupControlCellSection:(ZDetailTableViewController *)c
{
  [c startSection];
  /* Group on/off */ {
    ZSwitchCell *sw = [c detailCell:[ZSwitchCell class]];
    sw.labelText = @"Controls";
    sw.valueConnector.autoSaveValue = YES;
    [sw.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"showControls"];
    [sw.valueConnector setValueChangedHandler:^BOOL(ZDetailValueConnector *aConnector) {
      [c changeDisplayedGroups:GROUP_CONTROLS toVisible:[aConnector.value boolValue] animated:YES];
      return NO; // don't abort handling process
    }];
  }
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
  /* Numeric result in inplace number editing cell */ {
    ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class] neededGroups:GROUP_CONTROLS];
    t.labelText = @"Result";
    t.descriptionLabel.numberOfLines = 2;
    t.editInDetailView = NO;
    NSNumberFormatter *fmt = [[[NSNumberFormatter alloc] init] autorelease];
    fmt.numberStyle = NSNumberFormatterDecimalStyle;
    t.valueConnector.formatter = fmt;
    [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"controlsNumber"];
    t.valueConnector.autoSaveValue = YES;
  }
  [c endSection];  
}


- (void)setupTextCellSection:(ZDetailTableViewController *)c
{
  [c startSection];
  /* Group on/off */ {
    ZSwitchCell *sw = [c detailCell:[ZSwitchCell class]];
    sw.labelText = @"Text Editing";
    sw.valueConnector.autoSaveValue = YES;
    [sw.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"showTextEditing"];
    [sw.valueConnector setValueChangedHandler:^BOOL(ZDetailValueConnector *aConnector) {
      [c changeDisplayedGroups:GROUP_TEXTEDIT toVisible:[aConnector.value boolValue] animated:YES];
      return NO; // don't abort handling process
    }];
  }
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


- (void)setupChoicesCellSection:(ZDetailTableViewController *)c
{
  [c startSection];
  /* Group on/off */ {
    ZSwitchCell *sw = [c detailCell:[ZSwitchCell class]];
    sw.labelText = @"Multiple Choices";
    sw.valueConnector.autoSaveValue = YES;
    [sw.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"showChoosers"];
    [sw.valueConnector setValueChangedHandler:^BOOL(ZDetailValueConnector *aConnector) {
      [c changeDisplayedGroups:GROUP_CHOOSERS toVisible:[aConnector.value boolValue] animated:YES];
      return NO; // don't abort handling process
    }];
  }
  /* segment choice cell */ {
    ZSegmentChoicesCell *sg = [c detailCell:[ZSegmentChoicesCell class] neededGroups:GROUP_CHOOSERS];
    sg.labelText = @"Segmented Choices";
    [sg.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"controlsNumber"];
    [sg.choicesManager addChoice:@"0" order:1 key:[NSNumber numberWithInt:0]];
    [sg.choicesManager addChoice:@"1" order:2 key:[NSNumber numberWithInt:1]];
    [sg.choicesManager addChoice:@"2" order:3 key:[NSNumber numberWithInt:2]];
    [sg.choicesManager addChoice:@"3" order:4 key:[NSNumber numberWithInt:3]];
    sg.valueConnector.autoSaveValue = YES;
  }
  [c endSection];
}


- (void)setupDateCellSection:(ZDetailTableViewController *)c
{
  [c startSection];
  /* Group on/off */ {
    ZSwitchCell *sw = [c detailCell:[ZSwitchCell class]];
    sw.labelText = @"Dates";
    sw.valueConnector.autoSaveValue = YES;
    [sw.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"showDates"];
    [sw.valueConnector setValueChangedHandler:^BOOL(ZDetailValueConnector *aConnector) {
      [c changeDisplayedGroups:GROUP_DATETIME toVisible:[aConnector.value boolValue] animated:YES];
      return NO; // don't abort handling process
    }];
  }
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
    [d.startDateConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"startDate"];
    [d.endDateConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"endDate"];
    [d.dateOnlyConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"dateOnly"];
    d.startDateConnector.nilAllowed = YES;
    d.endDateConnector.nilAllowed = YES;
    d.startDateConnector.autoSaveValue = YES;
    d.endDateConnector.autoSaveValue = YES;
    d.dateOnlyConnector.autoSaveValue = YES;
  }
  [c endSection];
}


/*

 //t.valueConnector.autoSaveValue = YES; // we want to see the other cells updating live!
 // hardcore: every keypress refreshes table visibility state
 [t setValueChangedHandler:^(ZDetailViewBaseCell *aCell, ZDetailValueConnector *aConnector) {
 // immediately save
 [aConnector saveValue];
 [c updateCellVisibilitiesAnimated:YES];
 return NO; // don't prevent other handling activities
 }];
 
 
 */

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
    [self setupControlCellSection:c];
    // - cells for text editing
    [self setupTextCellSection:c];
    // - choosers
    [self setupChoicesCellSection:c];
    // - dates
    [self setupDateCellSection:c];
    
    
    
    
    // - numbers and dates
    
    
    // - color, location
    
    // - special features
    
    // only show when not empty, 
    
    
    // %%% old stuff
    [c startSection];
    /* Button */ {
      ZButtonCell *b = [c detailCell:[ZButtonCell class]];
      b.labelText = @"Hallo";
      [b setTapHandler:^(ZDetailViewBaseCell *aCell, BOOL aInAccessory) {
        // open subdetail
        ZDetailTableViewController *dtvc2 = [ZDetailTableViewController controllerWithTitle:@"Welt"];
        [dtvc2 setBuildDetailContentHandler:^(ZDetailTableViewController *c2) {
          [c2 startSection];
          /* base cell */ {
            ZDetailViewBaseCell *x = [c2 detailCell:[ZDetailViewBaseCell class]];
            x.labelText = @"Welt!";
            x.valueLabel.text = @"Soweit mein Kommentar";
          }
          [c2 endSection];
          return YES; // built
        }];
        [c pushViewControllerForDetail:dtvc2 animated:YES];          
        return YES; // handled
      }]; // tapHandler
    } // button

    /* inplace number editing cell, hex */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"Inplace Number edit";
      t.descriptionLabel.numberOfLines = 2;
      t.editInDetailView = NO;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testNumber2"];
      NSNumberFormatter *fmt = [[[NSNumberFormatter alloc] init] autorelease];
      fmt.numberStyle = NSNumberFormatterDecimalStyle;
      t.valueConnector.formatter = fmt;
      t.valueConnector.autoSaveValue = YES;
    }
    /* color represented as int */ {
      ZColorChooserCell *co = [c detailCell:[ZColorChooserCell class]];
      [co.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testNumber2"];
      co.valueConnector.valueTransformer = [NSValueTransformer valueTransformerForName:@"ZIntToUIColorTransformer"];
      co.valueConnector.autoSaveValue = YES;
    }
//    /* slider for number */ {
//      ZSliderCell *sl = [c detailCell:[ZSliderCell class]];
//      [sl.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testNumber2"];
//      sl.valueConnector.autoSaveValue = YES;
//      sl.sliderControl.maximumValue = 0xFFFFFF; // 24bit color range
//    }
    /* inplace start date text editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"Start date";
      t.editInDetailView = NO;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"startDate"];
      NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
      fmt.dateStyle = NSDateFormatterMediumStyle;
      fmt.timeStyle = NSDateFormatterMediumStyle;
      t.valueConnector.formatter = fmt;
      t.valueConnector.autoSaveValue = YES;
      t.valueConnector.saveEmptyAsNil = YES;
    }
    /* inplace end date text editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"End date";
      t.editInDetailView = NO;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"endDate"];
      NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
      fmt.dateStyle = NSDateFormatterMediumStyle;
      fmt.timeStyle = NSDateFormatterMediumStyle;
      t.valueConnector.formatter = fmt;
      t.valueConnector.autoSaveValue = YES;
      t.valueConnector.saveEmptyAsNil = YES;
    }
    /* segment choice cell */ {
      ZSegmentChoicesCell *sg = [c detailCell:[ZSegmentChoicesCell class]];
      sg.labelText = @"Segmented Choices";
      [sg.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testNumber2"];
      [sg.choicesManager addChoice:@"11" order:1 key:[NSNumber numberWithInt:11]];
      [sg.choicesManager addChoice:@"22" order:2 key:[NSNumber numberWithInt:22]];
      [sg.choicesManager addChoice:@"33" order:3 key:[NSNumber numberWithInt:33]];
      sg.valueConnector.autoSaveValue = YES;
    }
    /* switch cell switch control */ {
      ZSwitchCell *sw = [c detailCell:[ZSwitchCell class]];
      sw.labelText = @"Switch Bit 0";
      sw.bitMask = 0x01;
      [sw.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testNumber2"];
      sw.valueConnector.autoSaveValue = YES;
    }
    /* switch cell using checkmark toggle */ {
      ZSwitchCell *t = [c detailCell:[ZSwitchCell class]];
      t.labelText = @"!Switch Bit 7";
      t.inverse = YES;
      t.bitMask = 0x80;
      t.checkMark = YES;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testNumber2"];
      t.valueConnector.autoSaveValue = YES;
    }
    /* list choice cell */ {
      ZChoiceListCell *cl = [c detailCell:[ZChoiceListCell class]];
      cl.labelText = @"Multiple Choices";
      [cl.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testChoices"];
      [cl.choicesManager addChoice:@"OneOne" summary:@"11" order:1 key:[NSNumber numberWithInt:11]];
      [cl.choicesManager addChoice:@"TwoTwo" summary:@"22" order:2 key:[NSNumber numberWithInt:22]];
      [cl.choicesManager addChoice:@"ThreeThree" summary:@"33" order:3 key:[NSNumber numberWithInt:33]];
      [cl.choicesManager addChoice:@"FourFour" summary:@"44" order:4 key:[NSNumber numberWithInt:44]];
      [cl.choicesManager addChoice:@"FiveFive"  summary:@"55" order:5 key:[NSNumber numberWithInt:55]];
      cl.choicesManager.mode = ZChoicesManagerModeDictArray;
      cl.choicesManager.multipleChoices = YES;
      cl.choicesManager.reorderable = YES;
      cl.valueConnector.autoSaveValue = NO;
    }
    /* list choice cell */ {
      ZChoiceListCell *cl = [c detailCell:[ZChoiceListCell class]];
      cl.labelText = @"Single Choice";
      [cl.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testNumber2"];
      [cl.choicesManager addChoice:@"One" order:1 key:[NSNumber numberWithInt:111]];
      [cl.choicesManager addChoice:@"Two" order:2 key:[NSNumber numberWithInt:222]];
      [cl.choicesManager addChoice:@"Seven" order:3 key:[NSNumber numberWithInt:777]];
      cl.choicesManager.mode = ZChoicesManagerModeSingleKey;
      cl.choicesManager.multipleChoices = NO;
      cl.valueConnector.autoSaveValue = YES;
    }
    /* detailview editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"Nonempty";
      t.descriptionLabel.numberOfLines = 2;
      t.neededModes = ZDetailDisplayModeBasicsNonEmpty; // must be non-empty to show up in basic view mode
      t.editInDetailView = NO;
      t.returnKeyType = UIReturnKeyNext;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testText"];
    }
    [c endSection];
    [c startSectionWithText:@"More stuff" asTitle:YES];
    /* inplace editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"Inplace edit 2";
      t.contentIndent = 50;
//      t.valueCellShare = 0.5;
      t.editInDetailView = NO;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testText"];
    }
    [c endSection];
    return YES; // built
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
