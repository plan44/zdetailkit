//
//  ZString_utils.m
//
//  Created by Lukas Zeller on 2011/06/29.
//  Copyright (c) 2011-2013 by Lukas Zeller. All rights reserved.
//

#include "ZString_utils.h"



NSComparisonResult compareStringWithOptions(NSString *s1, NSString *s2, NSStringCompareOptions aOptions)
{
  // both nil or both actually same string object count as equal
  if (s1==s2) return NSOrderedSame;
  // now depends on option
  if ((aOptions & ZStringCompareOptionsNilEqualsEmpty)==0) {
    // nil is not same as empty: only one of both nil means not equal
    // (both can't be nil here because then they would be equal, checked above)
    if (s1==nil) return NSOrderedAscending; // nil before non-nil
    if (s2==nil) return NSOrderedDescending; // nil after non-nil
  }
  // nil means empty
  if (s1==nil) s1=@"";
  if (s2==nil) s2=@"";
  return [s1 compare:s2 options:aOptions & ZStringCompareOptionsNSMask];
}


BOOL sameStringWithOptions(NSString *s1, NSString *s2, NSStringCompareOptions aOptions)
{
  return compareStringWithOptions(s1, s2, aOptions)==NSOrderedSame;
}


BOOL sameString(NSString *s1, NSString *s2)
{
  // both nil count as equal
  return sameStringWithOptions(s1, s2, ZStringCompareOptionsNilEqualsEmpty);
}



// check if new passed string value for a property setter is same as current;
// accepts NSNull and converts it to nil (in aNewStringValueP)
// This is to check property setters, where we don't want a NSNull stored
BOOL samePropertyString(NSString **aNewStringValueP, NSString *aCurrentValue)
{
  // Null is treated as nil
  if ((id)*aNewStringValueP==[NSNull null]) *aNewStringValueP = nil;
  return sameStringWithOptions(*aNewStringValueP, aCurrentValue, 0);
}


BOOL sameData(NSData *d1, NSData *d2)
{
  // both nil or actually same object count as equal
  return (d1==d2) || (d1 && d2 && [d1 isEqualToData:d2]);
}



/* eof */
