//
//  ZTextViewCell.m
//
//  Created by Lukas Zeller on 25.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZTextViewCell.h"

#import "ZTextExpanderSupport.h"
#import "ZDetailTableViewController.h"


@interface ZTextViewCell ( /* class extension */ )
{
  #ifdef TEXTEXPANDER_SUPPORT
  SMTEDelegateController *textExpander;
  #endif
  CGFloat dynamicCellHeight;
  BOOL recalcDynamicCellHeight;
}

@end

@implementation ZTextViewCell

@synthesize textView;


- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    // the text view
    textView = nil; // created on demand
    autoAdjustHeight = NO;
    adjustWhileTyping = NO;
    maxCellHeight = 10000;
    dynamicCellHeight = -1;
    recalcDynamicCellHeight = YES;
    #ifdef TEXTEXPANDER_SUPPORT
    textExpander = nil;
    #endif
    self.valueLabel.hidden = YES; // don't show value label    
  }
  return self;
}


- (void)dealloc
{
	[textView release];
  #ifdef TEXTEXPANDER_SUPPORT
  [textExpander release];
  #endif
	[super dealloc];
}


#pragma mark - value management


- (NSString *)editedText
{
  return self.textView.text;
}


- (void)setEditedText:(NSString *)aEditedText
{
  self.textView.text = aEditedText;
}

    

#pragma mark - cell configuration


- (void)updateForDisplay
{
  // connect textview (also creates it)
  self.valueConnector.valuePath = @"textView.text";  
  // reconfigure views
  self.valueView = self.textView; // put textView under layout control
  if (self.editInDetailView || !self.allowsEditing) {
    // display only or editing with detail view: textView is in read-only mode
    self.textView.editable = NO;
    self.textView.userInteractionEnabled = YES; // still need user interaction for scrolling and data detectors
    if (self.allowsEditing) {
      // editable - show disclosure indicator
      self.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;      
    }
    else {
      // non-editable - no disclosure indicator
      self.accessoryType = UITableViewCellAccessoryNone; // view only, no disclosure indicator
    }
  }
  else {
    // value is directly editable in the textView
    self.textView.editable = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
  }
  // update cell basics
  [super updateForDisplay];
}




#pragma mark - UITextView delegate methods

- (void)textViewDidChange
{
  // make sure value connector knows about unsaved changes even if KVO does not work
  self.valueConnector.unsavedChanges = YES;
}



- (void)textViewDidBeginEditing:(UITextView *)aTextView
{
  [self startedEditing];
}



- (void)textViewDidChange:(UITextView *)aTextView
{
  if (adjustWhileTyping) {
    // live updating of cellheight
    recalcDynamicCellHeight = YES;
    if ([self hasNewCellHeight]) {
      [self setNeedsReloadAnimated:YES];
      [self cellEditingRectChanged];
    }
  }
  // make sure value connector knows about unsaved changes even if KVO does not work
  self.valueConnector.unsavedChanges = YES;  
}



- (void)textViewDidEndEditing:(UITextView *)aTextView
{
  // cause height recalculation and cause reloading cell if so
  recalcDynamicCellHeight = YES;
  if ([self hasNewCellHeight]) {
    [self setNeedsReloadAnimated:YES];
    [self cellEditingRectChanged];
  }
  [self endedEditingWithGotoNext:self.returnKeyType==UIReturnKeyNext];
}



- (BOOL)textView:(UITextView *)tv shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	// pressing Done ends editing
	if ((tv.returnKeyType!=UIReturnKeyDefault) && (range.length==0) && [text isEqual:@"\n"]) {
		[self textViewDidEndEditing:tv]; // simulate end of editing by calling the delegate method directly
    return NO;
  }
  return YES;
}




#pragma mark - embedded text view management


@synthesize autoAdjustHeight, adjustWhileTyping, maxCellHeight;


- (CGFloat)cellHeight
{
  if (!autoAdjustHeight || dynamicCellHeight<0)
    return [super cellHeight]; // not dynamic or height cannot yet be calculated -> return standard (minimal) height
  // check if we need recalculation
  [self hasNewCellHeight];
  DBGNSLOG(@"CellHeight = %g",dynamicCellHeight);
  return dynamicCellHeight; // return dynamic height
}


#define TEXTVIEW_SCROLLBAR_MARGIN_RIGHT 16

- (BOOL)hasNewCellHeight
{
  if (autoAdjustHeight && recalcDynamicCellHeight && self.contentView) {
    recalcDynamicCellHeight = NO; // doing it now
    // we can assume that the textView has been layouted and it's width is known
    CGSize maxsiz = CGSizeMake(textView.bounds.size.width-TEXTVIEW_SCROLLBAR_MARGIN_RIGHT, self.maxCellHeight+100-self.contentMargins.height*2);
    NSString *txtToMeasure = textView.text;
    if ([txtToMeasure hasSuffix:@"\n"])
      txtToMeasure = [textView.text stringByAppendingString:@" "]; // need one space on next line to make sure it is measured
    CGSize siz = [txtToMeasure sizeWithFont:textView.font constrainedToSize:maxsiz lineBreakMode:UILineBreakModeClip];
    // derive the dynamic cellheight
    CGFloat minHeight = [super cellHeight];
    CGFloat newHeight = round(siz.height + 2*self.contentMargins.height);
    // check limits
    if (newHeight<minHeight)
      newHeight = minHeight;
    if (newHeight>=maxCellHeight) {
      newHeight = maxCellHeight;
      self.textView.scrollEnabled = YES;
    }
    else {
      self.textView.scrollEnabled = NO;
    }
    // check if changed
    if (newHeight!=dynamicCellHeight) {
      // has changed, assign
      dynamicCellHeight = newHeight;
      return YES; // has changed
    }
  }
  return NO;  
}


