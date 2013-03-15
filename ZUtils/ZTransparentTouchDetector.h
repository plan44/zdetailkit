//
//  ZTransparentTouchDetector.h
//  ZUtils
//
//  Created by Lukas Zeller on 15.03.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

/// creates a UIGestureRecognizer which can be added to a UIView to receive a notification (handler block called)
/// when a UIView sees a touch, *without interfering with actual touch and gesture processing* (hence _transparent_ detector)
@interface ZTransparentTouchDetector : UITapGestureRecognizer <UIGestureRecognizerDelegate>

typedef void (^ZTransparentTouchDetectorHandler)(ZTransparentTouchDetector *aGestureRecognizer);

/// create a ZTransparentTouchDetector
/// @param aTouchHandler this handler is called when the view or any of its subviews is touched.
+ (ZTransparentTouchDetector *)transparentTouchDetectorWithHandler:(ZTransparentTouchDetectorHandler)aTouchHandler;


@end
