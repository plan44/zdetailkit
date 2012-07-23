/*
 *  ZColor_utils.m
 *
 *  Copyright 2011 by plan44.ch
 *
 */

#include "ZColor_utils.h"


BOOL GetRGBFromColor(UIColor *aColor, CGFloat *rP, CGFloat *gP, CGFloat *bP)
{
	if (aColor) {
    #ifdef __IPHONE_5_0
    if ([aColor respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
      // iOS 5 or later, use system function
      CGFloat a;
      return [aColor getRed:rP green:gP blue:bP alpha:&a];
    }
    else
    #endif
    {
      // before iOS 5, extract by hand
      CGColorRef col = aColor.CGColor;
      CGColorSpaceRef cspc = CGColorGetColorSpace(col);
      CGColorSpaceModel model = CGColorSpaceGetModel(cspc);
      float *components = (float *)CGColorGetComponents(col);
      if (model==kCGColorSpaceModelRGB) {
        *rP = components[0];
        *gP = components[1];
        *bP = components[2];
      }
      else if (model==kCGColorSpaceModelMonochrome) {
        *rP = *gP = *bP = components[0];
      }
      else {
        // error - bright red
        *rP = 1;
        *gP = 0;
        *bP = 0;
        return NO;
      }
    }
  }
  else {
    // no color = black
    *rP = 0;
    *gP = 0;
    *bP = 0;
  }
  return YES;
}


BOOL GetHSBFromColor(UIColor *aColor, CGFloat *hP, CGFloat *sP, CGFloat *bP)
{
  if (aColor) {
    #ifdef __IPHONE_5_0
    if ([aColor respondsToSelector:@selector(getHue:saturation:brightness:alpha:)]) {
      // iOS 5 or later, use system function
      CGFloat a;
      BOOL ok = [aColor getHue:hP saturation:sP brightness:bP alpha:&a];
      //DBGNSLOG(@"iOS: r,g,b=(%f,%f,%f) hsb=(%f,%f,%f)",r,g,b,*hP,*sP,*bP);
      return ok;
    }
    else
    #endif
    {
      CGFloat r,g,b;
      GetRGBFromColor(aColor, &r, &g, &b);
      // adapted from https://github.com/alessani/ColorConverter.git
      float h,s, l, v, m, vm, r2, g2, b2;
      h = 0;
      s = 0;
      v = MAX(r, g);
      v = MAX(v, b);
      m = MIN(r, g);
      m = MIN(m, b);
      l = (m+v)/2.0f;
      if (l <= 0.0)
        goto output;
      
      vm = v - m;
      s = vm;
      if (s > 0.0f){
        s/= (l <= 0.5f) ? (v + m) : (2.0 - v - m); 
      } else {
        goto output;
      }
      
      r2 = (v - r)/vm;
      g2 = (v - g)/vm;
      b2 = (v - b)/vm;      
      if (r == v) {
        h = (g == m ? 5.0f + b2 : 1.0f - g2);
      } else if (g == v){
        h = (b == m ? 1.0f + r2 : 3.0 - b2);
      } else {
        h = (r == m ? 3.0f + g2 : 5.0f - r2);
      }
      
      h/=6.0f;
    output:
      *hP = h;
      *sP = s;
      //*bP = l;
      *bP = v; // Apple's idea of B apparently is just the max of r,g,b
      //DBGNSLOG(@"ZUtil: r,g,b=(%f,%f,%f) hsb=(%f,%f,%f) mybright=%f",r,g,b,*hP,*sP,*bP,sqrtf(r*r*.241 + g*g*.571 + b*b*.188));
    }
  }
  else {
    // no color, black
    *hP = 0; *sP = 0; *bP = 0;
  }
  return YES;
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


