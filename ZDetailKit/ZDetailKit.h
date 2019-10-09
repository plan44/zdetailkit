//
//  ZDetailKit.h
//
//  Created by Lukas Zeller on 15.02.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//


// common
#import "ZDetailEditing.h"
#import "ZDBGMacros.h"

// ZUtils
#import "ZCustomI8n.h"

// controllers
#import "ZDetailTableViewController.h"

// cells
#import "ZButtonCell.h"
#import "ZSwitchCell.h"
#import "ZSegmentChoicesCell.h"
#import "ZSliderCell.h"
#import "ZTextFieldCell.h"
#import "ZTextViewCell.h"
#import "ZDateTimeCell.h"
#import "ZColorChooserCell.h"
#import "ZChoiceListCell.h"

// Note: ZLocationCell requires MapKit and CoreLocation frameworks to be included in the app,
//       which in turn requires that the app declares usage of location in NSLocationAlwaysUsageDescription,
//       NSLocationWhenInUseUsageDescription, and NSLocationAlwaysAndWhenInUseUsageDescription in info.plist
#import "ZLocationCell.h"

// EOF
