
#import "GHTestViewModel.h"
#import "GHTesting.h"

@implementation GHTestViewModel // @synthesize root=root_, editing=editing_;
{
//	GHTestSuite *suite_;	GHTestNode *root_;	GHTestRunner *runner_;
	NSMutableDictionary *_map, *_defaults; // id<GHTest>#identifier -> GHTestNode
  NSString *_identifier;
//	BOOL editing_;
}

- (id)initWithIdentifier:(NSString *)identifier suite:(GHTestSuite *)suite {

	if (!(self = [super init])) return nil;
  _identifier = identifier;
  _root = [GHTestNode.alloc initWithTest:_suite = suite children:self.suite.children source:self];
  _map = NSMutableDictionary.new;
	return self;
}

- (void)dealloc {
	// Clear delegates
	for(NSString *identifier in _map) [_map[identifier] setDelegate:nil];

  [_runner cancel];
  _runner.delegate = nil;
  
}

- (NSString *)name { return _root.name; }

- (NSString *)statusString:(NSString *)prefix {

	NSInteger totalRunCount = _suite.stats.testCount - (_suite.disabledCount + _suite.stats.cancelCount);
	NSString *statusInterval = [NSString stringWithFormat:@"%@ %0.3fs (%0.3fs in test time)", self.running ? @"Running" : @"Took", _runner.interval,_suite.interval];
	return [NSString stringWithFormat:@"%@%@ %ld/%ld (%ld failures)", prefix, statusInterval, _suite.stats.succeedCount, totalRunCount, _suite.stats.failureCount];
}

- (void)registerNode:(GHTestNode *)node { _map[node.identifier] = node; node.delegate = self; }

- (GHTestNode *)findTestNodeForTest:(id<GHTest>)test {
	return _map[test.identifier];
}

- (GHTestNode *)findFailure {	return [self findFailureFromNode:_root];   }

- (GHTestNode *)findFailureFromNode:(GHTestNode *)node {
	if (node.failed && [node.test exception]) return node;
	for(GHTestNode *childNode in node.children) {
		GHTestNode *foundNode = [self findFailureFromNode:childNode];
		if (foundNode) return foundNode;
	}
	return nil;
}

- (NSInteger)numberOfGroups { return _root.children.count; }

- (NSInteger)numberOfTestsInGroup:(NSInteger)group {
	NSArray *children = _root.children;
	if ([children count] == 0) return 0;
	GHTestNode *groupNode = children[group];
	return [[groupNode children] count];
}

- (NSIndexPath *)indexPathToTest:(id<GHTest>)test {
	NSInteger section = 0;
	for(GHTestNode *node in _root.children) {
		NSInteger row = 0;		
		if ([node.test isEqual:test]) {
			NSUInteger pathIndexes[] = {section,row};
			return [NSIndexPath indexPathWithIndexes:pathIndexes length:2]; // Not user row:section: for compatibility with MacOSX
		}
		for(GHTestNode *childNode in [node children]) {
			if ([childNode.test isEqual:test]) {
				NSUInteger pathIndexes[] = {section,row};
				return [NSIndexPath indexPathWithIndexes:pathIndexes length:2];
			}
			row++;
		}
		section++;
	}
	return nil;
}

- (void)testNodeDidChange:(GHTestNode *)node { }

- (NSString*) defaultsPath { if (_defaultsPath) return _defaultsPath;

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  if ([paths count] == 0) return nil;
  NSString *identifier = _identifier;
  if (!identifier) identifier = @"Tests";
  return _defaultsPath = [paths[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"GHUnit-%@.tests", identifier]];
}

- (void)_updateTestNodeWithDefaults:(GHTestNode *)node {
  id<GHTest> test = node.test;
  id<GHTest> testDefault = _defaults[test.identifier];
  if (testDefault) {    
    test.status = testDefault.status;
    test.interval = testDefault.interval;
    #if !TARGET_OS_IPHONE // Don't use hidden state for iPhone
    if ([test isKindOfClass:[GHTest class]]) 
      [test setHidden:testDefault.hidden];
    #endif
  }
  for(GHTestNode *childNode in [node children])
    [self _updateTestNodeWithDefaults:childNode];
}

