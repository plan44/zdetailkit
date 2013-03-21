//
//  ZDVTViewController.h
//  ZDetailViewTest
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZDVTViewController : UIViewController

- (IBAction)entryEditDetails:(id)sender;
- (IBAction)prefDetails:(id)sender;
- (IBAction)taskZDetails:(id)sender;

@property (strong, nonatomic) IBOutlet UILabel *plan44linkLabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *presentationModeSegControl;

@end
