//
//  ZTextExpanderSupport.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 19.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#ifdef TEXTEXPANDER_SUPPORT

#import <TextExpander/SMTEDelegateController.h>

@interface TextExpanderSingleton : NSObject
+ (void)initialize;
+ (SMTEDelegateController *)sharedTextExpander;
+ (BOOL)textExpanderEnabled;
@end

#endif // TEXTEXPANDER_SUPPORT