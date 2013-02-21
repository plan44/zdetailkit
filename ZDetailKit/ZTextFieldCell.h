//
//  ZTextFieldCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 21.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZTextEditBaseCell.h"

#import "ZValueConnector.h"

@class ZTextFieldCell;

@interface ZTextFieldCell : ZTextEditBaseCell

@property (readonly, nonatomic) UITextField *textField;

@property (assign,nonatomic) BOOL autoDetail; // table width determines if we should use in-place textfield or detail editor
@property (assign,nonatomic) BOOL largeEditor; // large textView editor rather than single-line textfield



@end
