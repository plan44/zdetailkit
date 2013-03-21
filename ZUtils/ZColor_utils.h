//
//  ZColor_utils.h
//  ZUtils
//
//  Copyright (c) 2011-2013 plan44.ch. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Get RGB components from a UIColor
BOOL GetRGBFromColor(UIColor *aColor, CGFloat *rP, CGFloat *gP, CGFloat *bP);

/// Get HSB components from a UIColor
BOOL GetHSBFromColor(UIColor *aColor, CGFloat *hP, CGFloat *sP, CGFloat *bP);

/// Get brightness from R,G,B components
CGFloat GetBrighntessFromRGB(CGFloat red, CGFloat green, CGFloat blue);

/// Get brightness from a UIColor
CGFloat GetBrighntessFromColor(UIColor *aColor);
