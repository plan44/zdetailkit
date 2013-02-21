//
//  ZMapLocationEdit.m
//  TodoZ
//
//  Created by Lukas Zeller on 2011/07/02.
//  Copyright 2011 plan44.ch. All rights reserved.
//

#import "ZMapLocationEdit.h"

#import <AddressBook/AddressBook.h>


@interface ZMapLocationEdit () {
  // edited values
  BOOL locationTextIsUserInput;
  // internal
  ZMapLocationAnnotation *locationAnnotation;
}
// private methods
- (void)makeSureUserLocationIsCentered;
- (void)updateLocationTextForPosition;
- (void)showInMaps;
@end


@implementation ZMapLocationEdit


@synthesize locationTextField;
@synthesize mapView;
@synthesize userPosButton;
@synthesize pinButton;

@synthesize textValueConnector, coordinateValueConnector;

- (id)init
{
  if ((self = [super initWithNibName:@"ZMapLocationEdit" bundle:nil])) {
    // Custom initialization
    locationCoordinate = kCLLocationCoordinate2DInvalid; // none so far
    locationAnnotation = nil; // none so far
    // valueConnector for the location text field (directly connect the textField's text property)
    textValueConnector = [self registerValueConnector:
      [ZDetailValueConnector connectorWithValuePath:@"locationTextField.text" owner:self]
    ];
    textValueConnector.nilNulValue = @""; // default to show external nil/null as empty string
    // valueConnector for the location coordinate (connected to my own property)
    coordinateValueConnector = [self registerValueConnector:
      [ZDetailValueConnector connectorWithValuePath:@"locationCoordinate" owner:self]
    ];
    coordinateValueConnector.nilNulValue = [NSValue valueWithBytes:&kCLLocationCoordinate2DInvalid objCType:@encode(CLLocationCoordinate2D)] ; // default to show external nil/null as no coordinate
  }
  return self;
}



#pragma mark - ZDetailViewBaseController integration


- (void)detailViewWillOpen:(BOOL)aAnimated
{
  [super detailViewWillOpen:aAnimated];
  [locationTextField performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0]; // keyboard not shown!
}


- (void)detailViewWillClose:(BOOL)aAnimated
{
  DBGNSLOG(
    @"closed map with position long=%f, lat=%f, deltaLong=%f, deltaLat=%f",
    mapView.centerCoordinate.longitude, mapView.centerCoordinate.latitude,
    mapView.region.span.longitudeDelta, mapView.region.span.latitudeDelta
  );
}


- (void)setActive:(BOOL)aActive
{
  if (self.active!=aActive) {
    // activate value connectors
    if (aActive) {
      // Activate
      [super setActive:YES];
      // - set up map view with current data
      locationTextField.placeholder = self.title;
      locationTextIsUserInput = [self.locationTextField.text length]>0; // non-empty text to start with counts as user input
      if (CLLocationCoordinate2DIsValid(locationCoordinate)) {
        // don't show current user pos
        self.showUserLocation = NO;
        // center map on saved coordinate
        [mapView setRegion:MKCoordinateRegionMakeWithDistance(locationCoordinate, 1000, 1000)];
        // refresh pin location
        self.locationCoordinate = self.locationCoordinate;
      }
      else {
        // center on current location
        self.showUserLocation = YES;
        [mapView setRegion:MKCoordinateRegionMakeWithDistance(mapView.userLocation.location.coordinate, 1000, 1000)];
      }
    }
    else {
      // deactivate
      [super setActive:NO];
    }
  }
}


#pragma mark Property handlers

@synthesize locationCoordinate;

- (void)setLocationCoordinate:(CLLocationCoordinate2D)aLocationCoordinate
{
  // set new coordinate
  locationCoordinate = aLocationCoordinate;
  if (CLLocationCoordinate2DIsValid(aLocationCoordinate)) {
    // show location as coordinate
    if (!locationAnnotation) {
      // - none set yet, create it
      locationAnnotation = [[ZMapLocationAnnotation alloc] initWithLocationEdit:self];
    }
    else {
      // - remove old position
      [mapView removeAnnotation:locationAnnotation];
    }
    // - add (or re-add) to map
    [mapView addAnnotation:locationAnnotation];
    // reflect status on pin button
    pinButton.selected = YES;
  }
  else {
    // no coordinate, remove annotation
    if (locationAnnotation) {
      [mapView removeAnnotation:locationAnnotation];
       locationAnnotation = nil;
    }
    // reflect status on pin button
    pinButton.selected = NO;
  }
}


- (BOOL)showUserLocation
{
  return mapView.showsUserLocation;
}


- (void)setShowUserLocation:(BOOL)aShowUserLocation
{
  // actually set map view's user tracking
  mapView.showsUserLocation = aShowUserLocation;
  // and reflect status on button
  userPosButton.selected = aShowUserLocation;
}


#pragma controller and delegate methods


- (void)mapView:(MKMapView *)aMapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
  [self makeSureUserLocationIsCentered];
}


- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
  // if it's the user location, just return nil.
  if ([annotation isKindOfClass:[MKUserLocation class]])
    return nil;
  if ([annotation isKindOfClass:[ZMapLocationAnnotation class]]) {
    // my own
    // - try to dequeue an existing pin view first
    static NSString* MapLocationAnnotationID = @"MapLocationAnnotationID";
    MKPinAnnotationView* pinView = (MKPinAnnotationView *)
      [aMapView dequeueReusableAnnotationViewWithIdentifier:MapLocationAnnotationID];
    if (!pinView) {
      // none exist, create new one
      pinView = [[MKPinAnnotationView alloc]
        initWithAnnotation:annotation reuseIdentifier:MapLocationAnnotationID];
      pinView.pinColor = MKPinAnnotationColorPurple;
      pinView.animatesDrop = YES;
      pinView.canShowCallout = YES;
      // can be dragged
      pinView.draggable = YES;
      // add a detail disclosure button
      UIButton* detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
      [detailButton addTarget:self action:@selector(pinDetails) forControlEvents:UIControlEventTouchUpInside];
      pinView.rightCalloutAccessoryView = detailButton;
    }
    else
    {
      pinView.annotation = nil; // reset
      pinView.annotation = annotation; // force re-loading title
    }
    return pinView;
  }
  // none of my annotations
  return nil;
}


- (void)pinDetails
{
  // Open in Maps
  [self showInMaps];
}


- (void)pinDraggedTo:(CLLocationCoordinate2D)aCoordinate
{
  // already visible pin changed its position
  // - just set new coordinate
  locationCoordinate = aCoordinate;
  // - reverse geocode new location
  [self updateLocationTextForPosition];
}



- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  // there's a touch in the map, remove the keyboard
  [locationTextField resignFirstResponder];
  // ...but always pretend we're not interested in the touch at all, so mapView will work as normal
  return NO;
}


#pragma mark - appearance


- (void)viewDidLoad
{
  [super viewDidLoad];
  // add gesture recognizer that will never fire, but allows to see when the mapview is touched
  UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dummySelectorNeverUsed)];
  tgr.cancelsTouchesInView = NO; // let touches get through
  tgr.numberOfTapsRequired = 1;
  tgr.delegate = self;
  [mapView addGestureRecognizer:tgr];
}


- (void)viewDidUnload
{
  [self setMapView:nil];
  [self setLocationTextField:nil];
  [self setUserPosButton:nil];
  [self setPinButton:nil];
  [super viewDidUnload];
}


- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}


#pragma mark - geocoding and reverse geocoding

typedef void (^FindLocationCompletionHandler)(CLLocationCoordinate2D aLocation);


-(void)findLocationWithCompletionHandler:(FindLocationCompletionHandler)aCompletionHandler
{
  // check for iOS 6.1 advanced map search
  Class mkLocalSearchClass = Nil;
  mkLocalSearchClass = NSClassFromString(@"MKLocalSearch");
  if (mkLocalSearchClass) {
    // iOS 6.1 advanced natural language map query is available, use it
    // - create request
    MKLocalSearchRequest *searchRequest = [[NSClassFromString(@"MKLocalSearchRequest") alloc] init];
    searchRequest.naturalLanguageQuery = locationTextField.text; // the search text
    searchRequest.region =  mapView.region; // base search on current map region
    // - create the search
    MKLocalSearch *localSearch = [[mkLocalSearchClass alloc] initWithRequest:searchRequest];
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
      if (response && [response.mapItems count]>0) {
        // only use first result
        MKMapItem *mapItem = [response.mapItems objectAtIndex:0];
        CLLocation *loc = mapItem.placemark.location;
        // call the handler
        aCompletionHandler(loc.coordinate);
      }
      else {
        aCompletionHandler(kCLLocationCoordinate2DInvalid);
      }
    }];
  }
  else {
    // use iOS 5.0 geoCoder, if available (pre iOS5, search is not supported here)
    Class geoCoderClass = Nil;
    geoCoderClass = NSClassFromString(@"CLGeocoder");
    if (geoCoderClass) {
      // CLGeocoder is available, use it
      CLGeocoder *geoCoder = [[geoCoderClass alloc] init];
      [geoCoder geocodeAddressString:locationTextField.text inRegion:nil completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks && [placemarks count]>0) {
          // use first placemark
          CLPlacemark *place = [placemarks objectAtIndex:0];
          CLLocation *loc = place.location;
          // call the handler
          aCompletionHandler(loc.coordinate);
        }
        else {
          // call the handler with invalid coordinate marker
          aCompletionHandler(kCLLocationCoordinate2DInvalid);
        }
      }];
    }
  }
}



- (void)updateLocationTextForPosition
{
  if (!locationTextIsUserInput) {
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    CLLocation *loc = [[CLLocation alloc]
      initWithCoordinate:locationCoordinate altitude:0 horizontalAccuracy:0 verticalAccuracy:-1 timestamp:[NSDate date]
    ];
    [geoCoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
      if (placemarks && [placemarks count]>0) {
        // use first placemark
        CLPlacemark *place = [placemarks objectAtIndex:0];
        locationTextField.text = [NSString stringWithFormat:
          @"%@, %@",
          [place.addressDictionary valueForKey:@"Street"],
          [place.addressDictionary valueForKey:@"City"]
        ];
      }
    }];
  }
}


