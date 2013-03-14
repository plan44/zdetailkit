//
//  ZTextFieldCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 21.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZTextFieldCell.h"

#import "ZTextExpanderSupport.h"
#import "ZDetailTableViewController.h"

@interface ZTextFieldCell ( /* class extension */ )
{
  NSString *editedText;
}
@end


@implementation ZTextFieldCell

@synthesize textField, largeEditor;


- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    // no textfield by default, created on demand (when we actually edit in the cell, and
    // not in a subeditor
    textField = nil;
    largeEditor = NO;
    autoDetail = YES;
    editedText = nil; // none so far
  }
  return self;
}




#pragma mark - value management

- (void)setEditedText:(NSString *)aEditedText
{
  if (!samePropertyString(&aEditedText,editedText)) {
    editedText = aEditedText;
    if (self.editInDetailView || !self.allowsEditing) {
      // update value label
      if (self.secureTextEntry) {
        // just show bullets
        self.valueLabel.text = [@"" stringByPaddingToLength:[self.editedText length] withString:@"●" startingAtIndex:0]; // Unicode BLACK CIRCLE $25CF
      }
      else {
        // show the actual text
        self.valueLabel.text = editedText;
      }
      // IMPORTANT! This is needed to force UILabel text visible again
      [self setNeedsLayout];
    }
  }
}


- (NSString *)editedText
{
  return editedText;
}


#pragma mark - properties

@synthesize autoDetail;


- (void)setMultiline:(BOOL)aMultiline
{
  if (aMultiline) {
    // multiline editing in textField always needs (multi-line)detail editor, disable auto
    autoDetail = NO;
    self.editInDetailView = YES;
  }
  [super setMultiline:aMultiline];
}


- (void)setEditInDetailView:(BOOL)aEditInDetailView
{
  autoDetail = NO;
  [super setEditInDetailView:aEditInDetailView];
}


- (void)setAutoDetail:(BOOL)aAutoDetail
{
  if (aAutoDetail!=autoDetail) {
    autoDetail = aAutoDetail;
    [self setNeedsUpdate];
  }
}



#pragma mark - cell configuration


- (void)updateForDisplay
{
  // reconfigure views
  if (autoDetail) {
    // automatically decide if we should use inplace editing
    self.editInDetailView = self.multiline || (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad);
  }
  if (self.editInDetailView || !self.allowsEditing) {
    // display only or editing with detail view: value is shown in text label
    if (self.allowsEditing) {
      // editable - show disclosure indicator
      self.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;      
    }
    else {
      // non-editable - no disclosure indicator
      self.accessoryType = UITableViewCellAccessoryNone; // view only, no disclosure indicator
    }
    self.valueLabel.hidden = NO; // make sure label exists
    self.valueConnector.valuePath = @"editedText";
    self.valueView = self.valueLabel; // put under layout control
    // remove the text field, we have the value label
    if (textField) {
      [textField removeFromSuperview]; // remove from view
      textField = nil;
    }
  }
  else {
    // value is shown in text field so it can be edited directly
    self.accessoryType = UITableViewCellAccessoryNone;
    self.textField.hidden = NO; // force creation of textfield
    self.valueView = self.textField; // put under custom layout control
    self.valueConnector.valuePath = @"textField.text";
    // hide the value label, we have the text field instead
    self.editedText = nil; // none, such that when we switch back this will get updated
    self.valueLabel.hidden = YES;
  }
  // update texts
  if (textField) {
    textField.placeholder = self.placeholderText;
  }
  // update cell basics
  [super updateForDisplay];
}


#pragma mark - detail editor

- (BOOL)useTextViewEditor
{
  // textView when cell wants large editor
  return largeEditor;
}


#pragma mark - textField action handlers


- (void)textFieldEditingStarted
{
  // let cell know
  [self startedEditing];
}


- (void)textFieldExited
{
  [self endedEditingWithGotoNext:NO];  
}


- (void)textFieldDoneKeyPressed
{
  [self endedEditingWithGotoNext:self.returnKeyType==UIReturnKeyNext];
}





#pragma mark - embedded text field


- (void)layoutSubviews
{
	[super layoutSubviews];
  // now copy the font
  if (textField) {
    textField.font = self.valueLabel.font;
    textField.textColor = self.valueLabel.textColor;
  }
}


// will be called from detailviewcontroller on all other cells when a new cell gets focus
- (void)defocusCell
{
  // Note: direct call works too, at least in iOS 5 - but in older versions probable sometimes not, so we delay it
  //[textField performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0];
  [textField resignFirstResponder];
  [super defocusCell];
}


// called to try to begin editing (e.g. getting kbd focus) in this cell. Returns YES if possible
- (BOOL)beginEditing
{
  if (textField) {
    [textField becomeFirstResponder];
    return YES; // can edit here
  }
  return NO; // cannot start editing here
}



- (UITextField *)textField
{
  if (textField==nil) {
    // need to be created now
    textField = [[UITextField alloc] initWithFrame:CGRectMake(100, 7, 180, 30)]; // need a height when we have no border
    textField.borderStyle = UITextBorderStyleNone;
    #if LAYOUT_DEBUG
    textField.backgroundColor = [UIColor colorWithRed:0.964 green:0.548 blue:1.000 alpha:1.000];
    #endif
    textField.autoresizingMask = UIViewAutoresizingNone;
    textField.contentMode = UIViewContentModeScaleToFill;
    // - important: without this, clear button is centered, but text is not
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    // textfield other options
    // Note: font cannot be copied here, because valueLabel might not have set it's font size correctly
    textField.textAlignment = self.valueLabel.textAlignment;
    // keyboard options
    textField.secureTextEntry = self.secureTextEntry;
    textField.keyboardType = self.keyboardType;
    textField.returnKeyType = self.returnKeyType;
    textField.autocapitalizationType = self.autocapitalizationType;
    textField.autocorrectionType = self.autocorrectionType;
    textField.spellCheckingType = self.spellCheckingType;
    // clear button only on left-aligned fields by default (looks ugly otherwise)
    textField.clearButtonMode = self.valueLabel.textAlignment==UITextAlignmentLeft ? UITextFieldViewModeWhileEditing : UITextFieldViewModeNever;
		// KVO does not catch all changes to textField.text (KVO triggers when field resigns first responder,
    // but that does not always happen reliably in time depending on how view is dismissed
    // So: value connector needs a notice when the value has changed
    [textField addTarget:self.valueConnector action:@selector(markInternalValueChanged)
    	forControlEvents:UIControlEventEditingChanged
    ];
		// need notice when done (return/next) key is pressed so we can remove keyboard
    [textField addTarget:self action:@selector(textFieldDoneKeyPressed)
    	forControlEvents:UIControlEventEditingDidEndOnExit
    ];
		// need notice when field looses focus
    [textField addTarget:self action:@selector(textFieldExited)
        forControlEvents:UIControlEventEditingDidEnd
     ];
		// need notice when starting edit so we can bring cell in view
    [textField addTarget:self action:@selector(textFieldEditingStarted)
    	forControlEvents:UIControlEventEditingDidBegin
    ];
    // add textExpander to in place editor
    #ifdef TEXTEXPANDER_SUPPORT
    if ([TextExpanderSingleton textExpanderEnabled]) {
      textField.delegate = [TextExpanderSingleton sharedTextExpander];
    }
    #endif    
    // add field
    [self.contentView addSubview:textField];
    [self setNeedsLayout];
  }
  return textField;
}



@end
