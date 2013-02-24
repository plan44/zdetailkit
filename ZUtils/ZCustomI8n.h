//
//  ZCustomI8n.h
//
//  Created by Lukas Zeller on 12.09.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Customizable internationalisation: if Z_CUSTOM_I8N is defined non-zero in a project, all strings localized with
/// the ZLocalizedString and ZLocalizedStringWithDefault macros will first look up strings from a
/// customer provided string file at Z_CUSTOM_I8N_PATH. This allows for end-user aided i8n, in that
/// end user can create and test a internationalisation by storing a customized .strings file
/// for example in Documents via iTunes access.

/// define Z_CUSTOM_I8N_PATH (e.g. in your prefix file) to set a different path
#ifndef Z_CUSTOM_I8N_PATH
#define Z_CUSTOM_I8N_PATH @"Documents/Custom_Localizable.strings"
#endif

/// define Z_CUSTOM_I8N to non-zero (e.g. in your prefix file) to enable custom internationalisation
#if Z_CUSTOM_I8N
#define ZLocalizedString(key, comment) zCustomI8nString(key,nil)
#define ZLocalizedStringWithDefault(key, default) zCustomI8nString(key,default)
#else
#define ZLocalizedString(key, comment) NSLocalizedString(key, comment)
#define ZLocalizedStringWithDefault(key, default) [[NSBundle mainBundle] localizedStringForKey:(key) value:default table:nil]
#endif

#if Z_CUSTOM_I8N
NSString *zCustomI8nString(NSString *aKey, NSString *aDefault);
#endif