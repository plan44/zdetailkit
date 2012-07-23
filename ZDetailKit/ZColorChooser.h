//
//  ZColorChooser.h
//
//  Copyright 2010 by Lukas Zeller. All rights reserved.
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
  id<ZColorChooserDelegate> delegate;
}
@property(retain,nonatomic) UIColor *color;
@property(assign) BOOL noColorAllowed;
@property(assign,nonatomic) id delegate;

@end