- (void)_saveTestNodeToDefaults:(GHTestNode *)node {
  _defaults[node.test.identifier] = node.test;
  for(GHTestNode *childNode in [node children])
    [self _saveTestNodeToDefaults:childNode];
}

- (void)loadDefaults {  

  _defaults = _defaults ?: self.defaultsPath ? [NSKeyedUnarchiver unarchiveObjectWithFile:_defaultsPath] : NSMutableDictionary.dictionary;

  [self _updateTestNodeWithDefaults:_root];
}

- (void) saveDefaults {

  if (!self.defaultsPath || !_defaults) return;
  
  [self _saveTestNodeToDefaults:_root];
  [NSKeyedArchiver archiveRootObject:_defaults toFile:self.defaultsPath];
}

- (void)cancel {	 [_runner cancel]; }

- (void)run:(id<GHTestRunnerDelegate>)delegate inParallel:(BOOL)inParallel options:(GHTestOptions)options {  
  // Reset (non-disabled) tests so we don't clear non-filtered tests status; in case we re-filter and they become visible
  for(id<GHTest> test in _suite.children)  if (!test.disabled) [test reset];
  
  _runner = _runner ?: [GHTestRunner runnerForSuite:_suite];

  _runner.delegate = delegate;
  _runner.options = options;
  [_runner setInParallel:inParallel];
	[_runner runInBackground];
}

- (BOOL)running { return _runner.isRunning; }

@end

@implementation GHTestNode

@synthesize test=test_, children=children_, delegate=delegate_, filter=filter_, textFilter=textFilter_;

- (id)initWithTest:(id<GHTest>)test children:(NSArray */*of id<GHTest>*/)children source:(GHTestViewModel *)source {
	if ((self = [super init])) {
		test_ = test;
		
		NSMutableArray *nodeChildren = [NSMutableArray array];
		for(id<GHTest> test in children) {	
			
			GHTestNode *node = nil;
			if ([test conformsToProtocol:@protocol(GHTestGroup)]) {
				NSArray *testChildren = [(id<GHTestGroup>)test children];
				if ([testChildren count] > 0) 
					node = [GHTestNode nodeWithTest:test children:testChildren source:source];
			} else {
				node = [GHTestNode nodeWithTest:test children:nil source:source];
			}			
			if (node)
				[nodeChildren addObject:node];
		}
		children_ = nodeChildren;
		[source registerNode:self];
	}
	return self;
}


+ (GHTestNode *)nodeWithTest:(id<GHTest>)test children:(NSArray *)children source:(GHTestViewModel *)source {
	return [[GHTestNode alloc] initWithTest:test children:children source:source];
}

- (BOOL)hasChildren {
	return [self.children count] > 0;
}

- (void)notifyChanged {
	[delegate_ testNodeDidChange:self];
}

- (NSArray *)children {
  if (filter_ != GHTestNodeFilterNone || textFilter_) return filteredChildren_;
  return children_;
}

- (void)_applyFilters {  
  NSMutableSet *textFiltered = [NSMutableSet set];
  for(GHTestNode *childNode in children_) {
    [childNode setTextFilter:textFilter_];
    if (textFilter_) {
      if (([self.name rangeOfString:textFilter_].location != NSNotFound) || ([childNode.name rangeOfString:textFilter_].location != NSNotFound) || [childNode hasChildren]) 
        [textFiltered addObject:childNode];
    }
  }
  
  NSMutableSet *filtered = [NSMutableSet set];
  for(GHTestNode *childNode in children_) {      
    [childNode setFilter:filter_];
    if (filter_ == GHTestNodeFilterFailed) { 
      if ([childNode hasChildren] || childNode.failed)
        [filtered addObject:childNode];
    }
  }
  
  filteredChildren_ = [NSMutableArray array];
  for(GHTestNode *childNode in children_) {
    if (((!textFilter_ || [textFiltered containsObject:childNode]) && 
        (filter_ == GHTestNodeFilterNone || [filtered containsObject:childNode])) || [childNode hasChildren]) {
      [filteredChildren_ addObject:childNode];
      if (![childNode hasChildren]) {
        [childNode.test setDisabled:NO];
      }
    } else {
      if (![childNode hasChildren]) {
        [childNode.test setDisabled:YES];
      }
    }
  }
}

