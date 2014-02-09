//
//  GHTestApp.m
//  GHUnit
//
//  Created by Gabriel Handford on 1/20/09.
//  Copyright 2009. All rights reserved.
//

#import "GHTestApp.h"

@implementation GHTestApp  { NSMutableArray *topLevelObjects_; GHTestWindowController *windowController_; GHTestSuite *suite_; }


- (id)init { return  self = super.init ?	windowController_ = GHTestWindowController.new,

	[[NSBundle bundleForClass:self.class] loadNibFile:@"GHTestApp"
                                  externalNameTable:  @{  @"NSOwner": self,
                                                          @"NSTopLevelObjects":topLevelObjects_ = @[].mutableCopy}
                                           withZone:nil],
                                              self : nil;
}

// Since init loads XIB we need to set suite early; For backwards compat.
- (id)initWithSuite:(GHTestSuite *)suite { suite_ = suite; return self = [self init]; }

- (void)awakeFromNib { 

	[NSNotificationCenter.defaultCenter addObserver:self 
														             selector:@selector(applicationWillTerminate:)
															               name:NSApplicationWillTerminateNotification
														               object:nil];

	windowController_.viewController.suite = suite_;
	[windowController_ showWindow:nil];
}
- (void) dealloc 	{ [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void) runTests { [windowController_.viewController runTests]; }

#pragma mark Notifications (NSApplication)

- (void)applicationWillTerminate:(NSNotification *)a { [windowController_.viewController saveDefaults];
	[NSUserDefaults.standardUserDefaults synchronize];
}

@end
