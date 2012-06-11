//
//  ZTextExpanderSupport.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#ifdef TEXTEXPANDER_SUPPORT

#import "ZTextExpanderSupport.h"

@implementation TextExpanderSingleton

static SMTEDelegateController *_sharedTextExpander;

+ (void)initialize
{
  _sharedTextExpander = nil;  
}


+ (SMTEDelegateController *)sharedTextExpander
{
  if (!_sharedTextExpander) {
    _sharedTextExpander = [[SMTEDelegateController alloc] init];
  }
  return _sharedTextExpander;
}


+ (BOOL)textExpanderEnabled
{
  BOOL isEnabled = NO;
  id enabledFlag = nil;
  @try {
    enabledFlag = [(id)[UIApplication sharedApplication].delegate valueForKey:@"textExpanderEnabled"];
    if (enabledFlag)
      isEnabled = [enabledFlag boolValue];
  }
  @catch (NSException *exception) {
    // just enabled if support is compiled in, but appDelegate does not have a enable/disable switch
    isEnabled = YES;
  }
  return isEnabled;
}


@end // TextExpanderSingleton

#endif // TEXTEXPANDER_SUPPORT
