//
//  ZColorChooser.h
//  ZDetailKit
//
//  Copyright (c) 2011-2013 plan44.ch. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ZColorChooserDelegate <NSObject>

- (void)blockScrollingForSliders:(BOOL)aBlockScrolling;

@end



@interface ZColorChooser : UIControl	
{
	UIImage *hueImage;
  UIColor *color;
  UIColor *hueColor;
	int trackmode;
  BOOL noColorAllowed;
  id<ZColorChooserDelegate> __unsafe_unretained delegate;
}
@property(strong,nonatomic) UIColor *color;
@property(assign) BOOL noColorAllowed;
@property(unsafe_unretained,nonatomic) id delegate;

@end
