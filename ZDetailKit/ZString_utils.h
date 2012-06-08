//
//  ZString_utils.h
//
//  Created by Lukas Zeller on 2011/06/29.
//  Copyright (c) 2011 by Lukas Zeller. All rights reserved.
//

#import <Foundation/Foundation.h>

BOOL sameStringWithOptions(NSString *s1, NSString *s2, BOOL aNilSameAsEmptyString);
BOOL sameString(NSString *s1, NSString *s2);
BOOL samePropertyString(NSString **aNewStringValueP, NSString *s2);
