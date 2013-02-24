//
//  ZKeyChainWrapper.h
//
//  Created by Lukas Zeller on 2011/08/16.
//  Copyright 2011-2013 plan44.ch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <Security/SecItem.h>

enum {
  kZKeyChainWrapperErrorBadArguments = -1001,
  kZKeyChainWrapperErrorNoPassword = -1002
};

extern NSString* const kZKeyChainWrapperErrorDomain;

/// ZKeyChainWrapper provides a simple way to store and retrieve passwords/secrets in the keychain
@interface ZKeyChainWrapper : NSObject
{
  NSString *servicePrefix;
}

/// returns a shared instance of the keyChain wrapper using the bundle identifier
/// (plus a dot) as a prefix to service and account strings
+ (ZKeyChainWrapper *)sharedKeyChainWrapper; 

/// create a keychain wrapper with a custom service prefix (can be nil to have none)
- (id)initWithServicePrefix:(NSString *)aServicePrefix;

/// get the password or empty string for given service/account
- (NSString *)passwordOrEmptyForService:(NSString *)service account:(NSString *)account;

/// get the password or nil for given service/account
- (NSString *)passwordForService:(NSString *)service account:(NSString *)account error:(NSError **)error;

/// remove password for given service/account
- (BOOL)removePasswordForService:(NSString *)service account:(NSString *)account error:(NSError **)error;

/// store new password for given service/account
- (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account error:(NSError **)error;

@end
