//
//  GHTestApp.h
//  GHUnit
//
//  Created by Gabriel Handford on 1/20/09.
//  Copyright 2009. All rights reserved.
//

#import "GHTestWindowController.h"

@interface GHTestApp : NSObject

- (id)initWithSuite:(GHTestSuite *)suite;

- (void)runTests;

@end
