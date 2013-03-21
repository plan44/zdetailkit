//
//  ZOrientation.m
//  ZUtils
//
//  Created by Lukas Zeller on 2011/08/31.
//  Copyright (c) 2011-2013 plan44.ch. All rights reserved.
//

#import "ZOrientation.h"

@implementation ZOrientation

static int infoDictSupportedOrientations = -1;

+ (int)supportedOrientationsMaskFromInfoDict
{
  if (infoDictSupportedOrientations == -1) {
    infoDictSupportedOrientations = ZAppOrientationNone;
    NSArray *orientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];  
    for (NSString *o in orientations) {
      if ([o isEqualToString:@"UIInterfaceOrientationPortrait"])
        infoDictSupportedOrientations |= ZAppOrientationPortrait;
      else if ([o isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"])
        infoDictSupportedOrientations |= ZAppOrientationPortraitUpsideDown;
      else if ([o isEqualToString:@"UIInterfaceOrientationLandscapeRight"])
        infoDictSupportedOrientations |= ZAppOrientationLandscapeRight;
      else if ([o isEqualToString:@"UIInterfaceOrientationLandscapeLeft"])
        infoDictSupportedOrientations |= ZAppOrientationLandscapeLeft;
    }
  }
  return infoDictSupportedOrientations;
}


+ (BOOL)supportsInterfaceOrientation:(UIInterfaceOrientation)aInterfaceOrientation orientationsMask:(int)aOrientationsMask;
{
  int o = ZAppOrientationNone;
  switch (aInterfaceOrientation) {
    case UIInterfaceOrientationPortrait: o = ZAppOrientationPortrait; break;
    case UIInterfaceOrientationPortraitUpsideDown: o = ZAppOrientationPortraitUpsideDown; break;
    case UIInterfaceOrientationLandscapeRight: o = ZAppOrientationLandscapeRight; break;
    case UIInterfaceOrientationLandscapeLeft: o = ZAppOrientationLandscapeLeft; break;
    default: o = ZAppOrientationNone; break;
  }
  BOOL ret = (o & aOrientationsMask)!=0;
  return ret;
}


+ (BOOL)supportsInterfaceOrientation:(UIInterfaceOrientation)aInterfaceOrientation
{
  return [self supportsInterfaceOrientation:aInterfaceOrientation orientationsMask:[self supportedOrientationsMaskFromInfoDict]];
}


@end
