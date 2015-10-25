//
//  ZSoundPlayer.h
//
//  Created by Lukas Zeller on 2011-06-23
//  Copyright (c) 2011 plan44.ch
//


#import <AudioToolbox/AudioToolbox.h>

@interface ZSoundPlayer : NSObject
{
  // sound
  NSString *soundName;
  CFURLRef soundFileURLRef;
  SystemSoundID soundFileObject;
  int repetitionsToPlay;
  BOOL asAlert;
}
@property(strong,nonatomic) NSString *soundName;
@property(assign) BOOL asAlert;

- (id)init;
- (void)play;
- (void)playTimes:(int)aTimes;
- (void)stop;


@end // ZSoundPlayer
