/*
 *  ZColor_utils.m
 *
 *  Copyright 2011-2013 by plan44.ch
 *
 */

#include "ZColor_utils.h"


BOOL GetRGBFromColor(UIColor *aColor, CGFloat *rP, CGFloat *gP, CGFloat *bP)
{
	if (aColor) {
    CGFloat a;
    return [aColor getRed:rP green:gP blue:bP alpha:&a];
  }
  else {
    // no color = black
    *rP = 0;
    *gP = 0;
    *bP = 0;
    return YES;
  }
}


BOOL GetHSBFromColor(UIColor *aColor, CGFloat *hP, CGFloat *sP, CGFloat *bP)
{
  if (aColor) {
    CGFloat a;
    return [aColor getHue:hP saturation:sP brightness:bP alpha:&a];
  }
  else {
    // no color, black
    *hP = 0; *sP = 0; *bP = 0;
    return YES;
  }
}


CGFloat GetBrighntessFromRGB(CGFloat red, CGFloat green, CGFloat blue)
{
	return
		sqrtf(
      red*red*.241 +
      green*green*.571 +
      blue*blue*.188
    );
}


CGFloat GetBrighntessFromColor(UIColor *aColor)
{
	CGFloat r,g,b;
  GetRGBFromColor(aColor, &r, &g, &b);
  return GetBrighntessFromRGB(r, g, b);
}
