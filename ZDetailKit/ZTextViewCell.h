//
//  ZTextViewCell.h
//
//  Created by Lukas Zeller on 25.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZTextEditBaseCell.h"

#import "ZDetailValueConnector.h"

@interface ZTextViewCell : ZTextEditBaseCell

@property (readonly, nonatomic) UITextView *textView;

@property (assign, nonatomic) CGFloat maxCellHeight;

@property (assign, nonatomic) BOOL autoAdjustHeight;
@property (assign, nonatomic) BOOL adjustWhileTyping;

@end
