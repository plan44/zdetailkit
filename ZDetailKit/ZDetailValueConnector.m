//
//  ZDetailValueConnector.m
//  ZDetailKit
//
//  Created by Lukas Zeller on 17.05.12.
//  Copyright (c) 2012 plan44.ch. All rights reserved.
//

#import "ZDetailValueConnector.h"

#import "ZString_utils.h"


@interface ZDetailValueConnector ( /* class extension */ )
{
  // non-public instance vars
  BOOL loadedValue; // set after cell value has been loaded for the first time
  BOOL saving; // set during saveValue (recursion breaking flag)
  BOOL loading; // set during revertValue (recursion breaking flag)
  BOOL needsValidation;
}

// private methods
- (void)checkForAutoOps; // save if automatic save / validation

@end



@implementation ZDetailValueConnector


+ (id)connectorWithValuePath:(NSString *)aValuePath owner:(id)aOwner;
{
  return [[[self alloc] initWithValuePath:aValuePath owner:aOwner] autorelease];
}


- (id)initWithValuePath:(NSString *)aValuePath owner:(id)aOwner
{
  if ((self = [super init])) {
    NSAssert(aOwner!=nil,@"owner must be specified");
    owner = aOwner; // not retained!
    valuePath = nil;
    valueChangedHandler = nil;
    validationHandler = nil;
    validationChangedHandler = nil;
    valueTransformer = nil;
    formatter = nil;
    // establish KVO for object (in owner, or subobject of it) representing the cellValue
    self.valuePath = aValuePath;
    // no KVC target yet
    active = NO; // not yet active
    target = nil;
    keyPath = nil;
    readonly = NO; // can save
    nilNulValue = nil; // no internal replacement value for nil/nul
    saveEmptyAsNil = NO;
    saveNilAsNull = NO;
    autoUpdateValue = YES; // by default, follow updates of cell value unless dirty
    autoRevertOnValidationError = NO; // by default, non-validating values will not be reloaded
    loadedValue = NO; // makes sure that value will be loaded once when connected to remote model, even if autoUpdate is off
    autoValidate = NO; // no autovalidation
    autoSaveValue = NO; // and don't automatically save back
    saving = NO; // not saving right now (recursion breaking flag)
    loading = NO; // not loading right now (recursion breaking flag)
    unsavedChanges = NO; // not dirty;
    validated = NO; // currently not validated
    needsValidation = YES; // needs re-validation
  }
  return self;
}


- (void)dealloc
{
  // decativate to remove outside observers
  self.active = NO;
  // forget target
  self.target = nil;
  self.keyPath = nil;
  // deactivate observation of internal object representing the cellValue
  self.valuePath = nil;
  // release handlers, important, as these may retain other objects!
  [valueChangedHandler release];
  [validationHandler release];
  [validationChangedHandler release];
  // Note: owner itself is not retained
  [super dealloc];
}


- (NSString *)description
{
  return [NSString stringWithFormat:@"<ZDetailValueConnector '%@' <-> '%@' in owner:%@", self.keyPath, self.valuePath, [owner description]];
}



#pragma mark - remote (model) and internal (usually control) value connection via KVO/KVC

@synthesize target, keyPath;
@synthesize readonly, autoUpdateValue, autoSaveValue, autoValidate, autoRevertOnValidationError;
@synthesize active;
@synthesize unsavedChanges;
@synthesize valueChangedHandler;
@synthesize validationHandler;
@synthesize formatter, valueTransformer;
@synthesize nilNulValue;
@synthesize saveEmptyAsNil, saveNilAsNull, notNil;



//#warning "%%% Use keyPathsForValuesAffectingValueForKey for groups of properties, like linked dates, allday flags etc."


#define KVO_OPTIONS_FOR_CELL NSKeyValueObservingOptionNew+NSKeyValueObservingOptionInitial


