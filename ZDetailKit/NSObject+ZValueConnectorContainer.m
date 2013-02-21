//
//  NSObject+ZValueConnectorContainer.m
//  iosapps
//
//  Created by Lukas Zeller on 21.02.13.
//  Copyright (c) 2013 plan44.ch. All rights reserved.
//

#import "NSObject+ZValueConnectorContainer.h"

#import <objc/runtime.h>


@implementation NSObject (ZValueConnectorContainerImpl)

@dynamic valueConnectors;


#pragma mark - associated object for valueconnectors array


static char VALEUCONNECTORS_IDENTIFER; // Note: the identifier is the address of that variable (unique per process!)
static char VALEUCONNECTORCONTAINERS_IDENTIFER; // Note: the identifier is the address of that variable (unique per process!)

- (void)setValueConnectors:(NSMutableArray *)aValueConnectors
{
  objc_setAssociatedObject(self, &VALEUCONNECTORS_IDENTIFER, aValueConnectors, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)valueConnectors
{
  NSMutableArray *v = objc_getAssociatedObject(self, &VALEUCONNECTORS_IDENTIFER);
  if (v==nil) {
    // create on first use
    v = [NSMutableArray array];
    self.valueConnectors = v;
  }
  return v;
}

- (void)setValueConnectorContainers:(NSMutableArray *)aValueConnectorContainers
{
  objc_setAssociatedObject(self, &VALEUCONNECTORCONTAINERS_IDENTIFER, aValueConnectorContainers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)valueConnectorContainers
{
  NSMutableArray *v = objc_getAssociatedObject(self, &VALEUCONNECTORCONTAINERS_IDENTIFER);
  if (v==nil) {
    // create on first use
    v = [NSMutableArray array];
    self.valueConnectorContainers = v;
  }
  return v;
}

- (NSMutableArray *)valueConnectorContainersNoCreate
{
  return objc_getAssociatedObject(self, &VALEUCONNECTORCONTAINERS_IDENTIFER);
}



- (void)setValueConnectorsActive:(BOOL)aActive
{
  for (ZValueConnector *connector in self.valueConnectors) {
    connector.active = aActive;
  }
  NSArray *a = [self valueConnectorContainersNoCreate];
  if (a) {
    for (id<ZValueConnectorContainer> vcc in a) {
      [vcc setValueConnectorsActive:aActive];
    }
  }
}


- (void)saveValueConnectors
{
  // save in all connectors
  for (ZValueConnector *connector in self.valueConnectors) {
    [connector saveValue];
  }
  NSArray *a = [self valueConnectorContainersNoCreate];
  if (a) {
    for (id<ZValueConnectorContainer> vcc in a) {
      [vcc saveValueConnectors];
    }
  }
}


- (void)loadValueConnectors
{
  // load in all connectors
  for (ZValueConnector *connector in self.valueConnectors) {
    [connector loadValue];
  }
  NSArray *a = [self valueConnectorContainersNoCreate];
  if (a) {
    for (id<ZValueConnectorContainer> vcc in a) {
      [vcc loadValueConnectors];
    }
  }
}


- (BOOL)connectorsValidateWithErrors:(NSMutableArray **)aErrorsP
{
  BOOL validates = YES;
  // collect validation from all connectors
  for (ZValueConnector *connector in self.valueConnectors) {
    if (connector.connected)
      validates = validates && [connector validatesWithErrors:aErrorsP];
  }
  NSArray *a = [self valueConnectorContainersNoCreate];
  if (a) {
    for (id<ZValueConnectorContainer> vcc in a) {
      validates = validates && [vcc connectorsValidateWithErrors:aErrorsP];
    }
  }
  return validates;
}


- (ZValueConnector *)registerValueConnector:(ZValueConnector *)aConnector
{
  [self.valueConnectors addObject:aConnector];
  return aConnector;
}


- (ZValueConnector *)registerValueConnectorContainer:(id<ZValueConnectorContainer>)aContainer
{
  [self.valueConnectorContainers addObject:aContainer];
  return aContainer;
}





@end