- (void)setTextFilter:(NSString *)textFilter {
  [self setFilter:filter_ textFilter:textFilter];
}

- (void)setFilter:(GHTestNodeFilter)filter {
  [self setFilter:filter textFilter:textFilter_];
}

- (void)setFilter:(GHTestNodeFilter)filter textFilter:(NSString *)textFilter {
  filter_ = filter;
  
  textFilter = [textFilter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([textFilter isEqualToString:@""]) textFilter = nil;
  
  textFilter_ = textFilter;    
  [self _applyFilters];    
}

- (NSString *)name {
	return [test_ name];
}

- (NSString *)identifier {
	return [test_ identifier];
}

- (NSString *)statusString {
	// TODO(gabe): Some other special chars: ☐✖✗✘✓
	NSString *status = @"";
	NSString *interval = @"";
	if (self.isRunning) {
		status = @"✸";
		if (self.isGroupTest)
			interval = [NSString stringWithFormat:@"%0.2fs", [test_ interval]];
	} else if (self.isEnded) {
		if ([test_ interval] >= 0)
			interval = [NSString stringWithFormat:@"%0.2fs", [test_ interval]];

		if ([test_ status] == GHTestStatusErrored) status = @"✘";
		else if ([test_ status] == GHTestStatusSucceeded) status = @"✔";
		else if ([test_ status] == GHTestStatusCancelled) {
			status = @"-";
			interval = @"";
		} else if ([test_ isDisabled] || [test_ isHidden]) {
			status = @"⊝";
			interval = @"";
		}
	} else if (!self.isSelected) {
		status = @"";
	}

	if (self.isGroupTest) {
		NSString *statsString = [NSString stringWithFormat:@"%ld/%ld (%ld failed)",
														 ([test_ stats].succeedCount+[test_ stats].failureCount), 
														 [test_ stats].testCount, [test_ stats].failureCount];
		return [NSString stringWithFormat:@"%@ %@ %@", status, statsString, interval];
	} else {
		return [NSString stringWithFormat:@"%@ %@", status, interval];
	}
}

- (NSString *)nameWithStatus {
	NSString *interval = @"";
	if (self.isEnded) interval = [NSString stringWithFormat:@" (%0.2fs)", [test_ interval]];
	return [NSString stringWithFormat:@"%@%@", self.name, interval];
}

- (BOOL)isGroupTest {
	return ([test_ conformsToProtocol:@protocol(GHTestGroup)]);
}

- (BOOL)failed {
	return [test_ status] == GHTestStatusErrored;
}
	
- (BOOL)isRunning {
	return GHTestStatusIsRunning([test_ status]);
}

- (BOOL)isDisabled {
	return [test_ isDisabled];
}

- (BOOL)isHidden {
	return [test_ isHidden];
}

- (BOOL)isEnded {
	return GHTestStatusEnded([test_ status]);
}

- (GHTestStatus)status {
	return [test_ status];
}

- (NSString *)stackTrace {
	if (![test_ exception]) return nil;

	return [GHTesting descriptionForException:[test_ exception]];
}

- (NSString *)exceptionFilename {
  return [GHTesting exceptionFilenameForTest:test_];
}

- (NSInteger)exceptionLineNumber {
  return [GHTesting exceptionLineNumberForTest:test_];
}

- (NSString *)log {
	return [[test_ log] componentsJoinedByString:@"\n"]; // TODO(gabe): This isn't very performant
}

- (NSString *)description {
	return [test_ description];
}

- (BOOL)isSelected {
	return ![test_ isHidden];
}

- (void)setSelected:(BOOL)selected {
	[test_ setHidden:!selected];
	for(GHTestNode *node in children_) 
		[node setSelected:selected];
	[self notifyChanged];
}

@end

//! @endcond


//
//  GHTestViewModel.m
//  GHUnit
//
//  Created by Gabriel Handford on 1/17/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

//! @cond DEV
