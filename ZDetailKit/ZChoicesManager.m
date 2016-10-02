//
//  ZChoicesManager.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 06.06.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZChoicesManager.h"

#import "ZCustomI8n.h"

@implementation ZChoiceInfo

@synthesize key, selected, index, choice;

+ (ZChoiceInfo *)choiceWithDict:(NSDictionary *)aChoiceDict selected:(BOOL)aSelected index:(NSUInteger)aIndex
{
  id key = [aChoiceDict valueForKey:@"key"];
  NSAssert(key!=nil,@"aChoiceDict must contain 'key'");
  ZChoiceInfo *i = [[ZChoiceInfo alloc] init];
  i.key = key;
  i.selected = aSelected;
  i.choice = aChoiceDict;
  i.index = aIndex;
  return i;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<ZChoiceInfo selected=%d, key='%@' index=%lu>",self.selected, self.key, (unsigned long)self.index];
}

@end // ZChoiceInfo




@interface ZChoicesManager ( /* class extension */ )
{
  BOOL needsChoiceInfoUpdate; // currentChoice needs to be updated
  BOOL needsChoicesSelectionUpdate; // display of current choice selection needs to be updated
  BOOL needsChoicesDisplayUpdate; // choices display (order, items contained) need to be updated
  NSUInteger nextChoiceIndex; // incrementing index (or id), assigned to choices as they are created
}

@property (readonly) BOOL keepOrder;
- (void)updateData;

@end


@implementation ZChoicesManager


- (id)init
{
  if ((self = [super init])) {
    choicesArray = nil;
    choiceInfos = nil; // created on demand
    delegate = nil;
    active = NO;
    nextChoiceIndex = 0;
    multipleChoices = NO;
    noChoice = NO;
    mode = ZChoicesManagerModeAutomatic;
    // status
    needsChoiceInfoUpdate = YES;
    needsChoicesDisplayUpdate = YES;
    needsChoicesSelectionUpdate = YES;
  }
  return self;
}





#pragma mark - configuration

@synthesize delegate;

@synthesize mode, active;

- (void)setMode:(ZChoicesManagerMode)aMode
{
  if (aMode!=mode) {
    mode = aMode;
    if (mode==ZChoicesManagerModeSingleKey)
      multipleChoices=NO; // cannot have multiple choices with single key
    // forget current choiceInfos, need to be rebuilt
    [choiceInfos removeAllObjects];
    needsChoiceInfoUpdate = YES;
  }
}


@synthesize multipleChoices;

- (void)setMultipleChoices:(BOOL)aMultipleChoices
{
  if (aMultipleChoices!=multipleChoices) {
    multipleChoices = aMultipleChoices;
    if (multipleChoices && mode==ZChoicesManagerModeSingleKey) {
      self.mode = ZChoicesManagerModeKeySet; // use set by default
    }
    self.noChoice = self.multipleChoices; // by default, having no choice selected is ok in multiple choices mode
  }
}


@synthesize reorderable;
@synthesize noChoice;

// add choice, but only during setup (when cell is not active)
- (void)addChoice:(NSDictionary *)aChoiceDict
{
  if (!self.active) {
    if (![choicesArray isKindOfClass:[NSMutableArray class]]) {
      // convert to mutable
      NSMutableArray *newChoices = [NSMutableArray arrayWithArray:choicesArray];
      choicesArray = newChoices;
    }
    // now add
    [(NSMutableArray *)choicesArray addObject:aChoiceDict];
  }
}


// add simple ordered text choice
- (void)addChoice:(NSString *)aText order:(NSInteger)aOrder key:(id)aKey
{
  [self addChoice:@{
    @"key" : aKey,
    @"text" : aText,
    @"order" : @(aOrder),
   }];
}


// add simple ordered text choice with separate summary text
- (void)addChoice:(NSString *)aText summary:(NSString *)aSummary order:(NSInteger)aOrder key:(id)aKey
{
  [self addChoice:@{
    @"key" : aKey,
    @"text" : aText,
    @"summary" : aSummary,
    @"order" : @(aOrder)
  }];
}


- (void)addImageChoice:(id)aImageOrName order:(NSInteger)aOrder key:(id)aKey
{
  [self addChoice:@{
    @"key" : aKey,
    ([aImageOrName isKindOfClass:[UIImage class]] ? @"image" : @"imageName")   : aImageOrName,
    @"order" : @(aOrder)
  }];
}




#pragma mark - choices list management


