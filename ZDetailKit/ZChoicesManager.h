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


/// ZChoicesManager internal representation of a choice
@interface ZChoiceInfo: NSObject
/// the key
@property (strong, nonatomic) id key;
/// the choice dictionary (as set by addChoice: method
@property (strong, nonatomic) NSDictionary *choice;
/// original index to re-identify the choice even after potential reordering
@property (assign, nonatomic) NSUInteger index;
/// flag to signal if thsi choice is selected or not
@property (assign, nonatomic) BOOL selected;
/// convenience factory class method
+ (ZChoiceInfo *)choiceWithDict:(NSDictionary *)aChoiceDict selected:(BOOL)aSelected index:(NSUInteger)aIndex;
@end


/// delegate protocol for choice manager, allows to respond to changes in choice list and selection
@protocol ZChoicesManagerDelegate <NSObject>

@optional
/// called when list of choices changes (if only order). Must also update selection (updateChoiceSelection is not called automatically)
- (void)updateChoicesDisplay;
/// called when selection changes (but not list of choices)
- (void)updateChoiceSelection;
/// called when change of parameters cause a choiceInfo rebuild that affects currentChoice
- (void)currentChoiceChanged;

@end


/// ZChoicesManager is the object which manages a ordered and potentially orderable set of choices
/// for use in editors like ZSegmentChoicesCell and ZChoiceListCell
///
/// The basic asset is the choicesArray, which holds a dictionary for each choice.
/// Each choice dictionary contains at least a key plus some values to visually represent the
/// choice (text, summary text, image etc.).
/// See addChoice: for a description of choice dictionary keys.
///
/// ZChoicesManager can interface the visual choices in different ways with a data model object,
/// from storing a single key value for a single choice, to a NSSet or NSArray of multiple choices,
/// up to a ordered array of all choices representing a user set order plus a "selected" status
/// for each choice. See mode property for details.
@interface ZChoicesManager : NSObject

/// @name configuration

/// This sets the interfacing mode for the choice manager as follows
///
/// - ZChoicesManagerModeSingleKey: the choice is a single choice key value (usually a NSNumber, NSValue, NSString)
/// - ZChoicesManagerModeKeySet: the choice is a NSSet of choice key values
/// - ZChoicesManagerModeKeyArray: the choice is a NSArray of choice key values
/// - ZChoicesManagerModeDictArray: the choice is a ordered NSArray of dictionaries, each of which
///   has a "key" and a "sel" (selected, NSNumber). All choices will be included in end-user set order, selected
///   ones have "sel" set.
/// - ZChoicesManagerModeChoiceInfoArray: same as ZChoicesManagerModeDictArray, but the dictionaries returned are
///   the internal representation (ZChoiceInfo objects).
/// - ZChoicesManagerModeAutomatic (default value): automatically selects one of ZChoicesManagerModeKeySet,
///   ZChoicesManagerModeKeyArray or ZChoicesManagerModeSingleKey depending on the kind of object first
///   assigned to currentChoice.
@property (assign, nonatomic) ZChoicesManagerMode mode;

/// if set, multiple choices are allowed
@property (assign, nonatomic) BOOL multipleChoices;

/// if set, having no choice is allowed
@property (assign, nonatomic) BOOL noChoice;

/// if set, choices can be reordered
@property (assign, nonatomic) BOOL reorderable;

/// if set, choice management is active and addChoice: methods cannot be used
@property (assign, nonatomic) BOOL active;

/// delegate 
@property (unsafe_unretained, nonatomic) id<ZChoicesManagerDelegate> delegate;

/// current choice, formatted according to mode
@property (strong, nonatomic) id currentChoice;

/// configured list of choices
/// @note usually, choices are constructed using addChoice: family of methods. However, choicesArray can also be set
/// directly - in this case it needs to be a array of choice dictionaries. For possible key/values in a choiceDict,
/// see aChoiceDict param in addChoice:
@property (strong, nonatomic) NSArray *choicesArray;

// internal array of choices plus selection status, in display order
// (for use by subclasses)
@property (readonly, nonatomic) NSMutableArray *choiceInfos;

/// Add a new choice
/// @param aChoiceDict a dictionary representing the choice with the following possible key/values:
///
/// - "key" : (id) the object to be used as key for this choice
/// - "text" : (NSString) textual representation of the choice
/// - "summary" : (NSString) summarized (short form) representation of the choice. Defaults to "text" if not set
/// - "order" : (NSNumber) order. Choices are presented sorted ascending by this key first, and "text" next
///   (unless order is represented in currentChoice already (ZChoicesManagerModeDictArray and ZChoicesManagerModeChoiceInfoArray modes)
///
/// The above are the keys known by ZChoicesManager. Other keys might be used to add to the visual representation
/// in actual choice editors like ZSegmentChoicesCell and ZChoiceListController/ZChoiceListCell
///
/// - "imageName" : a name which can be used with imageNamed: to get a image representing the choice
/// - "image" : a UIImage representing the choice
///
/// @note addChoice: can only be used when the choice manager is not active
- (void)addChoice:(NSDictionary *)aChoiceDict;

/// Add a new textual choice
/// @param aText the description text for the choice
/// @param aOrder the order for the choice
/// @param aKey the object to be used as key for this choice
- (void)addChoice:(NSString *)aText order:(NSInteger)aOrder key:(id)aKey;

/// Add a new textual choice with summary
/// @param aText the description text for the choice
/// @param aSummary a short text for representing the choice e.g. in a ZChoiceListCell
/// @param aOrder the order for the choice
/// @param aKey the object to be used as key for this choice
- (void)addChoice:(NSString *)aText summary:(NSString *)aSummary order:(NSInteger)aOrder key:(id)aKey;

/// Add a new image choice
/// @param aImageOrName a UIImage object or a NSString representing a image name
/// @param aOrder the order for the choice
/// @param aKey the object to be used as key for this choice
- (void)addImageChoice:(id)aImageOrName order:(NSInteger)aOrder key:(id)aKey;




/// reordering support used e.g. by ZChoiceListController
/// @param aFromIndex original row index
/// @param aToIndex new row index
- (void)moveChoiceFrom:(NSInteger)aFromIndex to:(NSInteger)aToIndex;

@end
