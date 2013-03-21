//
//  ZKeyChainWrapper.m
//  ZUtils
//
//  Created by Lukas Zeller on 2011/08/16.
//  Copyright (c) 2011-2013 plan44.ch. All rights reserved.
//

#import "ZKeyChainWrapper.h"

@implementation ZKeyChainWrapper

static ZKeyChainWrapper *sharedKeyChainWrapper = nil;

NSString* const kZKeyChainWrapperErrorDomain = @"ch.plan44.ZKeyChainWrapper";


- (id)initWithServicePrefix:(NSString *)aServicePrefix
{
  if ((self = [super init])) {
    servicePrefix = aServicePrefix;
  }
  return self;
}



+ (ZKeyChainWrapper *)sharedKeyChainWrapper
{
  if (!sharedKeyChainWrapper) {
    sharedKeyChainWrapper = [[self alloc] initWithServicePrefix:
      [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] stringByAppendingString:@"."]
    ];
  }
  return sharedKeyChainWrapper;
}


// Most useful info about keychain on iOS so far:
// http://useyourloaf.com/blog/2010/4/28/keychain-duplicate-item-when-adding-password.html
// Main point is that Apple sample is wrong - what constitues the unique key is account & service, not AttrGeneric


- (NSMutableDictionary *)keychainQueryForService:(NSString *)service account:(NSString *)account
{
  NSString *uniqueService = [servicePrefix stringByAppendingString:service];
  NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass, // class is "generic password"    
    [uniqueService dataUsingEncoding:NSUTF8StringEncoding], (__bridge id)kSecAttrGeneric, // use service as generic attr as well, must be NSData!
    account, (__bridge id)kSecAttrAccount,
    uniqueService, (__bridge id)kSecAttrService,
    nil
  ];
  return query;
}



- (NSString *)passwordOrEmptyForService:(NSString *)service account:(NSString *)account
{
  NSString *result = [self passwordForService:service account:account error:NULL];
  if (!result) result = @"";
  return result;
}


- (NSString *)passwordForService:(NSString *)service account:(NSString *)account error:(NSError **)error
{
  OSStatus status = kZKeyChainWrapperErrorBadArguments;
  NSString *result = nil;
  if ([service length]>0 && [account length]>0) {
    CFDataRef passwordData = NULL;
    // get the basic query data
    NSMutableDictionary *keychainQuery = [self keychainQueryForService:service account:account];
    // add specifics for finding a entry
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData]; // return password data (rather than all attributes with kSecReturnAttributes=YES)
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit]; // only one in case of multiples
    // issue query
    status = SecItemCopyMatching(
      (__bridge CFDictionaryRef)keychainQuery,
      (CFTypeRef *)&passwordData
    );
    if (status==noErr && [(__bridge NSData *)passwordData length]>0) {
      // we got a password
      result = [[NSString alloc]
        initWithData:(__bridge NSData *)passwordData
        encoding:NSUTF8StringEncoding
      ];
    }
    if (passwordData!=NULL) {
      CFRelease(passwordData);
    }
  }
  if (status!=noErr && error!=NULL) {
    *error = [NSError errorWithDomain:kZKeyChainWrapperErrorDomain code:status userInfo:nil];
  }
  return result;
}



- (BOOL)removePasswordForService:(NSString *)service account:(NSString *)account error:(NSError **)error
{
  OSStatus status = kZKeyChainWrapperErrorBadArguments;
  if ([service length]>0 && [account length]>0) {
    NSMutableDictionary *keychainQuery = [self keychainQueryForService:service account:account];
    status = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
  }
  if (status!=noErr && error!=NULL) {
    *error = [NSError errorWithDomain:kZKeyChainWrapperErrorDomain code:status userInfo:nil];
  }
  return status==noErr;
}



- (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account error:(NSError **)error
{
  OSStatus status = kZKeyChainWrapperErrorBadArguments;
  if ([service length]>0 && [account length]>0) {
    // remove old version first
    [self removePasswordForService:service account:account error:nil];
    // now add new version
    if ([password length]>0) {
      NSMutableDictionary *keychainQuery = [self keychainQueryForService:service account:account];
      NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
      [keychainQuery setObject:passwordData forKey:(__bridge id)kSecValueData];
      status = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
    }
  }
  if (status!=noErr && error!=NULL) {
    *error = [NSError errorWithDomain:kZKeyChainWrapperErrorDomain code:status userInfo:nil];
  }
  return status==noErr;
}


@end