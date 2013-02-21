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

/// MapKit based editor for a location text and a 2D map coordinate
///
/// Normally, this editor is used by ZLocationCell, but it can also be used independently
@interface ZMapLocationEdit : ZDetailViewBaseController <UIGestureRecognizerDelegate>
{
  // UI elements
  MKMapView *mapView;
  UIButton *userPosButton;
  UIButton *pinButton;
  UITextField *locationTextField;
}

/// value connector for the location text
@property (weak, readonly,nonatomic) ZValueConnector *textValueConnector;

/// value connector for the geocoordinate
/// @note the value connected must be a NSValue wrapping a CLLocationCoordinate2D
@property (weak, readonly,nonatomic) ZValueConnector *coordinateValueConnector;

/// This is the currently pinned location.
///
/// If no pin is set, it returns kCLLocationCoordinate2DInvalid
@property (nonatomic, assign) CLLocationCoordinate2D locationCoordinate;

/// If set, the user's current location is displayed on the map (blue dot)
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



