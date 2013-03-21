//
//  ZStringToCoordinate2DTransformer.h
//  ZUtils
//
//  Created by Lukas Zeller on 2013-02-17.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import "ZStringToCoordinate2DTransformer.h"

#import <CoreLocation/CoreLocation.h>


@implementation ZStringToCoordinate2DTransformer

#pragma mark - NSValueTransformer methods

+ (BOOL)allowsReverseTransformation
{
  return YES;
}

+ (Class)transformedValueClass
{
  // CLLocationCoordinate2D is a struct, will be passed as NSValue
  return [NSValue class];
}


- (id)transformedValue:(id)aValue
{
  // no input transforms to no coordinate
  if (aValue && [aValue isKindOfClass:[NSString class]]) {
    // parse longitude,latitude out of string
    CLLocationCoordinate2D coord;
    NSScanner *s = [NSScanner scannerWithString:aValue];
    if ([s scanDouble:&coord.latitude]) {
      if ([s scanString:@"," intoString:NULL]) {
        if ([s scanDouble:&coord.longitude]) {
          // pack into NSValue and return
          return [NSValue valueWithBytes:&coord objCType:@encode(CLLocationCoordinate2D)];
        }
      }
    }
  }
  return nil;
}


- (id)reverseTransformedValue:(id)aValue
{
  if (aValue && [aValue isKindOfClass:[NSValue class]]) {
    NSValue *val = (NSValue *)aValue;
    if (strcmp([val objCType],@encode(CLLocationCoordinate2D))==0) {
      CLLocationCoordinate2D coord;
      [val getValue:&coord];
      if (CLLocationCoordinate2DIsValid(coord)) {
        return [NSString stringWithFormat:@"%f,%f", coord.latitude, coord.longitude];
      }
    }
  }
  return nil;
}

@end
