//
//  ZValueConnector.h
//  ZDetailKit
//
//  Created by Lukas Zeller on 17.05.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ZValueConnector;

// handler for changed value
// - can return YES to signal situation fully handled (suppresses default action, if any)
// - if no handler is set, processing continues as if the handler had returned NO
typedef BOOL (^ZValueConnectorHandler)(ZValueConnector *aConnector);
// handler for other notifications
typedef void (^ZValueConnectorNotifyHandler)(ZValueConnector *aConnector);
// - custom validation
typedef BOOL (^ZValueConnectorValidationHandler)(ZValueConnector *aConnector, id aValue, NSError **aErrorP);


/// protocol for objects that own ZValueConnector objects. If owner implements the optional methods,
/// it will be notified about value and validation state changes
@protocol ZValueConnectorOwner <NSObject>
@optional
/// called when the internal value changes
/// @note if autoSaveValue is not set, the external (connected) value has not yet changed when this method is called
/// @param aConnector the connector that has a changed value
- (BOOL)valueChangedInConnector:(ZValueConnector *)aConnector;
/// called when the validation status of the value has changed
/// @param aConnector the connector that has a changed validation status
/// @param aError nil if the validation has changed to ok, or a NSError describing why the validation is not ok
- (BOOL)validationStatusChangedInConnector:(ZValueConnector *)aConnector error:(NSError *)aError;
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
/// @param aActive YES to activate connectors, NO to deactivate.
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
/// @param aConnector a ZValueConnector, usually created with [ZValueConnector connectorWithValuePath:owner:]
- (ZValueConnector *)registerValueConnector:(ZValueConnector *)aConnector;

@end



/// ZValueConnector provides for iOS something similar to what Cocoa bindings are for OS X.
///
/// In the KVC paradigm, a ZValueConnector is a object which is normally used to
/// connect a data model value to a controller or view object which represents that value in the UI.
///
/// Each ZValueConnector has two ends both working with KVC (key value coding):
///
/// - the external end, which is meant as the "socket" to connect a
///   data model property value with. It is established with the connectTo:keyPath: method.
/// - the internal end, which is meant as the "internal wiring" within a controller or
///   UIControl object, which embeds the ZValueConnector. This is usually established when
///   the ZValueConnector is instantiated with initWithValuePath:owner: or connectorWithValuePath:owner:
///   The owner can optionally implement the ZValueConnectorOwner protocol to get notified of what happens in the connectors.
///
/// ZValueConnector has various options to establish and maintain a connection between these two ends.
/// The connection can be immediately updating (live display/editing) or only upon request (load/save semantics).
/// Validation can also be immediate or upon attempt to save.
/// ZValueConnector also supports the use of NSValueTransformer and NSFormatter objects to convert between model
/// values and their UI representations.
///
/// @warning ZValueConnector uses KVC and KVO and retains its target object as long as it is active.
/// To avoid retain cycles and memory leaks, it is therefore essential to make sure all value connectors
/// are set inactive (active = NO) by their owning objects _before_ releasing them. To simplify this,
/// the ZValueConnectorContainerImpl category on NSObject provides a registry for valueConnectors embedded
/// in an object, and allows using [ZValueConnectorContainerImpl setValueConnectorsActive:] to control all
/// of an object's valueConnectors at once. Still, you need to make sure deactivation occurs in your
/// object before dealloc (in UIViewControllers, viewDidDisappear is a good place for this).
@interface ZValueConnector : NSObject

/// @name initialisation


/// initialize the connector with an owner and a valuePath referencing the internal value
/// @param aValuePath the key path for the internal value (relative to aOwner)
/// @param aOwner the owner of this ZValueConnector, usually the UI object or controller that embeds it.
/// @note the internal value is usually the value prooperty of the editing/displaying control
- (id)initWithValuePath:(NSString *)aValuePath owner:(id)aOwner;

/// convenience method to create a new ZValueConnector for some internal value.
/// @param aValuePath the key path for the internal value (relative to aOwner)
/// @param aOwner the owner of this ZValueConnector, usually the UI object or controller that embeds it.
+ (id)connectorWithValuePath:(NSString *)aValuePath owner:(id)aOwner;

/// the owner of this connector (usually the object which has the connector embedded)
/// @note this also is the object which builds the root for internal valuepaths as passed to initWithValuePath:owner:
@property (unsafe_unretained, readonly, nonatomic) id owner;

/// disconnect - prepare for being deleted (should null everything that might hold references)
- (void)disconnect;

/// convenience initializer, when ZValueConnector is used for binding the value of a UIControl.
/// @param aValuePath the key path for the control's value (e.g. "text" for a UITextField or "on" for a UISwitch)
/// @param aControl This UIControl becomes the owner of the valueConnector, and will be added a target/action
///   to notify the valueconnector about changes in the control's value (UIControlEventEditingChanged).
- (id)initForKeyPath:(NSString *)aValuePath inControl:(UIControl *)aControl;

/// convenience method for creating a new ZValueConnector to bind the value of a UIControl.
/// @param aValuePath the key path for the control's value (e.g. "text" for a UITextField or "on" for a UISwitch)
/// @param aControl This UIControl becomes the owner of the valueConnector, and will be added a target/action
///   to notify the valueconnector about changes in the control's value (UIControlEventEditingChanged).
+ (id)connectorForKeyPath:(NSString *)aValuePath inControl:(UIControl *)aControl;


/// @name target (data model) connection


