//
//  ZColorChooser.m
//
//  Copyright 2010 by Lukas Zeller. All rights reserved.
//

#import "ZColorChooser.h"

#import "ZGeometry_utils.h"
#import "ZColor_utils.h"


@implementation ZColorChooser

@synthesize color, noColorAllowed, delegate;


- (void)internalInit
{
	hueImage = [[UIImage imageNamed:@"ZCCH_hue.png"] retain];
  color = [[UIColor yellowColor] retain];
  hueColor = nil;
  noColorAllowed = YES;
  self.contentMode = UIViewContentModeRedraw;
}


- (void)dealloc
{
	[hueImage release];
	[color release];
  [hueColor release];
  [super dealloc];
}



- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
    [self internalInit];
	}
	return self;
}



- (id)initWithCoder:(NSCoder *)decoder
{
	if (self = [super initWithCoder:decoder]) {
    [self internalInit];
	}
	return self;
}


- (void)setColor:(UIColor *)aNewColor
{
	if (color!=aNewColor) {
  	[color release];
    color = [aNewColor retain];
    [hueColor release];
    hueColor = nil;
    [self setNeedsDisplay];
  }
}


- (void)setEnabled:(BOOL)aEnabled
{
	[super setEnabled:aEnabled];
  [self setNeedsDisplay];
}


#define PREVIEW_MARGIN 4

#define MAX_BLACK 0.5
#define MAX_WHITE 0.8
#define COLOR_GRAY_SEP 0.7


- (void)drawRect:(CGRect)rect
{
  // Drawing code
	CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect f = self.bounds;
  CGFloat pav = f.size.height+PREVIEW_MARGIN;

  // - white bg for now
  [[UIColor whiteColor] setFill];
	CGContextFillRect(context, f);

  // draw the current color
  if (color) {
    [color setFill];
    if (self.enabled) {
	    CGContextFillRect(context, CGRectMake(0, 0, pav-PREVIEW_MARGIN, f.size.height));
      if (noColorAllowed) {
	      [[UIImage imageNamed:@"ZCCH_clrBtn.png"] drawAtPoint:CGPointMake(0,0)];
      }
    }
    else
	    CGContextFillRect(context, CGRectMake(f.size.width-f.size.height, 0, f.size.height, f.size.height));
  }
  else {
  	if (self.enabled) {
      [[UIImage imageNamed:@"ZCCH_noColor.png"] drawInRect:CGRectMake(0, 0, pav-PREVIEW_MARGIN, f.size.height)];
    }
  }

  if (self.enabled) {
    // draw hue image
    [hueImage drawInRect:CGRectMake(pav, f.size.height/2+4, f.size.width-pav, f.size.height/2-2)];
    // draw intensity (combined saturation/brightness) rect
    // - calc the hue color if we don't have it already
    float red,green,blue;
    if (!hueColor) {
      if (color) {
        // calculate hue color
        GetRGBFromColor(color,&red,&green,&blue);
        // in degrees: Hue = 180/pi*atan2( sqrt(3)*(G-B) , 2*R-G-B )
        float hue = atan2(sqrt(3)*(green-blue), 2*red-green-blue)/(2*3.1415926535);
        if (hue<0) hue+=1.0;
        hueColor = [[UIColor colorWithHue:hue saturation:1 brightness:1 alpha:1] retain];
      }
      else {
        // use default hue
        hueColor = [[UIColor orangeColor] retain];
      }
    }
    // - get the middle color
		GetRGBFromColor(hueColor,&red,&green,&blue);
    // - create the gradient
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] =
    {
      red*MAX_BLACK, green*MAX_BLACK, blue*MAX_BLACK, 1, // blackest
      red, green, blue, 1, // most intense
      MAX_WHITE, MAX_WHITE, MAX_WHITE, 1, // whitest (actually shown towards grey)
      MAX_BLACK, MAX_BLACK, MAX_BLACK, 1 // darkest allowed grey
    };
    CGFloat locations[] = {
    	0, COLOR_GRAY_SEP/2, COLOR_GRAY_SEP, 1
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, colors, locations, sizeof(colors)/(sizeof(colors[0])*4));
    CGColorSpaceRelease(rgb);
    // - use the gradient to draw the rect
    CGContextSaveGState(context);
    CGContextClipToRect(context, CGRectMake(pav, 0, f.size.width-pav, f.size.height/2-2));
    CGContextDrawLinearGradient(context, gradient, CGPointMake(pav, f.origin.y), CGPointMake(f.size.width,f.origin.y), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
  }
}




