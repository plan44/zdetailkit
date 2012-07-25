//
//  ZDetailValueConnector.h
//
//  Created by Lukas Zeller on 17.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ZDetailValueConnector;

// handler for changed value
// - can return YES to signal situation fully handled (suppresses default action, if any)
// - if no handler is set, processing continues as if the handler had returned NO
typedef BOOL (^ZDetailValueConnectorHandler)(ZDetailValueConnector *aConnector);
// - custom validation
typedef BOOL (^ZDetailValueConnectorValidationHandler)(ZDetailValueConnector *aConnector, id aValue, NSError **aErrorP);

@protocol ZDetailValueConnectorOwner <NSObject>
@optional
- (BOOL)valueChangedInConnector:(ZDetailValueConnector *)aConnector;
- (BOOL)validationStatusChangedInConnector:(ZDetailValueConnector *)aConnector error:(NSError *)aError; 
@end


@interface ZDetailValueConnector : NSObject

@property (readonly, nonatomic) id owner; // the parent of this connector, origin of value paths

// specifies the remote object being displayed or edited
// Note: this is where values are loaded from/stored to, but actual editing does not
//       happen directly on this (but on some UI representation of it, such as a text field or switch)
@property (assign, nonatomic) BOOL active; // initially off, such that detail views can be built and then activated when everything is in place 
@property (readonly, nonatomic) BOOL connected; // set if a value is connected
@property (retain, nonatomic) id target; // target (model) object
@property (retain, nonatomic) NSString *keyPath; // keyPath to value in target (model) object
// options
@property (retain, nonatomic) id nilNulValue; // if set, external value nil or NSNull are converted to this value internally
@property (assign, nonatomic) BOOL saveEmptyAsNil; // if set, internal empty string is stored as nil (or NSNull if saveNilAsNull is set)
@property (assign, nonatomic) BOOL saveNilAsNull; // if set, nil is always stored as NSNull
@property (assign, nonatomic) BOOL nilAllowed; // if set, value stored may be Nil/Null
@property (assign, nonatomic) BOOL autoUpdateValue; // if set, KVO will set internalValue when remote attribute changes
@property (assign, nonatomic) BOOL autoRevertOnValidationError; // if set, failing validation will revert internalValue
@property (assign, nonatomic) BOOL autoValidate; // if set, every change to value will actively trigger re-validation (and handler/validationStatusChangedInConnector)
@property (assign, nonatomic) BOOL autoSaveValue; // if set, changes to value will be immediately saved to remote attribute
@property (assign, nonatomic) BOOL readonly; // if set, no changes will ever be saved
@property (assign, nonatomic) BOOL unsavedChanges; // if set, internal value has unsaved changes - calling save will store them to container/keyPath
- (void)connectTo:(id)aTarget keyPath:(NSString *)aKeyPath; // convenience one-line connect


// value transformation and formatting
// - transformer applied beween connected value and internal value (forward: external->internal, reverse: internal->external)
@property (retain, nonatomic) NSValueTransformer *valueTransformer;  
// - transformer applied beween connected, transformed value and internal string representation (forward: external->internal, reverse: internal->external)
@property (retain, nonatomic) NSFormatter *formatter;

// The object that the cell represents
@property (retain, nonatomic) NSString *valuePath; // Path to internal object that represents the current cell value.
@property (retain, nonatomic) id value; // ONLY CHANGE FROM EXTERNAL! (internal edits should access internalValue or the KVO observed object at owner/valuePath)
@property (retain, nonatomic) id internalValue; // internal (formatted, converted) representation of the value
@property (readonly, nonatomic) id valueForExternal; // representation of the value for external storage (validated)
@property (readonly, nonatomic) BOOL validated; // check if value is validated
@property (readonly, nonatomic) NSError *validationError; // nil if validation ok, error otherwise
@property (copy, nonatomic) ZDetailValueConnectorHandler valueChangedHandler;
- (void)setValueChangedHandler:(ZDetailValueConnectorHandler)valueChangedHandler;
@property (copy, nonatomic) ZDetailValueConnectorValidationHandler validationHandler;
- (void)setValidationHandler:(ZDetailValueConnectorValidationHandler)validationHandler; // declaration needed only for XCode autocompletion of block
@property (copy, nonatomic) ZDetailValueConnectorHandler validationChangedHandler;
- (void)setValidationChangedHandler:(ZDetailValueConnectorHandler)validationChangedHandler; // declaration needed only for XCode autocompletion of block
- (void)saveValue; // save the value to the container/keyPath. DO NOT DERIVE!
- (void)loadValue; // load (revert) the value from model in container/keyPath. DO NOT DERIVE!
- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP; // convenience method to collect possible validation errors from connectors

// initialisation
+ (id)connectorWithValuePath:(NSString *)aValuePath owner:(id)aOwner;
- (id)initWithValuePath:(NSString *)aValuePath owner:(id)aOwner;


@end
