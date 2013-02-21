//
//  ZDetailValueConnector.h
//  ZDetailKit
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


/// protocol for objects that own ZDetailValueConnector objects. If owner implements the optional methods,
/// it will be notified about value and validation state changes
@protocol ZDetailValueConnectorOwner <NSObject>
@optional
/// called when the internal value changes
/// @note if autoSaveValue is not set, the external (connected) value has not yet changed when this method is called
- (BOOL)valueChangedInConnector:(ZDetailValueConnector *)aConnector;
/// called when the validation status of the value has changed
- (BOOL)validationStatusChangedInConnector:(ZDetailValueConnector *)aConnector error:(NSError *)aError;
@end



/// Protocol for objects that have value connectors
/// @note this protocol is implemented in the ZValueConnectorContainerImpl category on NSObject
///   which makes every object a potential container for value connectors.
@protocol ZValueConnectorContainer <NSObject>

/// Mutable array containing all value connectors of the object
/// @note in the ZValueConnectorContainerImpl category, first access to this property creates
//    the valueConnectors mutable array as an attached object
@property (strong, nonatomic, getter = valueConnectors, setter = setValueConnectors:) NSMutableArray *valueConnectors;

/// activate / deactivate all registered connectors
- (void)setValueConnectorsActive:(BOOL)aActive;

/// save data in all connectors
- (void)saveValueConnectors;

/// load data in all connectors
- (void)loadValueConnectors;

/// check for validation in all connectors and collect errors
/// @return YES if all connectors validate ok, NO otherwise
/// @param aErrorsP can be passed NULL if no errors should be collected.
/// If *aErrorsP points to a nil value, a NSMutableArray is created when at least one error is encountered.
/// If an existing array is passed, encountered errors will be appended.
- (BOOL)connectorsValidateWithErrors:(NSMutableArray **)aErrorsP;

/// register a value connector with this object
- (ZDetailValueConnector *)registerValueConnector:(ZDetailValueConnector *)aConnector;

@end




@interface ZDetailValueConnector : NSObject

/// @name initialisation


/// initialize the connector with an owner and a valuePath referencing the internal value
/// @note the internal value is usually the value prooperty of the editing/displaying control
- (id)initWithValuePath:(NSString *)aValuePath owner:(id)aOwner;

/// convenience method to create a new connector for some internal value.
+ (id)connectorWithValuePath:(NSString *)aValuePath owner:(id)aOwner;

/// the owner of this connector (usually the object which has the connector embedded)
/// @note this also is the object which builds the root for internal valuepaths as passed to initWithValuePath:owner:
@property (unsafe_unretained, readonly, nonatomic) id owner;

/// @name target (data model) connection

// specifies the remote object being displayed or edited
// Note: this is where values are loaded from/stored to, but actual editing does not
//       happen directly on this (but on some UI representation of it, such as a text field or switch)

/// target (model) object
@property (strong, nonatomic) id target;
/// keyPath to attribute in target (model) object
@property (strong, nonatomic) NSString *keyPath;
/// convenience one-line connection method
- (void)connectTo:(id)aTarget keyPath:(NSString *)aKeyPath;

/// initially off, such that detail views can be built and then activated when everything is in place
@property (assign, nonatomic) BOOL active;

/// set if a value is connected
@property (readonly, nonatomic) BOOL connected;

/// save the value to the target (model) attribute
/// @warning DO NOT OVERRIDE!
- (void)saveValue;

/// load (revert) the value from model in container/keyPath.
/// @warning DO NOT OVERRIDE!
- (void)loadValue;

/// convenience method to collect possible validation errors from connectors
/// @note this is used by ZDetailViewBaseCell and ZDetaulViewBaseController to collect validation status
- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP;


/// @name options

