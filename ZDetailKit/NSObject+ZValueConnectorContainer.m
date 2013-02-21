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


- (void)setValueConnectorsActive:(BOOL)aActive
{
  for (ZValueConnector *connector in self.valueConnectors) {
    connector.active = aActive;
  }
}

- (void)saveValueConnectors
{
  // save in all connectors
  for (ZValueConnector *connector in self.valueConnectors) {
    [connector saveValue];
  }
}


- (void)loadValueConnectors
{
  // load in all connectors
  for (ZValueConnector *connector in self.valueConnectors) {
    [connector loadValue];
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
  return validates;
}


- (ZValueConnector *)registerValueConnector:(ZValueConnector *)aConnector
{
  [self.valueConnectors addObject:aConnector];
  return aConnector;
}




@end
