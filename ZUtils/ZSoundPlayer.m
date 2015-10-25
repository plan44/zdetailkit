//
//  ZSoundPlayer.m
//
//  Created by Lukas Zeller on 2011-06-23
//  Copyright (c) 2011 plan44.ch
//

#import "ZSoundPlayer.h"

#import "ZString_utils.h"


@implementation ZSoundPlayer

@synthesize soundName, asAlert;

- (id)init
{
  if ((self = [super init])) {
    soundName = nil;
    soundFileObject = 0;
    soundFileURLRef = NULL;
    repetitionsToPlay = 0;
    asAlert = NO;
  }
  return self;
}


- (void)deflate
{
  repetitionsToPlay = 0;
   soundName = nil;
  if (soundFileURLRef) CFRelease(soundFileURLRef); soundFileURLRef = NULL;
  if (soundFileObject) {
    AudioServicesRemoveSystemSoundCompletion(soundFileObject);
    AudioServicesDisposeSystemSoundID(soundFileObject); soundFileObject = 0;
  }
}


- (void)dealloc
{
  [self deflate];
}


- (void)startPlaying
{
  if (soundFileObject && repetitionsToPlay>0) {
    // now play
    if (asAlert)
      AudioServicesPlayAlertSound(soundFileObject);
    else
      AudioServicesPlaySystemSound(soundFileObject);
  }
}


- (void)playingComplete
{
  if (repetitionsToPlay>0) {
    repetitionsToPlay--;
    if (repetitionsToPlay>0) {
      // launch next repeat
      [self startPlaying]; // again
    }
  }
}


void PlayCompletionProc(SystemSoundID aSsID, void* aClientData)
{
  [(__bridge ZSoundPlayer *)aClientData playingComplete];
}


- (void)setSoundName:(NSString *)aSoundName
{
  if (!sameString(soundName,aSoundName)) {
    // new sound, forget old one
    [self deflate];
    soundName = aSoundName;
    if (aSoundName && [aSoundName length]>0) {
      // - Get the URL to the sound file to play
      soundFileURLRef = CFBundleCopyResourceURL(
        CFBundleGetMainBundle(),
        (__bridge CFStringRef)[soundName stringByDeletingPathExtension],
        CFSTR("caf"),
        NULL
      );
      // - Create a system sound object representing the sound file
      AudioServicesCreateSystemSoundID(soundFileURLRef, &soundFileObject);
      // - add completion hook for it
      AudioServicesAddSystemSoundCompletion(
        soundFileObject,
        NULL, NULL, PlayCompletionProc, (__bridge void *)(self)
      );
    }
  }
}

- (void)playTimes:(int)aTimes
{
  if (soundFileObject) {
    if (repetitionsToPlay>0) {
      // already playing, just add to scheduled plays
      repetitionsToPlay += aTimes;
    }
    else {
      // set number of repetitions
      repetitionsToPlay = aTimes;
      // - play first one
      [self startPlaying];
    }
  }
}

- (void)play
{
  [self playTimes:1]; // once
}


- (void)stop
{
  // deflating deletes system sound and immediately halts playing current sound
  [self deflate];
}


@end // ZSoundPlayer