/// if set, external value nil or NSNull are converted to this value internally
@property (strong, nonatomic) id nilNulValue;
/// if set, internal empty string is stored as nil (or NSNull if saveNilAsNull is set)
@property (assign, nonatomic) BOOL saveEmptyAsNil;
/// if set, nil is always stored as NSNull
@property (assign, nonatomic) BOOL saveNilAsNull;
/// if set, value stored may be Nil/Null
@property (assign, nonatomic) BOOL nilAllowed;
/// if set, KVO will update internalValue when connected target (model) attribute changes
@property (assign, nonatomic) BOOL autoUpdateValue;
/// if set, value changed handler will also be called when value is initially loaded and (when autoUpdateValue is set) for external value changes
/// (if not set, the handler is called only when the value changes due to user action)
/// Default is YES.
@property (assign, nonatomic) BOOL callChangedHandlerOnLoad;
/// if set, failing validation will revert internalValue to previous value
@property (assign, nonatomic) BOOL autoRevertOnValidationError;
/// if set, every change to value will actively trigger re-validation (and handler/validationStatusChangedInConnector)
@property (assign, nonatomic) BOOL autoValidate;
/// if set, changes to value will be immediately saved to connected target (model) attribute
@property (assign, nonatomic) BOOL autoSaveValue;
/// if set, no changes will ever be saved
@property (assign, nonatomic) BOOL readonly;
/// if set, internalValue is unsaved, and will be saved on next call to save.
/// @note This can also be set programmatically when the internalValue points to a non KVO-compliant value (such as most UIControl properties)
@property (assign, nonatomic) BOOL unsavedChanges;
/// if set, the value transformer (if any) will be used in reverse direction
/// (i.e. forward transformation is from value to target and reverse is from target to value)
@property (assign, nonatomic) BOOL transformReversed;

/// @name value transformation and formatting

/// NSValueTransformer applied beween connected value and internal value
/// (forward: external->internal, reverse: internal->external, unless reversed by setting transformReversed==YES)
@property (strong, nonatomic) NSValueTransformer *valueTransformer;  

/// NSFormatter applied beween connected, transformed value and internal string representation (string generation: external->internal, string parsing: internal->external)
@property (strong, nonatomic) NSFormatter *formatter;

/// @name internal value

/// keyPath to internal object that represents the current cell value (keyPath is relative to owner)
/// @note this is often made pointing directly to the value of a UIControl which represents the value
@property (strong, nonatomic) NSString *valuePath;

/// internal (transformed, formatted) representation of the value
/// @note this is the value pointed to by valuePath, and usually is the value of a UIControl which shows/edits the value
@property (strong, nonatomic) id internalValue;

/// The internal value, parsed, validated and transformed into representation suitable for being stored in target (model).
@property (readonly, nonatomic) id valueForExternal; // representation of the value for external storage (validated)

/// if YES, current internal value validates ok
@property (readonly, nonatomic) BOOL validated;

/// nil if validation ok, error otherwise
@property (readonly, nonatomic) NSError *validationError;

/// This directly accesses the connected target (model) value. It should not normally be changed.
/// @warning ONLY CHANGE FROM EXTERNAL! (internal edits should access internalValue or the KVO observed object at owner/valuePath).
@property (strong, nonatomic) id value;

/// @name handlers to modify standard behaviour

/// called when internal value changes.
///
/// If callChangedHandlerOnLoad is set, loading of the value from the connected target (model) attribute also triggers this handler
/// The handler should return YES if the value change is fully handled. Otherwise default processing will occur.
@property (copy, nonatomic) ZDetailValueConnectorHandler valueChangedHandler;
- (void)setValueChangedHandler:(ZDetailValueConnectorHandler)valueChangedHandler;
/// called after the value has been saved to the target (model) 
@property (copy, nonatomic) ZDetailValueConnectorHandler valueSavedHandler;
- (void)setValueSavedHandler:(ZDetailValueConnectorHandler)valueSavedHandler;
/// called as a first step of internal value validation. This handler can be set to implement custom validation.
@property (copy, nonatomic) ZDetailValueConnectorValidationHandler validationHandler;
- (void)setValidationHandler:(ZDetailValueConnectorValidationHandler)validationHandler; // declaration needed only for XCode autocompletion of block
/// called when validation status changes (i.e. validation becomes invalid or valid)
@property (copy, nonatomic) ZDetailValueConnectorHandler validationChangedHandler;
- (void)setValidationChangedHandler:(ZDetailValueConnectorHandler)validationChangedHandler; // declaration needed only for XCode autocompletion of block




@end
