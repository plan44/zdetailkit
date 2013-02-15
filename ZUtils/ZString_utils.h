//
//  ZString_utils.h
//
//  Created by Lukas Zeller on 2011/06/29.
//  Copyright (c) 2011-2013 by Lukas Zeller. All rights reserved.
//

#import <Foundation/Foundation.h>

// Superset of NSStringCompareOptions
enum {
  ZStringCompareOptionsNilEqualsEmpty = 0x01000000,
  ZStringCompareOptionsNSMask         = 0x00FFFFFF // bits 0..23 are reserved for NSStringCompareOptions
};
typedef NSUInteger ZStringCompareOptions;

NSComparisonResult compareStringWithOptions(NSString *s1, NSString *s2, NSStringCompareOptions aOptions);

BOOL sameStringWithOptions(NSString *s1, NSString *s2, NSStringCompareOptions aOptions);
BOOL sameString(NSString *s1, NSString *s2);
BOOL samePropertyString(NSString **aNewStringValueP, NSString *s2);

BOOL sameData(NSData *d1, NSData *d2);

