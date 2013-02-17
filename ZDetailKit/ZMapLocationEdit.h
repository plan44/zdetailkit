//
//  ZMapLocationEdit.h
//  TodoZ
//
//  Created by Lukas Zeller on 2011/07/02.
//  Copyright 2011 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "ZDetailKit.h"


@class ZMapLocationAnnotation;

@interface ZMapLocationEdit : ZDetailViewBaseController <UIGestureRecognizerDelegate>
{
  // UI elements
  MKMapView *mapView;
  UIButton *userPosButton;
  UIButton *pinButton;
  UITextField *locationTextField;
}
// connectors for the edited values
@property (weak, readonly,nonatomic) ZDetailValueConnector *textValueConnector;
@property (weak, readonly,nonatomic) ZDetailValueConnector *coordinateValueConnector;

// other properties and methods
@property (nonatomic, assign) CLLocationCoordinate2D locationCoordinate;
@property (assign) BOOL showUserLocation;

@property (nonatomic, strong) IBOutlet UITextField *locationTextField;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UIButton *userPosButton;
@property (nonatomic, strong) IBOutlet UIButton *pinButton;

- (IBAction)locationTextEditEnded:(UITextField *)aTextField;
- (IBAction)locationTextManualValueChange:(id)sender;
- (IBAction)searchLocationOnMap:(id)sender;
- (IBAction)userPositionToggle:(id)sender;
- (IBAction)pinToggle:(id)sender;


// ZDetailViewController protocol
@property(weak, nonatomic) id<ZDetailViewParent> parentDetailViewController;


@end // ZMapLocationEdit



@interface ZMapLocationAnnotation : NSObject <MKAnnotation> {
@private
  ZMapLocationEdit *locationEdit;
}
@property(nonatomic, readonly, copy) NSString *title;
@property(nonatomic, readonly, copy) NSString *subtitle;
@property(readonly,nonatomic) CLLocationCoordinate2D coordinate;

- (id)initWithLocationEdit:(ZMapLocationEdit *)aLocationEdit;

@end // ZMapLocationAnnotation



