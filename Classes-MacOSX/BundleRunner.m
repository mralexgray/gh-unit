//
//  BundleTestRunner.m
//  ibuffy
//
//  Created by Dave Dribin on 1/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

static void loadBundle(NSString * bundlePath)
{
    NSException * exception;
    NSBundle * bundle = [NSBundle bundleWithPath: bundlePath];
    if (!bundle)
    {
        NSString * reason = [NSString stringWithFormat:
                               @"Could not find bundle: %@", bundlePath];
        exception = [NSException exceptionWithName: @"BundleLoadException"
                                            reason: reason
                                          userInfo: nil];
        @throw exception;
    }
    
    if (![bundle load])
    {
        NSString * reason = [NSString stringWithFormat:
                               @"Could not load bundle: %@", bundle];
        exception = [NSException exceptionWithName: @"BundleLoadException"
                                            reason: reason
                                          userInfo: nil];
        @throw exception;
    }
}

int main(int argc, char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSBundle * bundle;
    NSString * bundlePath = [[[NSProcessInfo processInfo] environment]
        objectForKey: @"TEST_LOAD_BUNDLE"];

    if (bundlePath != nil)
    {
        loadBundle(bundlePath);
    }
    
    bundlePath =
        [[[NSProcessInfo processInfo] arguments] objectAtIndex: 1];
    loadBundle(bundlePath);
    SenTestSuite * suite;
    suite = [SenTestSuite testSuiteForBundlePath: bundlePath];
    BOOL hasFailed = ![[suite run] hasSucceeded];
    
    [pool release];
    return ((int) hasFailed);
    return 0;
}
