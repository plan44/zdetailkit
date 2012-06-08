//
//  ZOrientation.h
//
//  Created by Lukas Zeller on 2011/08/31.
//  Copyright 2011 plan44.ch. All rights reserved.
//


enum ZAppOrientations {
  ZAppOrientationNone = 0,
  ZAppOrientationPortrait = 1<<0, 
  ZAppOrientationPortraitUpsideDown = 1<<1,
  ZAppOrientationLandscapeRight = 1<<2,
  ZAppOrientationLandscapeLeft = 1<<3
};


@interface ZOrientation

+ (int)supportedOrientationsMaskFromInfoDict;
+ (BOOL)supportsInterfaceOrientation:(UIInterfaceOrientation)aInterfaceOrientation orientationsMask:(int)aOrientationsMask;
+ (BOOL)supportsInterfaceOrientation:(UIInterfaceOrientation)aInterfaceOrientation;

@end