- (BOOL)allowSwipePaging
{
  // touches starting on ZColorChooser should not cause page scrolling
  return NO;
}


#define HUE_MODE 0
#define INTENSITY_MODE 1
#define CANCEL_MODE 2

- (int)trackValueWithTouch:(UITouch *)touch intoFactor:(float *)aFactorP
{
  CGRect f = self.bounds;
  float pav = f.size.height+PREVIEW_MARGIN;
  CGPoint pt = [touch locationInView:self];
  if (pt.x >= pav-10) { // allow to tap real end of bar w/o hitting color cancel
    float factor = (pt.x-pav) / (f.size.width-pav);
    if (factor>1) factor=1;
    if (factor<0) factor=0;
    if (pt.y > f.size.height/2) {
      // touch ended in hue bar (which spans only 90% of the actual hue scale)
	    if (aFactorP) *aFactorP = factor*0.9;
      return HUE_MODE;
    }
    else {
      // touch ended in intensity bar
      if (factor>0.7) {
      	// we're in the white-to-black grayscale area
		    if (aFactorP) *aFactorP = (factor-1)/(1-COLOR_GRAY_SEP)*(MAX_WHITE-MAX_BLACK)-MAX_BLACK; // grayscale
      }
      else {
	      if (aFactorP) *aFactorP = factor/COLOR_GRAY_SEP; // 0..1
      }
      return INTENSITY_MODE;
    }
  }
  else {
  	return CANCEL_MODE;
  }
}


- (void)updateColorForMode:(int)mode andFactor:(float)factor
{
  if (mode==HUE_MODE) {
    // we are in hue bar
    [hueColor release];
    hueColor = [[UIColor colorWithHue:factor saturation:1 brightness:1 alpha:1] retain];
    [self setNeedsDisplay];
  }
  else if (mode==INTENSITY_MODE) {
    // touch ended in intensity bar
    if (hueColor) {
      float red,green,blue;
      GetRGBFromColor(hueColor,&red,&green,&blue);
      float goal;
      if (factor<0) {
      	// selecting a gray scale: 0=black, 1=white
        goal = -factor; // grayscale
        factor = 1; // forget color components
      }
      else if (factor>0.5) {
      	// towards white
        factor = MAX_WHITE*2*(factor-0.5);
        goal = factor; // towards white
      }
      else {
      	// towards black
        factor = MAX_BLACK-(1-MAX_BLACK)*2*factor;
        goal = 0; // towards black
      }
      red = goal + red*(1-factor);
      green = goal + green*(1-factor);
      blue = goal + blue*(1-factor);
      [color release];
      color = [[UIColor colorWithRed:red green:green blue:blue alpha:1] retain];
      [self setNeedsDisplay];
    }
  }
  else if (mode==CANCEL_MODE) {
    // tap into the preview area: cancel the color
    if (noColorAllowed) {
      [color release];
      color = nil;
      [self sendActionsForControlEvents:UIControlEventValueChanged];
      [self setNeedsDisplay];
    }
  }
}


- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (self.enabled) {
    // determine where we are tracking
    float factor;
    trackmode = [self trackValueWithTouch:touch intoFactor:&factor];
    [self updateColorForMode:trackmode andFactor:factor];
    // block scroller as otherwise touch tracking does not work
    if (delegate && [delegate respondsToSelector:@selector(blockScrollingForSliders:)])
    	[delegate blockScrollingForSliders:YES];
    return YES;
  }
  return NO;
}



- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[super continueTrackingWithTouch:touch withEvent:event];
	if (self.enabled) {
    float factor;
    int newmode = [self trackValueWithTouch:touch intoFactor:&factor];
    if (newmode!=CANCEL_MODE)
      [self updateColorForMode:trackmode andFactor:factor];
    return YES;
  }
  return NO;
}


- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (self.enabled) {
    // unblock scroller
    if (delegate && [delegate respondsToSelector:@selector(blockScrollingForSliders:)])
    	[delegate blockScrollingForSliders:NO];
    float factor;
    [self trackValueWithTouch:touch intoFactor:&factor];
    [self updateColorForMode:trackmode andFactor:factor];
    if (trackmode!=HUE_MODE) {
      [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
  }
}

@end // ZColorChooser