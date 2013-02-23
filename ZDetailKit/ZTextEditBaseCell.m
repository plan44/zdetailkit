//
//  ZTextEditBaseCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 25.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZTextEditBaseCell.h"

// these are needed for creating the detail editors
#import "ZDetailTableViewController.h"
#import "ZTextFieldCell.h"
#import "ZTextViewCell.h"

@implementation ZTextEditBaseCell

@synthesize valueConnector;

- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    // no textfield by default, created on demand (when we actually edit in the cell, and
    // not in a subeditor
    multiline = NO;
    editInDetailView = YES;
    keyboardType = UIKeyboardTypeDefault;
    returnKeyType = UIReturnKeyDone; // default to "done"
    autocapitalizationType = UITextAutocapitalizationTypeNone;
    autocorrectionType = UITextAutocorrectionTypeDefault;
    spellCheckingType = UITextSpellCheckingTypeDefault;
    secureTextEntry = NO;
    // valueConnector
    valueConnector = [self registerValueConnector:
      [ZValueConnector connectorWithValuePath:@"editedText" owner:self]
    ];
    valueConnector.nilNulValue = @""; // default to show external nil/null as empty string
  }
  return self;
}




#pragma mark - properties

// UITextInputTraits compatible properties, will be passed to real editing controls
@synthesize keyboardType;
@synthesize returnKeyType;
@synthesize autocapitalizationType;
@synthesize autocorrectionType;
@synthesize spellCheckingType;
@synthesize secureTextEntry;


#pragma mark - value management


// should return true when cell is presenting an empty value (such that empty cells can be hidden in some modes)
- (BOOL)presentingEmptyValue
{
  // no string or empty string counts as empty
  id v = self.valueConnector.internalValue;
  BOOL empty = v==nil || [v length]==0;
  return empty;
}


- (NSString *)editedText
{
  // none in base class
  return nil;
}


- (void)setEditedText:(NSString *)editedText
{
  // none in base class
}


#pragma mark - properties

@synthesize multiline, editInDetailView;


- (void)setMultiline:(BOOL)aMultiline
{
  if (aMultiline!=multiline) {
    multiline = aMultiline;
    // needs reconfiguration of views
    [self setNeedsUpdate];
  }
}


- (void)setEditInDetailView:(BOOL)aEditInDetailView
{
  if (aEditInDetailView!=editInDetailView) {
    editInDetailView = aEditInDetailView;
    // needs reconfiguration of views
    [self setNeedsUpdate];
  }
}


#pragma mark - detail editor

- (BOOL)useTextViewEditor
{
  // base class always uses text view
  return YES;
}


- (UIViewController *)editorForTapInAccessory:(BOOL)aInAccessory
{
  ZDetailTableViewController *dtvc = nil;
  if (self.editInDetailView && self.allowsEditing) {
    dtvc = [ZDetailTableViewController controllerWithTitle:self.detailTitleText];
    dtvc.defaultCellStyle = UITableViewCellStyleDefault+ZDetailViewCellStyleFlagAutoLabelLayout+ZDetailViewCellStyleFlagAutoStyle;
    dtvc.navigationMode = ZDetailNavigationModeLeftButtonCancel+ZDetailNavigationModeRightButtonSave;
    [dtvc setBuildDetailContentHandler:^(ZDetailTableViewController *c) {
      c.autoStartEditing = YES; // auto-start editing in the field
      c.detailTableView.scrollEnabled = NO; // prevent scrolling
      [c startSection];
      ZTextEditBaseCell *tb = nil;
      if (self.useTextViewEditor) {
        /* text view cell */ {
          ZTextViewCell *t = [c detailCell:[ZTextViewCell class]];
          t.standardCellHeight = 175; // good size for iPhone
          t.multiline = self.multiline; // inherit multiline
          tb = t;
        }
      }
      else {
        /* text field cell */ {
          ZTextFieldCell *t = [c detailCell:[ZTextFieldCell class]];
          tb = t;
        }
      }
      // common properties
      tb.valueLabel.font = self.valueLabel.font; // inherit font
      tb.valueCellShare = 1; // use entire cell
      tb.editInDetailView = NO; // in-place edit
      tb.detailTitleText = self.detailTitleText; // inherit detailtitle
      tb.placeholderText = self.placeholderText; // inherit placeholder 
      tb.keyboardType = self.keyboardType;
      tb.returnKeyType = UIReturnKeyDone; // done by default, becomes return for multilines automatically
      tb.autocapitalizationType = self.autocapitalizationType;
      tb.autocorrectionType = self.autocorrectionType;
      tb.autocorrectionType = self.autocorrectionType;
      tb.secureTextEntry = self.secureTextEntry;
      [tb setEditingEndedHandler:^(ZDetailViewBaseCell *t2) {
        [c dismissDetailViewWithSave:YES animated:YES];
        return YES;
      }];
      [tb.valueConnector connectTo:self.valueConnector keyPath:@"internalValue"];
      [c endSection];
      return YES; // built
    }];
  }
  return dtvc;
}


@end
