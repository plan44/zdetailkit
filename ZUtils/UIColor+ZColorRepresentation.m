//
//  UIColor+ZColorRepresentation.m
//  ZUtils
//
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "UIColor+ZColorRepresentation.h"

@implementation UIColor (ZColorRepresentation)


#pragma mark - hex color (32-bit integer and hex string thereof)

+ (id)colorWithInt:(uint32_t)aIntColor
{
  UIColor *color = [UIColor
    colorWithRed:(double)((aIntColor >> 16) & 0xFF)/255.0
    green:(double)((aIntColor >> 8) & 0xFF)/255.0
    blue:(double)((aIntColor >> 0) & 0xFF)/255.0
    alpha:(double)(255-((aIntColor >> 24) & 0xFF))/255.0 // alpha is inversed: 255=transparent, 0=opaque
  ];
  return color;
}


- (uint32_t)intColor
{
  float red,green,blue,alpha;
  [self getRed:&red green:&green blue:&blue alpha:&alpha];
  return
    (((int)(red*255)) << 16) + // red
    (((int)(green*255)) << 8) + // green
    (((int)(blue*255)) << 0) + // blue
    (((int)((1-alpha)*255)) << 24); // inverted alpha
}


- (NSString *)hexColorString
{
  return [NSString stringWithFormat:@"%08X",self.intColor];
}

- (NSString *)webColorString
{
  return [NSString stringWithFormat:@"%06X",self.intColor & 0xFFFFFF];
}


+ (id)colorWithHexString:(NSString *)aHexColorString
{
  NSScanner *sc = [NSScanner scannerWithString:aHexColorString];
  uint32_t intColor = 0; // black by default
  [sc scanHexInt:&intColor];
  return [UIColor colorWithInt:intColor];
}


@end
