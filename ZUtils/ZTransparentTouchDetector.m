//
//  ZTransparentTouchDetector.m
//  ZUtils
//
//  Created by Lukas Zeller on 15.03.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import "ZTransparentTouchDetector.h"

@interface ZTransparentTouchDetector () {
  ZTransparentTouchDetectorHandler handler;
}

@end


@implementation ZTransparentTouchDetector

+ (ZTransparentTouchDetector *)transparentTouchDetectorWithHandler:(ZTransparentTouchDetectorHandler)aTouchHandler
{
  return [[ZTransparentTouchDetector alloc] initWithHandler:aTouchHandler];
}


- (id)initWithHandler:(ZTransparentTouchDetectorHandler)aTouchHandler
{
  // gesture recognizer that will never fire, but allows to see when its view (including any of its subviews!)
  // is touched without interfering in any way with touch processing otherwise
  if ((self = [super initWithTarget:self action:@selector(dummySelectorNeverUsed)])) {
    self.cancelsTouchesInView = NO; // let touches get through
    self.numberOfTapsRequired = 1;
    self.delegate = self;
    // save handler
    handler = [aTouchHandler copy];
  }
  return self;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  // call the handler
  handler(self);
  // ...but always pretend we're not interested in the touch at all, so pickerView will work as normal
  return NO;
}


@end
