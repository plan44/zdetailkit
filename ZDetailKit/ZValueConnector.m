//
//  ZValueConnector.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 17.05.12.
//  Copyright (c) 2012-2013 plan44.ch. All rights reserved.
//

#import "ZValueConnector.h"

#import "ZDBGMacros.h"
#import "ZString_utils.h"
#import "ZCustomI8n.h"


@interface ZValueConnector ( /* class extension */ )
{
  // non-public instance vars
  BOOL loadedValue; // set after cell value has been loaded for the first time
  BOOL saving; // set during saveValue (recursion breaking flag)
  BOOL loading; // set during revertValue (recursion breaking flag)
  BOOL propagating; // set during propagation of a new value (recursion breaking flag)
  BOOL setting; // set during setting of internal value (recursion breaking flag, especially for valueChangedHandlers)
  BOOL needsValidation;
}

// private
- (void)checkForAutoOps; // save if automatic save / validation
@property (readonly,nonatomic) NSString *shortDesc;
@end


#ifdef DEBUG
#define TRACELOG(...) { if (_trace) NSLog(__VA_ARGS__); }
#define IFTRACE if (_trace) {
#define ENDIFTRACE }
#else
#define TRACELOG(...)
#define IFTRACE if (NO) {
#define ENDIFTRACE }
#endif


@implementation ZValueConnector


+ (id)connectorForKeyPath:(NSString *)aValuePath inControl:(UIControl *)aControl
{
  return [[self alloc] initForKeyPath:aValuePath inControl:aControl];
}


+ (id)connectorWithValuePath:(NSString *)aValuePath owner:(id)aOwner;
{
  return [[self alloc] initWithValuePath:aValuePath owner:aOwner];
}



- (id)initForKeyPath:(NSString *)aValuePath inControl:(UIControl *)aControl
{
  if ((self = [self initWithValuePath:aValuePath owner:aControl])) {
    // register for value changes in the control (note: target is not retained, so it will not prevent deallocation of myself)
    [aControl addTarget:self action:@selector(markInternalValueChanged) forControlEvents:UIControlEventEditingChanged];
  }
  return self;
}


- (id)initWithValuePath:(NSString *)aValuePath owner:(id)aOwner
{
  if ((self = [super init])) {
    NSAssert(aOwner!=nil,@"owner must be specified");
    owner = aOwner; // weak, not retained!
    valuePath = nil;
    valueChangedHandler = nil;
    valueSavedHandler = nil;
    validationHandler = nil;
    validationChangedHandler = nil;
    valueTransformer = nil;
    transformReversed = NO;
    formatter = nil;
    // establish KVO for object (in owner, or subobject of it) representing the cellValue
    self.valuePath = aValuePath;
    // no KVC target yet
    active = NO; // not yet active
    target = nil;
    keyPath = nil;
    nilAllowed = YES; // nil/null (= no value) allowed
    readonly = NO; // can save
    nilNulValue = nil; // no internal replacement value for nil/nul
    saveEmptyAsNil = NO;
    saveNilAsNull = NO;
    autoUpdateValue = YES; // by default, follow updates of cell value unless dirty
    callChangedHandlerOnLoad = YES; // value changed handler will be called for load and (when autoUpdateValue is set) for external value changes
    autoRevertOnValidationError = NO; // by default, non-validating values will not be reloaded
    loadedValue = NO; // makes sure that value will be loaded once when connected to remote model, even if autoUpdate is off
    autoValidate = NO; // no autovalidation
    autoSaveValue = NO; // and don't automatically save back
    saving = NO; // not saving right now (recursion breaking flag)
    loading = NO; // not loading right now (recursion breaking flag)
    propagating = NO; // not propagating value (recursion breaking flag)
    setting = NO; // not setting internal value right now
    unsavedChanges = NO; // not dirty;
    validated = NO; // currently not validated
    needsValidation = YES; // needs re-validation
    _trace = NO; // no trace by default
  }
  return self;
}


- (void)dealloc
{
  [self disconnect];
}


- (void)disconnect
{
  // decativate to remove outside observers
  self.active = NO;
  // forget target
  self.keyPath = nil;
  // deactivate observation of internal object representing the cellValue
  self.valuePath = nil;
  // release handlers, important, as these may retain other objects!
  valueChangedHandler = nil;
  valueSavedHandler = nil;
  validationHandler = nil;
  validationChangedHandler = nil;
  // Note: owner itself is not a strong reference
}


