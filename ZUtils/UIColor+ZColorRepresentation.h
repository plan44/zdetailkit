//
//  UIColor+ZColorRepresentation.h
//
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (ZColorRepresentation)

// 32-bit 0xaarrggbb representation of color
// where aa=inverse alpha (0=opaque, 0xFF=transparent) for compatibility with 24-bit color values
+ (id)colorWithInt:(uint32_t)aHexColor;
- (uint32_t)intColor;

// hex string representation (6 char as used in web colors, 8 char including alpha)
- (NSString *)hexColorString;
- (NSString *)webColorString;
+ (id)colorWithHexString:(NSString *)aHexColorString;


@end
