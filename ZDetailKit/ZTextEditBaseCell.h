//
//  ZTextEditBaseCell.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 25.05.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZDetailViewBaseCell.h"

@interface ZTextEditBaseCell : ZDetailViewBaseCell

@property (assign,nonatomic) BOOL multiline; // allow entering multiple text lines, may imply editInDetailView
@property (assign,nonatomic) BOOL editInDetailView; // just show the value, edit it in detail view

@property (weak, readonly,nonatomic) ZValueConnector *valueConnector;
@property (readonly,nonatomic) BOOL useTextViewEditor;
@property (strong,nonatomic) NSString *editedText;

// UITextInputTraits compatible properties, will be passed to real editing controls
@property (assign, nonatomic) UIKeyboardType keyboardType;
@property (assign, nonatomic) UIReturnKeyType returnKeyType;
@property (assign, nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property (assign, nonatomic) UITextAutocorrectionType autocorrectionType;
@property (assign, nonatomic) UITextSpellCheckingType spellCheckingType;
@property (assign, nonatomic) BOOL secureTextEntry;


@end