- (NSString *)description
{
  return [NSString stringWithFormat:@"<ZValueConnector '%@.%@' <-> '%@.%@' in owner:%@", [target class], self.keyPath, [owner class], self.valuePath, [owner description]];
}


- (NSString *)shortDesc
{
  return [NSString stringWithFormat:@"<model(%@.%@) <-> editor(%@.%@) in %@>", [target class], self.keyPath, [owner class], self.valuePath, [owner class]];
}



#pragma mark - remote (model) and internal (usually control) value connection via KVO/KVC

@synthesize target, keyPath;
@synthesize readonly, autoUpdateValue, autoSaveValue, autoValidate, autoRevertOnValidationError, callChangedHandlerOnLoad;
@synthesize active;
@synthesize unsavedChanges;
@synthesize valueChangedHandler;
@synthesize valueSavedHandler;
@synthesize validationHandler;
@synthesize formatter, valueTransformer;
@synthesize transformReversed;
@synthesize nilNulValue;
@synthesize saveEmptyAsNil, saveNilAsNull, nilAllowed;
@synthesize loading, setting;



- (void)connectTargetValue
{
  if (active && target && keyPath) {
    // connected now - add KVO
    // - activating KVO will most probably lead to loading the value, which in turn influences valueForExternal
    [self willChangeValueForKey:@"valueForExternal"];
    // - now setup KVO
    [target addObserver:self
      forKeyPath:keyPath
      options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionInitial
      context:NULL
    ];
    // - KVO has now caused loading the value
    [self didChangeValueForKey:@"valueForExternal"];
  }  
}


- (void)disconnectTargetValue
{
  if (active && target && keyPath) {
    // connected before - remove KVO
    [target removeObserver:self forKeyPath:keyPath];
  }  
}



// active is initially off, such that detail views can be built and then activated
// when everything is in place.
- (void)setActive:(BOOL)aActive
{
  if (aActive!=active) {
    IFTRACE
    NSLog(@"valueConnector changes active to %d - %@", aActive, self.shortDesc);
    ENDIFTRACE
    if (active) {
      // first disconnect externally
      [self disconnectTargetValue];
      // then internally
      if (valuePath) {
        // also remove interna connection
        [owner removeObserver:self forKeyPath:valuePath];      
      }
    }
    active = aActive;
    if (active) {
      // connect internally first 
      if (valuePath) {
        // also establish internal connection
        [owner addObserver:self
          forKeyPath:valuePath
          options:NSKeyValueObservingOptionNew
          context:NULL
        ];
      }      
      // connect to target value via KVO
      [self connectTargetValue];
    }    
  }
}


// this can be queried to see if an optional value is connected
- (BOOL)connected
{
  // value is connected if we are active and have a target and a keypath
  return active && target && keyPath;
}


- (void)setTarget:(id)aTarget
{
  if (aTarget!=target) {
    IFTRACE
    NSLog(@"valueConnector sets target to %@ - %@", aTarget, self.shortDesc);
    ENDIFTRACE
    if (target) {
      // release from KVO if we have a keyPath and an target object
      [self disconnectTargetValue];
      // forget old
      target = nil;
    }
    if (aTarget) {
      target = aTarget;
      // connect to new target value via KVO
      [self connectTargetValue];
    }
  }
}


- (void)setKeyPath:(NSString *)aKeyPath
{
  if (!samePropertyString(&aKeyPath,keyPath)) {
    IFTRACE
    NSLog(@"valueConnector sets keyPath to %@ - %@", aKeyPath, self.shortDesc);
    ENDIFTRACE
    if (keyPath) {
      // release from KVO if we have a keyPath and a target object
      [self disconnectTargetValue];
      // forget old
      keyPath = nil;
    }
    if (aKeyPath) {
      // save
      keyPath = aKeyPath;
      // register for KVO if we have a target object as well
      [self connectTargetValue];
    }
  }
}


// convenience one-line connect
- (void)connectTo:(id)aTarget keyPath:(NSString *)aKeyPath
{
  IFTRACE
  NSLog(@"valueConnector connectTo:%@ keyPath:%@ - %@", [aTarget class], aKeyPath, self.shortDesc);
  ENDIFTRACE
  if (target!=aTarget) {
    // changing target needs re-establishing KVO, so prevent it until new keyPath is set
    self.keyPath = nil;
    self.target = aTarget; // will not yet establish KVO because keyPath is nil
  }
  // now set the keypath, this will re-establish the KVO
  self.keyPath = aKeyPath;
}



