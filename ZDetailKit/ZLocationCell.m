//
//  ZLocationCell.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 17.02.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import "ZLocationCell.h"

#import "ZMapLocationEdit.h"

#import "ZString_utils.h"

@implementation ZLocationCell

@synthesize textValueConnector;
@synthesize coordinateValueConnector;

- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    // valueConnector for text
    textValueConnector = [self registerValueConnector:
      [ZDetailValueConnector connectorWithValuePath:@"editedText" owner:self]
    ];
    textValueConnector.nilNulValue = @""; // default to show external nil/null as empty string
    // valueConnector for coordinate
    coordinateValueConnector = [self registerValueConnector:
      [ZDetailValueConnector connectorWithValuePath:@"editedCoordinate" owner:self]
    ];
    coordinateValueConnector.nilNulValue = [NSValue valueWithBytes:&kCLLocationCoordinate2DInvalid objCType:@encode(CLLocationCoordinate2D)];
  }
  return self;
}


#pragma mark - value management

@synthesize editedText;

- (void)setEditedText:(NSString *)aEditedText
{
  if (!samePropertyString(&aEditedText,editedText)) {
    editedText = aEditedText;
    // show the actual text
    self.valueLabel.text = editedText;
    // IMPORTANT! This is needed to force UILabel text visible again
    [self setNeedsLayout];
  }
}


@synthesize editedCoordinate;

// coordinate is invisible on the cell level, just holds the edits made in ZMapLocationEdit


#pragma mark - detail editor


- (UIViewController *)editorForTapInAccessory:(BOOL)aInAccessory
{
  ZMapLocationEdit *mle = nil;
  if (self.allowsEditing) {
    // create a map view editor which allows editing the location text and geo coordinate
    mle = [[ZMapLocationEdit alloc] init];
    // set up the title
    mle.title = self.detailTitleText;
    mle.navigationItem.title = self.detailTitleText;
    // use save and cancel buttons
    mle.navigationMode = ZDetailNavigationModeLeftButtonCancel+ZDetailNavigationModeRightButtonSave;
    // connect the editors to our internal values
    [mle.textValueConnector connectTo:self.textValueConnector keyPath:@"internalValue"];
    [mle.coordinateValueConnector connectTo:self.coordinateValueConnector keyPath:@"internalValue"];
  }
  return mle;
}


@end
