//
//  ZDVTViewController.m
//  ZDetailViewTest
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDVTViewController.h"

#import "ZDetailTableViewController.h"

#import "ZButtonCell.h"
#import "ZTextFieldCell.h"
#import "ZTextViewCell.h"
#import "ZSwitchCell.h"
#import "ZSegmentChoicesCell.h"
#import "ZChoiceListCell.h"
#import "ZDateTimeCell.h"

@interface ZDVTViewController ()

@end


@implementation ZDVTViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}


- (void)setupDetails:(ZDetailTableViewController *)dtvc
{
  [dtvc setBuildDetailContentHandler:^(ZDetailTableViewController *c) {
    // IMPORTANT: do not use "dtvc" in blocks, as it would create a retain cycle!
    [c startSection];
    // important: don't use etched when there are indented cells!
    c.detailTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
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
    /* inplace editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"Inplace edit";
      t.editInDetailView = NO;
      t.returnKeyType = UIReturnKeyNext;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testText"];
      //t.valueConnector.autoSaveValue = YES; // we want to see the other cells updating live!
      // hardcore: every keypress refreshes table visibility state
      [t setValueChangedHandler:^(ZDetailViewBaseCell *aCell, ZDetailValueConnector *aConnector) {
        // immediately save
        [aConnector saveValue];
        [c updateCellVisibilitiesAnimated:YES];
        return NO; // don't prevent other handling activities
      }];
    }
    /* detailview editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"Number edit";
      t.descriptionLabel.numberOfLines = 2;
      t.editInDetailView = YES;
      t.largeEditor = YES;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testNumber1"];
      NSNumberFormatter *fmt = [[[NSNumberFormatter alloc] init] autorelease];
      fmt.numberStyle = NSNumberFormatterDecimalStyle;
      t.valueConnector.formatter = fmt;
    }
    /* inplace number editing cell */ {
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
    /* inplace start date editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"Start date";
      t.editInDetailView = NO;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"startDate"];
      NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
      fmt.dateStyle = NSDateFormatterMediumStyle;
      fmt.timeStyle = NSDateFormatterMediumStyle;
      t.valueConnector.formatter = fmt;
      t.valueConnector.autoSaveValue = YES;
    }
    /* inplace start date editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"End date";
      t.editInDetailView = NO;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"endDate"];
      NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
      fmt.dateStyle = NSDateFormatterMediumStyle;
      fmt.timeStyle = NSDateFormatterMediumStyle;
      t.valueConnector.formatter = fmt;
      t.valueConnector.autoSaveValue = YES;
    }
    /* switch cell switch control */ {
      ZSwitchCell *sw = [c detailCell:[ZSwitchCell class]];
      sw.labelText = @"Allday";
      [sw.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"dateOnly"];
      sw.valueConnector.autoSaveValue = YES;
    }
    /* dateTime cell */ {
      ZDateTimeCell *d = [c detailCell:[ZDateTimeCell class]];
      d.labelText = @"Start\nEnd";
      d.descriptionLabel.numberOfLines = 2;
      d.valueLabel.numberOfLines = 2;
      [d.startDateConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"startDate"];
      [d.endDateConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"endDate"];
      [d.dateOnlyConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"dateOnly"];
      d.startDateConnector.autoSaveValue = YES;
      d.endDateConnector.autoSaveValue = YES;
      d.dateOnlyConnector.autoSaveValue = YES;
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
    /* password editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.neededModes = ZDetailDisplayModeEditing+ZDetailDisplayModeDetails;
      t.labelText = @"Password";
      t.editInDetailView = NO;
      t.returnKeyType = UIReturnKeyNext;
      t.secureTextEntry = YES;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testText"];
    }
    /* textView editing cell */ {
      ZTextViewCell *t = [c detailCell:[ZTextViewCell class]];
      t.neededModes = ZDetailDisplayModeDetails;
      t.labelText = @"TextView";
      t.editInDetailView = YES;
      t.multiline = YES;
      t.descriptionViewAdjustment = ZDetailCellItemAdjustTop;
      t.valueViewAdjustment = ZDetailCellItemAdjustTop;
      t.autoAdjustHeight = YES;
      t.standardCellHeight = 88;
      t.maxCellHeight = 120;
      t.textView.dataDetectorTypes = UIDataDetectorTypeAll;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"longTestText"];
    }
    /* inplace textView editing cell */ {
      ZTextViewCell *t = [c detailCell:[ZTextViewCell class]];
      t.neededModes = ZDetailDisplayModeDetails;
      t.labelText = @"Inplace TV";
      t.editInDetailView = NO;
      t.multiline = YES;
      t.descriptionViewAdjustment = ZDetailCellItemAdjustTop;
      t.valueViewAdjustment = ZDetailCellItemAdjustTop;
      t.autoAdjustHeight = YES;
      t.adjustWhileTyping = YES;
      t.standardCellHeight = 88;
      t.maxCellHeight = 300;
      t.textView.dataDetectorTypes = UIDataDetectorTypeAll;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"longTestText2"];
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
    /* Button */ {
      ZButtonCell *b = [c detailCell:[ZButtonCell class]];
      b.buttonStyle = ZButtonCellStyleCenterText;
      b.contentIndent = 50;
      b.labelText = @"Edit Values on/off";
      [b setTapHandler:^(ZDetailViewBaseCell *aCell, BOOL aInAccessory) {
        [c setDisplayMode:c.displayMode ^ ZDetailDisplayModeEditing+ZDetailDisplayModeViewing animated:YES];
        return YES; // handled
      }];
    }
    /* Button */ {
      ZButtonCell *b = [c detailCell:[ZButtonCell class]];
      b.buttonStyle = ZButtonCellStyleCenterText;
      b.contentIndent = 50;
      b.tableEditingStyle = UITableViewCellEditingStyleNone; 
      b.labelText = @"Details on/off";
      [b setTapHandler:^(ZDetailViewBaseCell *aCell, BOOL aInAccessory) {
        [c setDisplayMode:c.displayMode ^ ZDetailDisplayModeDetails+ZDetailDisplayModeBasics animated:YES];
        return YES; // handled
      }];
    }
    /* inplace editing cell */ {
      ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
      t.labelText = @"Inplace edit 2";
      t.contentIndent = 50;
      t.valueCellShare = 0.5;
      t.editInDetailView = NO;
      [t.valueConnector connectTo:[NSUserDefaults standardUserDefaults] keyPath:@"testText"];
    }
    [c endSection];
    return YES; // built
  }];
  [self.navigationController pushViewController:dtvc animated:YES];
}


- (IBAction)prefDetails:(id)sender
{
  ZDetailTableViewController *dtvc = [ZDetailTableViewController controllerWithTitle:@"Hallo"];
  dtvc.defaultCellStyle = ZDetailViewCellStylePrefs;
  dtvc.navigationMode = ZDetailNavigationModeRightButtonTableEditDone;
  //[dtvc setCellSetupHandler:^(ZDetailTableViewController *aController, UITableViewCell *aNewCell) {}];
  [self setupDetails:dtvc]; 
}


- (IBAction)entryEditDetails:(id)sender
{
  ZDetailTableViewController *dtvc = [ZDetailTableViewController controllerWithTitle:@"Hallo"];
  dtvc.defaultCellStyle = ZDetailViewCellStyleEntryDetail;
  dtvc.navigationMode = ZDetailNavigationModeRightButtonTableEditDone;
  [self setupDetails:dtvc]; 
}


- (IBAction)taskZDetails:(id)sender
{
  ZDetailTableViewController *dtvc = [ZDetailTableViewController controllerWithTitle:@"Hallo"];
  dtvc.defaultCellStyle = ZDetailViewCellStyleEntryDetail;
  dtvc.navigationMode = ZDetailNavigationModeRightButtonTableEditDone;
  [dtvc setCellSetupHandler:^(ZDetailTableViewController *aController, UITableViewCell *aNewCell) {
    // specific styling applied to every cell
    if ([aNewCell isKindOfClass:[ZDetailViewBaseCell class]]) {
      ZDetailViewBaseCell *cell = (ZDetailViewBaseCell *)aNewCell;
      cell.descriptionLabel.textAlignment = UITextAlignmentLeft;
      cell.valueLabel.textAlignment = UITextAlignmentLeft;
      cell.descriptionViewAdjustment = cell.descriptionViewAdjustment | ZDetailCellItemAdjustExtend;
    }
  }];
  [self setupDetails:dtvc]; 
}



@end