// active is initially off, such that detail views can be built and then activated
// when everything is in place.
- (void)setActive:(BOOL)aActive
{
  if (aActive!=active) {
    if (active && target && keyPath) {
      // connected before - remove KVO
      [target removeObserver:self forKeyPath:keyPath];
    }
    active = aActive;
    if (active && target && keyPath) {
      // connected now - add KVO
      [target addObserver:self
        forKeyPath:keyPath
        options:KVO_OPTIONS_FOR_CELL
        context:NULL
      ];
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
    if (target) {
      // release from KVO if we have a keyPath and an target object
      if (active && keyPath) {
        [target removeObserver:self forKeyPath:keyPath];
      }
      // forget old
      [target release];
      target = nil;
    }
    if (aTarget) {
      target = [aTarget retain];
      // register for KVO if we have a keypath as well
      if (active && keyPath) {
        [target addObserver:self
          forKeyPath:keyPath
          options:KVO_OPTIONS_FOR_CELL
          context:NULL
        ];
      }
    }
  }
}


- (void)setKeyPath:(NSString *)aKeyPath
{
  if (!samePropertyString(&aKeyPath,keyPath)) {
    if (keyPath) {
      // release from KVO if we have a keyPath and a target object
      if (target) {
        [target removeObserver:self forKeyPath:keyPath];
      }
      // forget old
      [keyPath release];
      keyPath = nil;
    }
    if (aKeyPath) {
      // save
      keyPath = [aKeyPath retain];
      // register for KVO if we have a target object as well
      if (active && target) {
        [target addObserver:self
          forKeyPath:keyPath
          options:KVO_OPTIONS_FOR_CELL
          context:NULL
        ];
      }
    }
  }
}


// convenience one-line connect
- (void)connectTo:(id)aTarget keyPath:(NSString *)aKeyPath
{
  if (target!=aTarget) {
    // changing target needs re-establishing KVO, so prevent it until new keyPath is set
    self.keyPath = nil;
    self.target = aTarget;
  }
  // now set the keypath, this will re-establish the KVO
  self.keyPath = aKeyPath;
}



- (BOOL)propagateChange
{      
  // Propagate change
  BOOL handled = NO;
  // - first call handler block, if any
  if (valueChangedHandler) {
    handled = valueChangedHandler(self);
  }
  // - if not yet handled, inform owner
  if (!handled && [owner respondsToSelector:@selector(valueChangedInConnector:)]) {
    handled = [owner valueChangedInConnector:self];
  }
  if (!handled) {
    // - autosave/validate if requested
    [self checkForAutoOps];
  }
  return handled;
}



// This is called by KVO
- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)aObject change:(NSDictionary *)aChange context:(void *)aContext
{
  // check if it is the main object and path, and actually connected
  if (aObject==target && [aKeyPath isEqualToString:keyPath]) {
    // this is the value I am responsible for -> update the cell value
    if (!saving && active && !unsavedChanges && (autoUpdateValue || !loadedValue)) {
      // load new value for cell from remote object
      loadedValue = YES; // now loaded, only update further if autoUpdate is set
      loading = YES;
      id newVal = [aChange objectForKey:NSKeyValueChangeNewKey];
      // filter NSNull
      if (newVal==[NSNull null])
        newVal = nil; 
      self.value = newVal;
      loading = NO;
    }
  }
  else if (aObject==owner && [aKeyPath isEqualToString:[self valuePath]]) {
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
    if (valuePath) {
      [owner removeObserver:self forKeyPath:valuePath];      
    }
    [valuePath release];
    valuePath = nil;
    if (aValuePath) {
      valuePath = [aValuePath retain];
      [owner addObserver:self
        forKeyPath:valuePath
        options:NSKeyValueObservingOptionNew
        context:NULL
      ];
    }
    [self loadValue]; // if active, this will load the value into the new valuePath
  }
}





#pragma mark - validation


- (BOOL)validateAndConvert:(id *)aInOutValueP error:(NSError **)aErrorP
{
  BOOL validates = YES;
  id val = *aInOutValueP;
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
      val = [valueTransformer reverseTransformedValue:val];
    }
    // check for non-nil
    if (notNil && val==nil) {
      // non-empty not allowed
      if (aErrorP) {
        *aErrorP = [NSError errorWithDomain:@"ZValidationError" code:NSKeyValueValidationError userInfo:
          [NSDictionary dictionaryWithObjectsAndKeys:
            @"Empty value not allowed", NSLocalizedDescriptionKey,
            nil
          ]
        ];
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
  // return validation result
  return validates;
}


@synthesize validated;
@synthesize validationError;
@synthesize validationChangedHandler;

- (BOOL)validated
{
  if (needsValidation) {
    NSError *err = nil;
    id val = self.internalValue;
    validated = [self validateAndConvert:&val error:&err];
    needsValidation = NO;
    if (val!=valueForExternal) {
      [valueForExternal release];
      valueForExternal = [val retain];
    }
    if (err!=validationError) {
      [validationError release];
      validationError = [err retain];
      BOOL handled = NO;
      // - first call handler block, if any
      if (validationChangedHandler) {
        handled = validationChangedHandler(self);
      }
      // - if not yet handled, inform owner
      if (!handled && [owner respondsToSelector:@selector(validationStatusChangedInConnector:error:)]) {
        handled = [owner validationStatusChangedInConnector:self error:validationError];
      }
      // - only if unhandled, consider reverting to original value
      if (!handled && self.autoRevertOnValidationError) {
        [self loadValue];
      }
      if (validated)
        DBGNSLOG(@"Validation status OK - connector:%@",self.description);
      else
        DBGNSLOG(@"Validation error=%@ - connector:%@",self.validationError, self.description);
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
  [owner setValue:aInternalValue forKeyPath:self.valuePath];
}


// KVC calls this to validate the internalValue attribute, so if
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




// explicitly mark unsaved or saved 
- (void)setUnsavedChanges:(BOOL)aUnsavedChanges
{
  unsavedChanges = aUnsavedChanges;
  // trigger change propagation, even if already unsaved before
  if (unsavedChanges) {
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
  // modify the internal object
  unsavedChanges = NO;
  if (self.valuePath) {
    loading = YES;
    // basic transformation
    if (valueTransformer) {
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
    // set internal editor object to result
    [owner setValue:aValue forKeyPath:self.valuePath];
    loading = NO;
  }
}


// revert value from last saved (or original) value
- (void)loadValue
{
  if (active && target && keyPath) {
    self.value = [target valueForKeyPath:keyPath];
    needsValidation = YES; // in case we had a validation error before, this is needed to clear it
  }
}


- (void)saveValue
{
  if (!readonly && active && !saving && unsavedChanges) {
    saving = YES;
    if (self.validated) {
      if (target && keyPath) {
        [target setValue:self.value forKeyPath:keyPath];
        unsavedChanges = NO;
      }
    }
    saving = NO;
  }
}


@end