- (BOOL)keepOrder
{
  return mode==ZChoicesManagerModeChoiceInfoArray || mode==ZChoicesManagerModeDictArray;
}



- (NSDictionary *)choiceForKey:(id)aKey
{
  for (NSDictionary *d in choicesArray) {
    if ([[d valueForKey:@"key"] isEqual:aKey]) {
      return d;
    }
  }
  return nil;
}


// Important: operates on currently existing infos only, must not cause update!
- (ZChoiceInfo *)choiceInfoForKey:(id)aKey
{
  for (ZChoiceInfo *i in choiceInfos) {
    if ([i.key isEqual:aKey])
      return i;
  }
  return nil;
}



- (BOOL)updateChoiceInfos
{
  needsChoiceInfoUpdate = NO; // doing it now
  BOOL choicesChanged = NO;
  // need to rebuild/adapt the choice infos
  // - create a sorted list of choices
  NSArray *sortedChoices = [choicesArray
    sortedArrayUsingDescriptors:@[
      [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES],
      [NSSortDescriptor sortDescriptorWithKey:@"text" ascending:YES]
    ]
  ];
  // In all modes: remove choiceInfos that don't exist in the new choices any more
  if (choiceInfos) {
    NSArray *cif = [NSArray arrayWithArray:choiceInfos];
    for (ZChoiceInfo *ci in cif) {
      if ([self choiceForKey:ci.key]==nil) {
        // no such choice, remove info
        [choiceInfos removeObject:ci];
        // removing a selected item from choices is a change to the currentChoice
        // (and in ZChoicesManagerModeChoiceInfoArray mode every info change is a change of currentChoice)
        choicesChanged = ci.selected || self.keepOrder;
      }
    }
  }
  else {
    // no choiceinfos existed at all, create them now
    choiceInfos = [[NSMutableArray alloc] initWithCapacity:[choicesArray count]];
  }
  // Deal with new and existing entries
  if (self.keepOrder) {
    // sort order is part of currentChoice, retain it as much as possible
    // - append new items that are in the new choices list, in the order they appear
    for (NSDictionary *d in sortedChoices) {
      id k = [d valueForKey:@"key"];
      if ([self choiceInfoForKey:k]==nil) {
        [choiceInfos addObject:[ZChoiceInfo choiceWithDict:d selected:NO index:++nextChoiceIndex]];
        // adding a new choiceInfos item (even unselected) is a change in
        // ZChoicesManagerModeChoiceInfoArray/ZChoicesManagerModeDictArray
        choicesChanged = YES;
      }
    }
  }
  else {
    // sort order is NOT part of currentChoice, just retain selection status,
    // but otherwise replace choice infos with new ones in new sorted order
    NSMutableArray *newChoiceInfos = [NSMutableArray arrayWithCapacity:[choicesArray count]];
    for (NSDictionary *d in sortedChoices) {
      id k = [d valueForKey:@"key"];
      ZChoiceInfo *i = [self choiceInfoForKey:k];
      [newChoiceInfos addObject:[ZChoiceInfo choiceWithDict:d
        selected:i && i.selected // info exists and was selected before
        index:++nextChoiceIndex
      ]];
    }
    // install new infos
    choiceInfos = newChoiceInfos;
  }
  // return if currentChoice relevant changes have happened
  if (choicesChanged) {
    needsChoicesDisplayUpdate = YES;
    needsChoicesSelectionUpdate = YES; // selection changed as well
  }
  return choicesChanged;
}


@synthesize choicesArray;

- (NSArray *)choicesArray
{
  if (choicesArray==nil) {
    choicesArray = [NSArray array];
  }
  return choicesArray;
}



- (void)setChoicesArray:(NSArray *)aChoicesArray
{
  if (aChoicesArray!=choicesArray) {
    choicesArray = aChoicesArray;
    // changing choices while active may have impact on currentChoice
    // so we need to update the infos
    if (self.active) {
      if ([self updateChoiceInfos]) {
        if (delegate && [delegate respondsToSelector:@selector(currentChoiceChanged)]) {
          [delegate currentChoiceChanged];
        }
      }
    }
    else {
      needsChoiceInfoUpdate = YES;
    }
  }
}



@synthesize choiceInfos;

- (NSMutableArray *)choiceInfos
{
  if (choiceInfos==nil || needsChoiceInfoUpdate) {
    [self updateChoiceInfos];
  }
  return choiceInfos;
}


