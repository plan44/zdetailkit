//
//  ZCustomI8n.m
//  ZUtils
//
//  Created by Lukas Zeller on 12.09.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#if Z_CUSTOM_I8N

#import "ZCustomI8n.h"

static NSDictionary *zcustomI8nDict = nil;
static BOOL zcustomi8ntested = NO;


static void zCustomI8nInit()
{
  // check for custom strings file (in source, so we can put it there for testing)
  zcustomI8nDict = [NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:Z_CUSTOM_I8N_PATH]];
  zcustomi8ntested = YES;
}



NSString *zCustomI8nString(NSString *aKey, NSString *aDefault)
{
  if (!zcustomi8ntested) {
    // check for custom internationalisation file
    zCustomI8nInit();
  }
  if (zcustomI8nDict) {
    // custom translation is active, first try to load from custom dict
    NSString *result = [zcustomI8nDict objectForKey:aKey];
    if (result) return result;
    // otherwise, use standard localisation
  }
  // use standard localisation
  if (aDefault) {
    return [[NSBundle mainBundle] localizedStringForKey:(aKey) value:aDefault table:nil];
  }
  else {
    return NSLocalizedString(aKey, "dummy");
  }
}

#endif // Z_CUSTOM_I8N