- (void)layoutSubviews
{
	[super layoutSubviews];
  if (textView) {
    // copy the font
    textView.font = self.valueLabel.font;
    textView.textColor = self.valueLabel.textColor;
    // measure the text height
    if ([self hasNewCellHeight]) {
      // make sure table gets reloaded once again
      [self setNeedsTableReload];      
    }
    // anyway, adapt the textview height to the table view height
    CGRect tf = textView.frame;
    tf.origin.y = self.contentMargins.height;
    tf.size.height = self.contentView.bounds.size.height-2*self.contentMargins.height;
    textView.frame = tf;
  }
}


- (void)textViewTapped
{
  if (self.editInDetailView && self.allowsEditing) {
    // forward to handler
    [self.cellOwner cellTapped:self inAccessory:NO];
  }
}


// called to try to begin editing (e.g. getting kbd focus) in this cell. Returns YES if possible
- (BOOL)beginEditing
{
  if (textView && !self.editInDetailView  && self.allowsEditing) {
    [textView becomeFirstResponder];
    return YES; // can edit here
  }
  return NO; // cannot start editing here
}


// called when detail editor for my content has finished
- (void)editorFinishedWithCancel:(BOOL)aCancelled
{
  if (self.autoAdjustHeight && !aCancelled) {
    // cause height recalculation and cause reloading cell if so
    recalcDynamicCellHeight = YES;
    if ([self hasNewCellHeight]) {
      [self setNeedsReloadAnimated:YES];
    }
  }
}


// will be called from detailviewcontroller on all other cells when a new cell gets focus
- (void)defocusCell
{
  // Note: direct call works too, at least in iOS 5 - but in older versions probable sometimes not, so we delay it
  //[textView performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0];
  [textView resignFirstResponder];
  [super defocusCell];
}



- (UITextView *)textView
{
  if (textView==nil) {
    textView = [[UITextView alloc] initWithFrame:CGRectMake(100, 7, 180, 40)]; // need a height when we have no border
    #if LAYOUT_DEBUG
    textView.backgroundColor = [UIColor colorWithRed:0.964 green:0.548 blue:1.000 alpha:1.000];
    #endif
    textView.autoresizingMask = UIViewAutoresizingNone; //UIViewAutoresizingFlexibleWidth+UIViewAutoresizingFlexibleHeight;
    textView.contentMode = UIViewContentModeScaleToFill;
    textView.contentInset = UIEdgeInsetsMake(-8, -8, -8, -8);
    // textView other options
    // Note: font cannot be copied here, because valueLabel might not have set it's font size correctly
    textView.textAlignment = self.valueLabel.textAlignment;
    textView.backgroundColor = self.contentView.backgroundColor;
    // keyboard options
    textView.keyboardType = self.keyboardType;
    textView.returnKeyType = self.multiline ? UIReturnKeyDefault : self.returnKeyType; // multiline needs to have default return key
    textView.autocapitalizationType = self.autocapitalizationType;
    textView.autocorrectionType = self.autocorrectionType;
    textView.spellCheckingType = self.spellCheckingType;
    textView.secureTextEntry = self.secureTextEntry;
    textView.dataDetectorTypes = UIDataDetectorTypeNone;
    textView.editable = NO; // not really, but we need textViewShouldBeginEditing
    // add tap-to-open-detail gesture recognizer
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]
      initWithTarget:self action:@selector(textViewTapped)
    ];
    tgr.numberOfTapsRequired = 1;
    tgr.cancelsTouchesInView = NO;
    [textView addGestureRecognizer:tgr];
    [tgr release];
		// KVO does not catch all changes to textView.text (KVO triggers when field resigns first responder,
    // but that does not always happen reliably in time depending on how view is dismissed
    // So: we need notice when editing so we can set the value connector dirty
    #ifdef TEXTEXPANDER_SUPPORT
    textExpander = nil;
    if ([SMTEDelegateController textExpanderEnabled]) {    
      // need my own instance, because I need my own delegate
      textExpander = [[SMTEDelegateController alloc] init];
      [textExpander setNextDelegate:self];
      textView.delegate = textExpander;
    }
    else
    #endif // TEXTEXPANDER_SUPPORT
    {
      // editing callbacks to myself
      textView.delegate = (id<UITextViewDelegate>)self;
    }
    // add textView
    [self.contentView addSubview:textView];
  }
  return textView;
}



@end