- (id)choicesInMode:(ZChoicesManagerMode)aMode
{
  if (aMode==ZChoicesManagerModeSingleKey) {
    // first enabled key
    for (ZChoiceInfo *ci in self.choiceInfos) {
      if (ci.selected) {
        return ci.key;
      }
    }
    return nil; // no choice
  }
  else if (aMode==ZChoicesManagerModeKeyArray || aMode==ZChoicesManagerModeKeySet) {
    // collect selected keys
    NSMutableArray *ch = [NSMutableArray array];
    for (ZChoiceInfo *ci in self.choiceInfos) {
      if (ci.selected) {
        [ch addObject:ci.key];
      }
    }
    // return desired object
    if (aMode==ZChoicesManagerModeKeySet) {
      return [NSSet setWithArray:ch];
    }
    else {
      return ch;
    }
  }
  else if (aMode==ZChoicesManagerModeDictArray) {
    // return array of dicts containing "key" and "sel"
    NSMutableArray *dictArray = [NSMutableArray arrayWithCapacity:[self.choiceInfos count]];
    for (ZChoiceInfo *info in self.choiceInfos) {
      [dictArray addObject:@{
        @"key" : info.key,
        @"sel" : @(info.selected)
      }];
    }
    return dictArray;
  }
  else if (aMode==ZChoicesManagerModeChoiceInfoArray) {
    // return the internal representation
    return [NSArray arrayWithArray:self.choiceInfos];
  }
  // unknown mode
  return nil;
}




- (id)currentChoice
{
  return [self choicesInMode:mode];
}


- (void)setCurrentChoice:(id)aCurrentChoice
{
  if (mode==ZChoicesManagerModeAutomatic) {
    // set automatically
    if ([aCurrentChoice isKindOfClass:[NSArray class]])
      self.mode = ZChoicesManagerModeKeyArray;
    else if ([aCurrentChoice isKindOfClass:[NSSet class]])
      self.mode = ZChoicesManagerModeKeySet;
    else {
      // neither set nor array: assume single choice
      self.multipleChoices = NO;
      self.mode = ZChoicesManagerModeSingleKey;
    }
  }
  // create choice info list
  if (mode==ZChoicesManagerModeSingleKey) {
    // aCurrentChoice is single key object
    // - make it the only selected one in choices
    for (ZChoiceInfo *i in self.choiceInfos) {
      BOOL newSel = [aCurrentChoice isEqual:i.key]; 
      if (i.selected != newSel) {
        needsChoicesSelectionUpdate = YES; // selection needs to be updated
        i.selected = newSel;
      }
    }
  }
  else if (mode==ZChoicesManagerModeKeyArray || mode==ZChoicesManagerModeKeySet) {
    // input is NSSet or NSArray of selected choices' keys
    for (ZChoiceInfo *i in self.choiceInfos) {
      // check if key of that choice is in the new selection
      BOOL newSel = [aCurrentChoice containsObject:i.key];
      if (i.selected != newSel) needsChoicesSelectionUpdate = YES; // selection needs to be updated
      i.selected = newSel;
    }
  }
  else if (mode==ZChoicesManagerModeDictArray) {
    // rebuild
    choiceInfos = [[NSMutableArray alloc] initWithCapacity:[choicesArray count]];
    nextChoiceIndex = 0;
    // rebuild from dictArray (retaining key order!)
    for (NSDictionary *ccd in aCurrentChoice) {
      // look up from the actual choices we have
      id key = [ccd valueForKey:@"key"];
      id sel = [ccd valueForKey:@"sel"];
      if (key) {
        NSDictionary *dict = [self choiceForKey:key];
        if (dict) {
          // we have such a choice - create choiceInfo entry for it
          [choiceInfos addObject:
            [ZChoiceInfo choiceWithDict:dict selected:[sel boolValue] index:++nextChoiceIndex]
          ];
        }
      }
      needsChoicesDisplayUpdate = YES; // show new choices/order
    }
  }
  else if (mode==ZChoicesManagerModeChoiceInfoArray) {
    // replace raw infos
    choiceInfos = [aCurrentChoice mutableCopy]; // mutable copy
    nextChoiceIndex = 0;
    // needs to be verified/adjusted against actual choices
    needsChoiceInfoUpdate = YES;
  }
  [self updateData];
}




- (void)beginChoiceChanges
{
  [self willChangeValueForKey:@"currentChoice"];
}


- (void)endChoiceChanges
{
  [self didChangeValueForKey:@"currentChoice"];
  needsChoicesSelectionUpdate = YES;
}


#pragma mark - KVC and KVO for selection states and order of choices


