//
//  ZKeyChainSecretCell.m
//
//  Created by Lukas Zeller on 2011/08/16.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import "ZKeyChainSecretCell.h"

#import "ZKeyChainWrapper.h"


@interface ZKeyChainSecretCell ()

@property (retain, nonatomic) NSString *secret;

@end


@implementation ZKeyChainSecretCell


- (id)initWithStyle:(ZDetailViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier
{
  if ((self = [super initWithStyle:aStyle reuseIdentifier:aReuseIdentifier])) {
    // auto-configure as password cell
    self.secureTextEntry = YES;
    // auto-connect with internal property which accesses the keychain
    [self.valueConnector connectTo:self keyPath:@"secret"];
  }
  return self;
}



- (void)setSecret:(NSString *)secret
{
  if (_keyChainService && _keyChainAccount) {
    [[ZKeyChainWrapper sharedKeyChainWrapper] setPassword:secret forService:_keyChainService account:_keyChainAccount error:NULL];
  }
}


- (NSString *)secret
{
  if (_keyChainService && _keyChainAccount) {
    return [[ZKeyChainWrapper sharedKeyChainWrapper] passwordForService:_keyChainService account:_keyChainAccount error:NULL];
  }
  return nil;
}


@end // ZKeyChainSecretCell
