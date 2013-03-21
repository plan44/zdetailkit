//
//  NSObject+ZValueConnectorContainer.h
//
//  Created by Lukas Zeller on 21.02.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZValueConnector.h"


/// Category which implements ZValueConnectorContainer protocol for any NSObject
@interface NSObject (ZValueConnectorContainerImpl) <ZValueConnectorContainer>

@property (retain, nonatomic) NSMutableArray *valueConnectors;


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

/// convenience method to register a value connector with the object
/// @param aConnector a ZValueConnector, usually created with [ZValueConnector connectorWithValuePath:owner:]
- (ZValueConnector *)registerValueConnector:(ZValueConnector *)aConnector;

@end