- (BOOL)propagateChange
{      
  // Propagate change
  BOOL handled = NO;
  if (!propagating) {
    propagating = YES;
    // - first call handler block, if any
    if (valueChangedHandler) {
      IFTRACE
      NSLog(@"- calling valueChangedHandler");
      ENDIFTRACE
      handled = valueChangedHandler(self);
    }
    // - if not yet handled, inform owner
    if (!handled && [owner respondsToSelector:@selector(valueChangedInConnector:)]) {
      IFTRACE
      NSLog(@"- calling valueChangedInConnector delegate method");
      ENDIFTRACE
      handled = [owner valueChangedInConnector:self];
    }
    if (!handled) {
      // - autosave/validate if requested
      [self checkForAutoOps];
    }
    propagating = NO;
  }
  return handled;
}



// This is called by KVO
- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)aObject change:(NSDictionary *)aChange context:(void *)aContext
{
  // check if it is the main object and path, and actually connected
  if (aObject==target && [aKeyPath isEqualToString:keyPath]) {
    IFTRACE
    NSLog(@"received KVO notification for model path %@ - %@", keyPath, self.shortDesc);
    ENDIFTRACE
    // this is the value I am responsible for -> update the cell value
    if (!saving && active && !unsavedChanges && (autoUpdateValue || !loadedValue)) {
      // load new value for cell from remote object
      if (!loadedValue) {
        needsValidation = YES; // loading needs initial validation to make sure valueForExternal is up-to-date
      }
      loadedValue = YES; // now loaded, only update further if autoUpdate is set
      loading = YES;
      id newVal = [aChange objectForKey:NSKeyValueChangeNewKey];
      IFTRACE
      NSLog(@"- loading new value %@", newVal);
      ENDIFTRACE
      // filter NSNull
      if (newVal==[NSNull null])
        newVal = nil; 
      self.value = newVal; // this resets "loading"
      loading = YES; // set it again so valueChangedHandler can check it
      if (callChangedHandlerOnLoad && valueChangedHandler) {
        IFTRACE
        NSLog(@"- calling valueChangedHandler");
        ENDIFTRACE
        valueChangedHandler(self);
      }
      loading = NO;
    }
  }
  else if (aObject==owner && [aKeyPath isEqualToString:[self valuePath]]) {
    IFTRACE
    NSLog(@"received KVO notification from internalValue path %@ - %@", valuePath, self.shortDesc);
    ENDIFTRACE
    // this is a change to the internal object represented by the cell
    if (!loading) {
      // - mark dirty
      unsavedChanges = YES;
      needsValidation = YES;
      // - Propagate change
      [self propagateChange];
    }
  }
  else {
    // super might be observing other paths
    [super observeValueForKeyPath:aKeyPath ofObject:aObject change:aChange context:aContext];
  }
}



// change the internal object representing this value
- (void)setValuePath:(NSString *)aValuePath
{
  if (!samePropertyString(&aValuePath, valuePath)) {
    IFTRACE
    NSLog(@"set new internalValue path to %@ - %@", aValuePath, self);
    ENDIFTRACE
    if (valuePath && active) {
      [owner removeObserver:self forKeyPath:valuePath];      
    }
    valuePath = nil;
    if (aValuePath) {
      valuePath = aValuePath;
      if (active) {
        [owner addObserver:self
          forKeyPath:valuePath
          options:NSKeyValueObservingOptionNew
          context:NULL
        ];
      }
    }
    [self loadValue]; // if active, this will load the value into the new valuePath
  }
}





#pragma mark - validation


