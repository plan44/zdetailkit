//
//  ZString_utils.m
//
//  Created by Lukas Zeller on 2011/06/29.
//  Copyright (c) 2011 by Lukas Zeller. All rights reserved.
//

#include "ZString_utils.h"


BOOL sameStringWithOptions(NSString *s1, NSString *s2, BOOL aNilSameAsEmptyString)
{
  // both nil count as equal
  if (s1==nil && s2==nil) return YES;
  // now depends on option
  if (!aNilSameAsEmptyString) {
    // only one of both nil means not equal 
    if ((s1==nil) != (s2==nil)) return NO; // one is nil, does not match with anything else
  }
  // nil means empty
  if (s1==nil) s1=@"";
  if (s2==nil) s2=@"";
  return [s1 isEqualToString:s2];
}


BOOL sameString(NSString *s1, NSString *s2)
{
  // both nil count as equal
  return sameStringWithOptions(s1, s2, YES);
}


// check if new passed string value for a property setter is same as current;
// accepts NSNull and converts it to nil (in aNewStringValueP)
// This is to check property setters, where we don't want a NSNull stored
BOOL samePropertyString(NSString **aNewStringValueP, NSString *aCurrentValue)
{
  // Null is treated as nil
  if ((id)*aNewStringValueP==[NSNull null]) *aNewStringValueP = nil;
  return sameStringWithOptions(*aNewStringValueP, aCurrentValue, NO);
}


BOOL sameData(NSData *d1, NSData *d2)
{
  // both nil or actually same object count as equal
  return (d1==d2) || (d1 && d2 && [d1 isEqualToData:d2]);
}


/* eof */
