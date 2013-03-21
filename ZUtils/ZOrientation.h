//
//  ZOrientation.h
//  ZUtils
//
//  Created by Lukas Zeller on 2011/08/31.
//  Copyright (c) 2011-2013 plan44.ch. All rights reserved.
//


enum ZAppOrientations {
  ZAppOrientationNone = 0,
  ZAppOrientationPortrait = 1<<0, 
  ZAppOrientationPortraitUpsideDown = 1<<1,
  ZAppOrientationLandscapeRight = 1<<2,
  ZAppOrientationLandscapeLeft = 1<<3
};


/// ZOrientation is a collection of class methods for handling interface orientation
///
/// Using supportsInterfaceOrientation: in [UIViewController shouldAutorotateToInterfaceOrientation:]
/// avoids ugly hard-coded and device-specific implementations of orientation support. Instead,
/// info.plist settings determine orientation support consistently.
@interface ZOrientation : NSObject

/// returns the supported interface orientations as specified in the app's info.plist
/// @returns a bitmask for all supported orientations (see ZAppOrientations enum)
/// @note the info.plist is queried only once, after that, the result is cached for the lifetime of the app
+ (int)supportedOrientationsMaskFromInfoDict;

/// check a UIInterfaceOrientation value against a ZOrientation bitmask
/// @return YES if passed orientation is supported
/// @param aInterfaceOrientation orientation to check
/// @param aOrientationMask ZOrientation mask to check against
+ (BOOL)supportsInterfaceOrientation:(UIInterfaceOrientation)aInterfaceOrientation orientationsMask:(int)aOrientationsMask;

/// check a UIInterfaceOrientation value against supported orientations as specified in the app's info.plist
/// @return YES if passed orientation is supported
/// @param aInterfaceOrientation orientation to check
/// @note this class method is intended to be called from [UIViewController shouldAutorotateToInterfaceOrientation:] to avoid
///  hard-coding supported orientations in every view controller.
+ (BOOL)supportsInterfaceOrientation:(UIInterfaceOrientation)aInterfaceOrientation;

@end