- (BOOL)validateAndConvert:(id *)aInOutValueP error:(NSError **)aErrorP
{
  BOOL validates = YES;
  id val = *aInOutValueP;
  IFTRACE
  NSLog(@"validateAndConvert starts with val = %@ - %@", val, self.shortDesc);
  ENDIFTRACE
  // custom validation comes first
  if (validationHandler) {
    NSError *err = nil;
    validates = validationHandler(self, val, &err);
    if (aErrorP && err) *aErrorP = err;
  }
  // possibly convert empty string to nil
  if (saveEmptyAsNil && val && [val length]==0) {
    val = nil;
  }
  if (formatter && val) {
    // parse string format
    NSString *conversionError = nil;
    if (![formatter getObjectValue:&val forString:val errorDescription:&conversionError]) {
      if (aErrorP) {
        *aErrorP = [NSError errorWithDomain:@"ZValidationError" code:NSKeyValueValidationError userInfo:
          [NSDictionary dictionaryWithObjectsAndKeys:
            conversionError, NSLocalizedDescriptionKey,
            nil
          ]
        ];
      }
      validates = NO;
    }
  }
  if (validates) {
    if (valueTransformer) {
      if (transformReversed)
        val = [valueTransformer transformedValue:val];
      else
        val = [valueTransformer reverseTransformedValue:val];
    }
    // check for non-nil
    if (!nilAllowed && val==nil) {
      // non-empty not allowed
      if (aErrorP) {
        *aErrorP = [NSError errorWithDomain:@"ZValidationError" code:NSKeyValueValidationError userInfo:@{
          NSLocalizedDescriptionKey: ZLocalizedStringWithDefault(@"ZDTK_ValErr_NotEmpty",@"Empty value not allowed")
        }];
      }
      validates = NO;
    }
  }
  // Internal validation done
  if (validates) {
    // represent nil as NSNull if selected
    if (saveNilAsNull && val==nil) {
      val = [NSNull null];
    }
    // If valid, now check against KVC connected external value which is supposed to receive this value
    if (self.connected) {
      NSError *err = nil;
      if (![target validateValue:&val forKeyPath:keyPath error:&err]) {
        // external validation error
        if (aErrorP) {
          *aErrorP = err;
        }
        validates = NO;
        val = nil;
      }
    }
  }
  // pass back
  *aInOutValueP = validates ? val : nil;
  IFTRACE
  NSLog(@"- result: validated=%d, val = %@", validates, val);
  ENDIFTRACE
  // return validation result
  return validates;
}


@synthesize validated;
@synthesize validationError;
@synthesize validationChangedHandler;

- (BOOL)validated
{
  if (needsValidation) {
    IFTRACE
    NSLog(@"validation needed - %@", self.shortDesc);
    ENDIFTRACE
    NSError *err = nil;
    id val = self.internalValue;
    validated = [self validateAndConvert:&val error:&err];
    needsValidation = NO;
    if (val!=valueForExternal) {
      IFTRACE
      NSLog(@"- valueForExternal changes during validation to %@", val);
      ENDIFTRACE
      [self willChangeValueForKey:@"valueForExternal"];
      valueForExternal = val;
      [self didChangeValueForKey:@"valueForExternal"];
    }
    if (err!=validationError) {
      validationError = err;
      BOOL handled = NO;
      // - first call handler block, if any
      if (validationChangedHandler) {
        IFTRACE
        NSLog(@"- calling validationChangedHandler");
        ENDIFTRACE
        handled = validationChangedHandler(self);
      }
      // - if not yet handled, inform owner
      if (!handled && [owner respondsToSelector:@selector(validationStatusChangedInConnector:error:)]) {
        IFTRACE
        NSLog(@"- calling validationStatusChangedInConnector delegate method");
        ENDIFTRACE
        handled = [owner validationStatusChangedInConnector:self error:validationError];
      }
      // - only if unhandled, consider reverting to original value
      if (!handled && self.autoRevertOnValidationError) {
        [self loadValue];
      }
      if (validated)
        DBGNSLOG(@"Validation status OK - connector:%@",self.shortDesc);
      else
        DBGNSLOG(@"Validation error=%@ - connector:%@",self.validationError, self.shortDesc);
    }
  }
  return validated;
}


- (NSError *)validationError
{
  // force updated validation status
  [self validated];
  return validationError;
}



- (BOOL)validatesWithErrors:(NSMutableArray **)aErrorsP
{
  BOOL validates = [self validated];
  if (!validates && aErrorsP && self.validationError) {
    // collect reason for not validating here
    if (*aErrorsP==nil)
      *aErrorsP = [NSMutableArray array]; // no errors so far, create new array
    // add error
    [*aErrorsP addObject:self.validationError];
  }
  return validates;
}



#pragma mark - internal and external representation of value


@synthesize owner, valuePath, value;
@synthesize internalValue;
@synthesize valueForExternal;


// the internal value. Detail editors for a value can be connected to this one
- (id)internalValue
{
  return [owner valueForKeyPath:self.valuePath];
}


