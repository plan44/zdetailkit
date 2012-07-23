//
//  ZStringToUIColorTransformer.m
//
//  Created by Lukas Zeller on 23.07.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZStringToUIColorTransformer.h"

#import "UIColor+ZColorRepresentation.h"

@implementation ZStringToUIColorTransformer

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
  if (aValue && [aValue isKindOfClass:[NSString class]]) {
    return [UIColor colorWithHexString:aValue];
  }
  return nil;
}


- (id)reverseTransformedValue:(id)aValue
{
  if (aValue && [aValue isKindOfClass:[UIColor class]]) {
    return [(UIColor *)aValue hexColorString];
  }
  return nil;
}

@end


#pragma mark - web variant, outputs only web color compatible (6 digit) strings, no alpha

@implementation ZWebStringToUIColorTransformer

- (id)reverseTransformedValue:(id)aValue
{
  if (aValue && [aValue isKindOfClass:[UIColor class]]) {
    return [(UIColor *)aValue webColorString];
  }
  return nil;
}

@end