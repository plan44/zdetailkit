//
//  ZKeyChainSecretCell.h
//
//  Created by Lukas Zeller on 2011/08/16.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import "ZTextFieldCell.h"


@interface ZKeyChainSecretCell : ZTextFieldCell

@property (retain, nonatomic) NSString *keyChainService;
@property (retain, nonatomic) NSString *keyChainAccount;

@end
