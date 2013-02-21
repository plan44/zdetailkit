//
//  ZChoicesManager.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 06.06.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZValueConnector.h"

typedef enum {
  ZChoicesManagerModeSingleKey, // single key object (only in single-choice mode)
  ZChoicesManagerModeKeySet, // NSSet of chosen keys
  ZChoicesManagerModeKeyArray, // NSArray of chosen keys
  ZChoicesManagerModeDictArray, // NSArray of NSDictionary with "key" and "sel" values
  ZChoicesManagerModeChoiceInfoArray, // NSArray of ZChoiceInfo objects
  ZChoicesManagerModeAutomatic // selects one of the above when currentChoice is first set
} ZChoicesManagerMode;


@interface ZChoiceInfo: NSObject
@property (strong, nonatomic) id key;
@property (strong, nonatomic) NSDictionary *choice;
@property (assign, nonatomic) NSUInteger index; // original index to re-identify the choice even after potential reordering
@property (assign, nonatomic) BOOL selected;
+ (ZChoiceInfo *)choiceWithDict:(NSDictionary *)aChoiceDict selected:(BOOL)aSelected index:(NSUInteger)aIndex;
@end


@protocol ZChoicesManagerDelegate <NSObject>

@optional
// called when list of choices changes (if only order). Must also update selection (updateChoiceSelection is not called automatically)
- (void)updateChoicesDisplay;
// called when selection changes (but not list of choices)
- (void)updateChoiceSelection;
// called when change of parameters cause a choiceInfo rebuild that affects currentChoice
- (void)currentChoiceChanged;

@end



@interface ZChoicesManager : NSObject

// configuration
@property (assign, nonatomic) ZChoicesManagerMode mode;
@property (assign, nonatomic) BOOL multipleChoices;
@property (assign, nonatomic) BOOL noChoice;
@property (assign, nonatomic) BOOL reorderable;
// operation
@property (assign, nonatomic) BOOL active;
@property (unsafe_unretained, nonatomic) id<ZChoicesManagerDelegate> delegate;
// current choice, formatted according to mode
@property (strong, nonatomic) id currentChoice;
// configured list of choices
@property (strong, nonatomic) NSArray *choicesArray;

// internal array of choices plus selection status, in display order
// (for use by subclasses)
@property (readonly, nonatomic) NSMutableArray *choiceInfos;

// convenience methods to add choices
- (void)addChoice:(NSDictionary *)aChoiceDict;
- (void)addChoice:(NSString *)aText order:(NSInteger)aOrder key:(id)aKey;
- (void)addChoice:(NSString *)aText summary:(NSString *)aSummary order:(NSInteger)aOrder key:(id)aKey;

// reordering support
- (void)moveChoiceFrom:(NSInteger)aFromIndex to:(NSInteger)aToIndex;

@end