- (void)setSel:(BOOL)aSel inInfo:(ZChoiceInfo *)aInfo
{
  if (aSel!=aInfo.selected) {
    NSString *key = [NSString stringWithFormat:@"sel_%lu", (unsigned long)aInfo.index];
    [self willChangeValueForKey:key];
    [self willChangeValueForKey:@"currentChoice"];
    aInfo.selected = aSel;
    [self didChangeValueForKey:key];
    [self didChangeValueForKey:@"currentChoice"];
    needsChoicesSelectionUpdate = YES;
  }
}



// Note: this is to support UITableView reordering. Actual table display updates happen
//   as part of the user interaction, so we only need to adjust the data here
- (void)moveChoiceFrom:(NSInteger)aFromIndex to:(NSInteger)aToIndex
{
  ZChoiceInfo *movedChoice = [self.choiceInfos objectAtIndex:aFromIndex];
  [self willChangeValueForKey:@"currentChoice"];
  [self.choiceInfos removeObjectAtIndex:aFromIndex];
  [self.choiceInfos insertObject:movedChoice atIndex:aToIndex];
  [self didChangeValueForKey:@"currentChoice"];
}




- (id)valueForUndefinedKey:(NSString *)aKey
{
  if ([aKey hasPrefix:@"sel_"]) {
    NSUInteger i = [[aKey substringFromIndex:4] integerValue];
    // this is a pseudo-property accessing one of my choiceInfos
    for (ZChoiceInfo *info in self.choiceInfos) {
      if (info.index==i) {
        return [NSNumber numberWithBool:info.selected];
      }
    }
    return nil;
  }
  else {
    return [super valueForUndefinedKey:aKey];
  }
}


- (void)setValue:(id)aValue forUndefinedKey:(NSString *)aKey
{
  if ([aKey hasPrefix:@"sel_"]) {
    BOOL newSel = [aValue boolValue];
    NSUInteger i = [[aKey substringFromIndex:4] integerValue];
    // this is a pseudo-property accessing one of my choiceInfos
    for (ZChoiceInfo *info in self.choiceInfos) {
      if (info.index==i) {
        // addressed selection
        [self setSel:newSel inInfo:info];
      }
      else {
        // another choice
        if (!self.multipleChoices) {
          // other choices must be off
          [self setSel:NO inInfo:info];
        }
      }
    }
    [self updateData];
  }
  else {
    [super setValue:aValue forUndefinedKey:aKey];
  }
}


- (BOOL)validateValue:(id *)aIOValueP forKey:(NSString *)aKey error:(NSError **)aOutErrorP
{
  if ([aKey hasPrefix:@"sel_"]) {
    BOOL newSel = [*aIOValueP boolValue];
    if (self.noChoice==NO && !newSel) {
      // make sure we can't deselect last choice
      NSUInteger i = [[aKey substringFromIndex:4] integerValue];
      for (ZChoiceInfo *info in self.choiceInfos) {
        if (info.index!=i && info.selected) {
          // another choice is selected, we can allow deselecting this one
          return YES;
        }
      }
      // all other choices are off already, this one is the last, must remain selected
      if (aOutErrorP) {
        *aOutErrorP = [NSError errorWithDomain:@"ZValidationError" code:NSKeyValueValidationError userInfo:@{
          NSLocalizedDescriptionKey: ZLocalizedStringWithDefault(@"ZDTK_ValErr_NeedOneChoice",@"At least one choice must remain selected"),
        }];
      }
      return NO;
    }
    // no restrictions, just go on
    return YES;
  }
  else {
    return [super validateValue:aIOValueP forKey:aKey error:aOutErrorP];
  }
}


#pragma mark - current choice list and selection update - forward to delegate


- (void)updateData
{
  // give subclasses opportunity to update list and/or selection
  // - make sure choicesInfos are up-to-date
  if (needsChoiceInfoUpdate) {
    [self updateChoiceInfos];
  }
  if (needsChoicesDisplayUpdate) {
    needsChoicesDisplayUpdate = NO;
    needsChoicesSelectionUpdate = NO;
    if (delegate && [delegate respondsToSelector:@selector(updateChoicesDisplay)]) {
      [delegate updateChoicesDisplay];
    }
  }
  else if (needsChoicesSelectionUpdate) {
    needsChoicesSelectionUpdate = NO;
    if (delegate && [delegate respondsToSelector:@selector(updateChoiceSelection)]) {
      [delegate updateChoiceSelection];
    }
  }
}



@end
