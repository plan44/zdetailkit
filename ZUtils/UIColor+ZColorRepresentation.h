//
//  UIColor+ZColorRepresentation.h
//
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

/// This category on UIColor adds methods to convert colors from and to 32-bit and 24bit integer 
/// as well as web-style (6 char hex string) representations.
@interface UIColor (ZColorRepresentation)

/// Create a UIColor from a 32-bit integer representation
/// @return UIColor
/// @param aHexColor 32-bit integer, hex 0xAArrggbb
///  where AA=inverse alpha (0=opaque, 0xFF=transparent) for compatibility with 24-bit color values
///  and rr,gg,bb are 0..255 red, green, blue color components.
+ (id)colorWithInt:(uint32_t)aHexColor;

/// returns 32-bit integer representation of color
/// @return 32-bit integer, hex 0xAArrggbb
///  where AA=inverse alpha (0=opaque, 0xFF=transparent) for compatibility with 24-bit color values
///  and rr,gg,bb are 0..255 red, green, blue color components.
- (uint32_t)intColor;

/// returns 8 char hex string representation of color
/// @return hex string representation of intColor
- (NSString *)hexColorString;

/// returns 6 char hex string representation as used for web colors
/// @return hex string representation of (intColor & 0xFFFFFF) which is color without alpha
- (NSString *)webColorString;

/// Create a UIColor from a hex string representation
/// @return UIColor
/// @param aHexColorString hex string AArrggbb
///  where AA=inverse alpha (0=opaque, 0xFF=transparent) for compatibility with 24-bit color values
///  and rr,gg,bb are 0..255 red, green, blue color components.
+ (id)colorWithHexString:(NSString *)aHexColorString;


@end