// secondary detail editors might deliver changes to this value.
// The same changes might also get delivered directly to the
// object at owner/valuePath
- (void)setInternalValue:(id)aInternalValue
{
  setting = YES; // Note: flag is not used internally, but valueChangedHandlers might want to check it
  // Note: value for external implicitly changes as well, so alert it
  IFTRACE
  NSLog(@"internalValue set to %@ - %@", aInternalValue, self.shortDesc);
  ENDIFTRACE
  [self willChangeValueForKey:@"valueForExternal"];
  @try {
    [owner setValue:aInternalValue forKeyPath:self.valuePath];
  }
  @catch (NSException *exception) {
    DBGNSLOG(@"cannot set internal value to %@ in %@: %@", aInternalValue, self.shortDesc, exception);
  }
  [self didChangeValueForKey:@"valueForExternal"];
  setting = NO;
}


// KVO calls this to validate the internalValue attribute, so if
// we connect secondary editors here we get a end-to-end validation result,
// without actually touching the internalValue itself
- (BOOL)validateInternalValue:(id *)aInternalValueP error:(NSError **)aErrorP
{
  // validate against external value
  id val = *aInternalValueP;
  return [self validateAndConvert:&val error:aErrorP];
}




- (id)valueForExternal
{
  // force updated validation status
  [self validated];
  return valueForExternal;
}


// mark internal value changed
- (void)markInternalValueChanged
{
  self.unsavedChanges = YES;
}


// explicitly mark unsaved or saved 
- (void)setUnsavedChanges:(BOOL)aUnsavedChanges
{
  unsavedChanges = aUnsavedChanges;
  // trigger change propagation, even if already unsaved before
  if (unsavedChanges) {
    IFTRACE
    NSLog(@"unsavedChanges set YES - %@", self.shortDesc);
    ENDIFTRACE
    // marked unsaved now - act like value has changed
    needsValidation = YES;
    [self propagateChange];
  }
}


- (void)checkForAutoOps
{
  if (autoSaveValue) {
    [self saveValue]; // save includes validation anyway
  }
  else if (autoValidate) {
    [self validated]; // update validation status
  }
}


// the value represented by the cell.
- (id)value
{
  if (self.valuePath) {
    id val = self.internalValue;
    [self validateAndConvert:&val error:NULL];
    // return
    return val;
  }
  return nil; // none
}


// This is to set the value from external sources (such as KVO triggered updates from target/keyPath)
// (but internal changes should happen on the internal object itself, which in turn is KVObserved
// to perform autosave and calling custom handlers)
- (void)setValue:(id)aValue
{
  IFTRACE
  NSLog(@"value set to %@ - %@", aValue, self.shortDesc);
  ENDIFTRACE
  // modify the internal object
  unsavedChanges = NO;
  if (self.valuePath) {
    loading = YES;
    // basic transformation
    if (valueTransformer) {
      if (transformReversed)
        aValue = [valueTransformer reverseTransformedValue:aValue];
      else
        aValue = [valueTransformer transformedValue:aValue];
    }
    // possible nil/null -> default value transformation
    if (nilNulValue!=nil && (aValue==nil || aValue==[NSNull null])) {
      aValue = nilNulValue;
    }
    else if (formatter && aValue) {
      // non-nil input, have it formatted
      aValue = [formatter stringForObjectValue:aValue];
    }
    // set internal editor object to result (important to use property as it might be KVOed)
    self.internalValue = aValue;
    loading = NO;
  }
}


- (id)peekOriginalValue
{
  if (target && keyPath) {
    return [target valueForKeyPath:keyPath];
  }
  return nil;
}


// revert value from last saved (or original) value
- (void)loadValue
{
  if (active && target && keyPath) {
    IFTRACE
    NSLog(@"loading value - %@", self.shortDesc);
    ENDIFTRACE
    self.value = [target valueForKeyPath:keyPath];
    needsValidation = YES; // in case we had a validation error before, this is needed to clear it
    if (callChangedHandlerOnLoad && valueChangedHandler && !propagating) {
      propagating = YES;
      valueChangedHandler(self);
      propagating = NO;
    }
  }
}


- (void)saveValue
{
  if (!readonly && active && !saving && unsavedChanges) {
    IFTRACE
    NSLog(@"saving value - %@", self.shortDesc);
    ENDIFTRACE
    saving = YES;
    if (self.validated) {
      if (target && keyPath) {
        [target setValue:self.value forKeyPath:keyPath];
        unsavedChanges = NO;
      }
      // call the handler for possible after-save processing
      if (valueSavedHandler) {
        valueSavedHandler(self);
      }
    }
    saving = NO;
  }
}


@end
