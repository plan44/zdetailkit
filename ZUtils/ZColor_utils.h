/*
 *  ZColor_utils.h
 *
 *  Copyright 2011 by plan44.ch
 *
 */

#import <Foundation/Foundation.h>

// Color helper routines
BOOL GetRGBFromColor(UIColor *aColor, CGFloat *rP, CGFloat *gP, CGFloat *bP);
BOOL GetHSBFromColor(UIColor *aColor, CGFloat *hP, CGFloat *sP, CGFloat *bP);
CGFloat GetBrighntessFromRGB(CGFloat red, CGFloat green, CGFloat blue);
CGFloat GetBrighntessFromColor(UIColor *aColor);
