//
//  ZIntToUIColorTransformer.m
//  ZUtils
//
//  Created by Lukas Zeller on 23.07.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZIntToUIColorTransformer.h"

#import "UIColor+ZColorRepresentation.h"

@implementation ZIntToUIColorTransformer

#pragma mark - NSValueTransformer methods


+ (BOOL)allowsReverseTransformation
{
  return YES;
}


+ (Class)transformedValueClass
{
  return [UIColor class];
}



- (id)transformedValue:(id)aValue
{
  // no input transforms to no color
  if (aValue && [aValue isKindOfClass:[NSNumber class]]) {
    return [UIColor colorWithInt:[aValue intValue]];
  }
  return nil;
}


- (id)reverseTransformedValue:(id)aValue
{
  if (aValue!=nil && [aValue isKindOfClass:[UIColor class]]) {
    UIColor *myColor = (UIColor *)aValue;
    return [NSNumber numberWithInt:[myColor intColor]];
  }
  return nil;
}

@end