/// target (model) object
/// @note this is where the value is loaded from/stored to, but actual editing does not
///   happen directly on this (but usually on some UI representation of it, such as a text field)
@property (strong, nonatomic) id target;
/// keyPath to attribute/property in target (model) object
@property (strong, nonatomic) NSString *keyPath;
/// convenience one-line connection method
/// @param aTarget target (model) object
/// @param aKeyPath keyPath to attribute/property in target (model) object
- (void)connectTo:(id)aTarget keyPath:(NSString *)aKeyPath;

/// initially off, such that detail views can be built and then activated when everything is in place
@property (assign, nonatomic) BOOL active;

/// set if a value is connected
@property (readonly, nonatomic) BOOL connected;

/// set if currently loading value into internal value
@property (readonly, nonatomic) BOOL loading;



/// save the value to the target (model) attribute
/// @warning DO NOT OVERRIDE!
- (void)saveValue;

/// load (revert) the value from model in container/keyPath.
/// @warning DO NOT OVERRIDE!
- (void)loadValue;

/// get current original value from container/keyPath, without updating internals in any way
/// @note for read/modify/write cycles
- (id)peekOriginalValue;


/// convenience method to collect possible validation errors from connectors
/// @return YES if all connectors validate ok, NO otherwise
/// @param aErrorsP can be passed NULL if no errors should be collected.
/// If *aErrorsP points to a nil value, a NSMutableArray is created when at least one error is encountered.
/// If an existing array is passed, encountered errors will be appended.
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
/// if set, every change to value will actively trigger re-validation (and handler/validationStatusChangedInConnector). Default is NO.
@property (assign, nonatomic) BOOL autoValidate;
/// if set, changes to value will be immediately saved to connected target (model) attribute. Default is NO.
@property (assign, nonatomic) BOOL autoSaveValue;
/// if set, no changes will ever be saved
@property (assign, nonatomic) BOOL readonly;
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
///
/// This is the value pointed to by valuePath, and usually is the value of a UIControl which shows/edits the value
///
/// This property is not KVO compliant, but it is KVC compliant including validation, such that other value
/// connectors can be connected here as long as automatic updates are not needed.
/// @note As an example, the separate editor for ZTextFieldCell/ZTextViewCell (used when not editing in-place)
/// is connected to internalValue. Once the separate editor gets active, it reads internalValue, when
/// the editor is being closed, validation is checked and if ok, internalValue is updated.
@property (strong, nonatomic) id internalValue;

/// if set, internalValue is unsaved, and will be saved on next call to save.
/// @note This can also be set programmatically when the internalValue points to a not permanently
///   KVO-updating value (such as most UIControl value properties), see markInternalValueChanged action method.
@property (assign, nonatomic) BOOL unsavedChanges;

/// Sets unsavedChanges=YES.
/// This method can be directly used as the action in a
/// addTarget:action:forControlEvents: for catching UIControlEventEditingChanged events when
/// internalValue is connected to a not permanently (or not at all) KVO-updating value, such as
/// most UIControl value properties.
/// @note this triggers validation (if autoValidate is set) and saving to the connected model value (if autoSaveValue is set).
- (void)markInternalValueChanged;

/// The internal value, parsed, validated and transformed into representation suitable for being stored in target (model).
///
/// This property is KVO compliant, and is updated at save or whenever the value changes when autoValidate is YES.
/// @note This is the property to connect to with secondary representations (not editors) of a value, which
/// need to be updated while editing (for continuous updating, set autoValidate to YES). Such representations
/// cannot be connected to the model value directly, as (unless autoSave is on) this is not updated until
/// editing ends.
@property (readonly, nonatomic) id valueForExternal; // representation of the value for external storage (validated)

/// if YES, current internal value validates ok
@property (readonly, nonatomic) BOOL validated;

/// nil if validation ok, error otherwise
@property (readonly, nonatomic) NSError *validationError;

/// This can be used to set the value from external sources. Reading is equivalent to reading valueForExternal
/// @warning ONLY CHANGE FROM EXTERNAL! (internal edits should access internalValue or the KVO observed object at owner/valuePath).
@property (strong, nonatomic) id value;


/// Enables extra console logging for debugging a single value connector (as output from multiple connectors is often confusing)
/// @note only works in debug builds
@property (assign, nonatomic) BOOL trace;


/// @name handlers to modify standard behaviour

/// called when internal value changes.
///
/// If callChangedHandlerOnLoad is set, loading of the value from the connected target (model) attribute also triggers this handler
/// The handler should return YES if the value change is fully handled. Otherwise default processing will occur.
@property (copy, nonatomic) ZValueConnectorHandler valueChangedHandler;
- (void)setValueChangedHandler:(ZValueConnectorHandler)valueChangedHandler;
/// called after the value has been saved to the target (model) 
@property (copy, nonatomic) ZValueConnectorNotifyHandler valueSavedHandler;
- (void)setValueSavedHandler:(ZValueConnectorNotifyHandler)valueSavedHandler;
/// called as a first step of internal value validation. This handler can be set to implement custom validation.
@property (copy, nonatomic) ZValueConnectorValidationHandler validationHandler;
- (void)setValidationHandler:(ZValueConnectorValidationHandler)validationHandler; // declaration needed only for XCode autocompletion of block
/// called when validation status changes (i.e. validation becomes invalid or valid)
@property (copy, nonatomic) ZValueConnectorHandler validationChangedHandler;
- (void)setValidationChangedHandler:(ZValueConnectorHandler)validationChangedHandler; // declaration needed only for XCode autocompletion of block




@end
