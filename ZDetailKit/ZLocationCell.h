//
//  ZLocationCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 17.02.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"

/// cell to represent a location
///
/// The location is represented by a name (which is shown in the cell) and a geocoordinate (which is
/// shown as a pin on the map when the cell editor is open).
/// The MapKit based editor is implemented in ZMapLocationEdit
@interface ZLocationCell : ZDetailViewBaseCell

/// value connector for the location text
@property (weak, readonly,nonatomic) ZDetailValueConnector *textValueConnector;

/// value connector for the geocoordinate
/// @note the value connected must be a NSValue wrapping a CLLocationCoordinate2D
@property (weak, readonly,nonatomic) ZDetailValueConnector *coordinateValueConnector;

/// the edited text
@property (strong,nonatomic) NSString *editedText;

/// the edited coordinate (boxed in a NSValue)
@property (strong,nonatomic) NSValue *editedCoordinate;

@end