#pragma mark - map operations


- (void)makeSureUserLocationIsCentered
{
  // move user in view
  [mapView setCenterCoordinate:mapView.userLocation.location.coordinate animated:YES];
}


#if TARGET_IPHONE_SIMULATOR==0
#define MAPS_BASEURL @"maps:"
#else
#define MAPS_BASEURL @"http://maps.google.com/maps?"
#endif


- (void)showInMaps
{
  if (CLLocationCoordinate2DIsValid(locationCoordinate)) {
    #ifdef __IPHONE_6_0
    if (NSClassFromString(@"MKMapItem") && [MKMapItem instancesRespondToSelector:@selector(openInMapsWithLaunchOptions:)]) {
      // we are on iOS 6 with the new Apple Maps, use the new method
      MKPlacemark *pm = [[MKPlacemark alloc] initWithCoordinate:locationCoordinate addressDictionary:nil];
      MKMapItem *mi = [[MKMapItem alloc] initWithPlacemark:pm];
      if ([locationTextField.text length]>0)
        mi.name = locationTextField.text;
      [mi openInMapsWithLaunchOptions:nil];
    }
    else
    #endif
    {
      // iOS5 or older
      NSString *mapURL = nil;
      if ([locationTextField.text length]>0)
        mapURL =
          [NSString stringWithFormat:MAPS_BASEURL @"q=%@@%.6f,%.6f",
            [locationTextField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
            locationCoordinate.latitude,locationCoordinate.longitude
          ];
      else
        mapURL = [NSString stringWithFormat:MAPS_BASEURL @"ll=%.6f,%.6f",locationCoordinate.latitude,locationCoordinate.longitude];
      // launch google maps
      // - may cause applicationWillTerminate (before iPhoneOS 3.0) or prepareForPossibleTermination (iPhoneOS 4.0) which saves all open editing
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapURL]];
    }
  }
}




#pragma mark - actions


- (IBAction)locationTextEditEnded:(UITextField *)aTextField
{
  // hide keyboard
  [aTextField performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0]; // keyboard not shown!
}


- (IBAction)locationTextManualValueChange:(id)sender
{
  // classify location text as manually entered, so it will not be overwritten by reverse geocoder
  locationTextIsUserInput = [locationTextField.text length]>0; // manual input if not empty
  // let connector know
  self.textValueConnector.unsavedChanges = YES;
}



- (IBAction)searchLocationOnMap:(id)sender
{
  // hide keyboard
  [locationTextField performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0]; // keyboard not shown!
  // hide user location
  self.showUserLocation = NO;
  // show center
  [self findLocationWithCompletionHandler:^(CLLocationCoordinate2D aLocation) {
    if (CLLocationCoordinate2DIsValid(aLocation)) {
      mapView.centerCoordinate = aLocation;
      // set location and generate annotation
      self.locationCoordinate = aLocation;
      // find text for location if text is empty
      if ([locationTextField.text length]==0)
        [self updateLocationTextForPosition];
      else
        locationTextIsUserInput = NO; // keep search term for now, but when we move the pin text should get updated
    }
  }];
}


- (IBAction)userPositionToggle:(id)sender
{
  self.showUserLocation = !self.showUserLocation;
  if (self.showUserLocation) {
    [self makeSureUserLocationIsCentered];
  }
}

- (IBAction)pinToggle:(id)sender
{
  if (CLLocationCoordinate2DIsValid(self.locationCoordinate)) {
    // pin exists, must be removed
    if (MKMapRectContainsPoint(mapView.visibleMapRect, MKMapPointForCoordinate(self.locationCoordinate))) {
      // pin is visible, so what we want is deleting the pin
      self.locationCoordinate = kCLLocationCoordinate2DInvalid;
    }
    else {
      // pin is not visible, move it into view
      [mapView setCenterCoordinate:self.locationCoordinate animated:YES];
    }
  }
  else {
    // pin does not exist, drop it
    // - hide user location
    self.showUserLocation = NO;
    // - move pin to center of the map
    self.locationCoordinate = mapView.centerCoordinate;
    // - name location
    [self updateLocationTextForPosition];
  }
}


@end // ZMapLocationEdit



@implementation ZMapLocationAnnotation

- (id)initWithLocationEdit:(ZMapLocationEdit *)aLocationEdit
{
  if ((self = [super init])) {
    locationEdit = aLocationEdit;
  }
  return self;
}


- (NSString *)title
{
  if ([locationEdit.locationTextField.text length]>0) {
    return locationEdit.locationTextField.text;
  }
  else {
    return @" ";
  }
}

- (NSString *)subtitle
{
  return nil;
}

- (CLLocationCoordinate2D)coordinate
{
  return locationEdit.locationCoordinate;
}

// when dragging, this will be called
- (void)setCoordinate:(CLLocationCoordinate2D)aCoordinate
{
  [locationEdit pinDraggedTo:aCoordinate];
}

@end // ZMapLocationAnnotation

