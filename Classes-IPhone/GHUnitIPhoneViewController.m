//
//  GHUnitIPhoneViewController.m
//  GHUnitIPhone
//
//  Created by Gabriel Handford on 1/25/09.
//  Copyright 2009. All rights reserved.
//

#import "GHUnitIPhoneViewController.h"

NSString *const GHUnitPrefixKey = @"Prefix";
NSString *const GHUnitFilterKey = @"Filter";

@interface GHUnitIPhoneViewController ()
- (NSString *)_prefix;
- (void)_setPrefix:(NSString *)prefix;
- (void)_setFilterIndex:(NSInteger)index;
- (NSInteger)_filterIndex;
@end

@implementation GHUnitIPhoneViewController

@synthesize suite=suite_;

- (id)init {
  if ((self = [super init])) {
    self.title = @"Tests";
  }
  return self;
}

- (void)dealloc {
	[dataSource_ release];	
	[suite_ release];
	[super dealloc];
}

- (void)loadDefaults { }

- (void)saveDefaults {
  [dataSource_ saveDefaults];
}

- (void)loadView {
  [super loadView];
    
  if (!runButton_)
    runButton_ = [[UIBarButtonItem alloc] initWithTitle:@"Run" style:UIBarButtonItemStyleDone
                                                 target:self action:@selector(_toggleTestsRunning)];
	self.navigationItem.rightBarButtonItem = runButton_;
	[runButton_ release];	
	
  if (!view_) 
    view_ = [[GHUnitIPhoneView alloc] initWithFrame:CGRectMake(0, 0, 320, 344)];
  view_.searchBar.delegate = self;
  NSString *prefix = [self _prefix];
  if (prefix) view_.searchBar.text = prefix;  
  view_.filterControl.selectedSegmentIndex = [self _filterIndex];
  [view_.filterControl addTarget:self action:@selector(_filterChanged:) forControlEvents:UIControlEventValueChanged];
  view_.tableView.delegate = self;
  view_.tableView.dataSource = self.dataSource;
  self.view = view_;
  [view_ release];
	[self reload];
}

- (GHUnitIPhoneTableViewDataSource *)dataSource {
  if (!dataSource_) {
    dataSource_ = [[GHUnitIPhoneTableViewDataSource alloc] initWithIdentifier:@"Tests" suite:[GHTestSuite suiteFromEnv]];  
    [dataSource_ loadDefaults];    
  }
  return dataSource_;
}

- (void)reload {
  [self.dataSource.root setTextFilter:[self _prefix]];	
  [self.dataSource.root setFilter:[self _filterIndex]];
	[view_.tableView reloadData];	
}

#pragma mark Running

- (void)_toggleTestsRunning {
	if (self.dataSource.isRunning) [self cancel];
	else [self runTests];
}

- (void)runTests {
	if (self.dataSource.isRunning) return;
	
  self.view;
	runButton_.title = @"Cancel";
	userDidDrag_ = NO; // Reset drag status
	view_.statusLabel.textColor = [UIColor blackColor];
	view_.statusLabel.text = @"Starting tests...";
	[self.dataSource run:self inParallel:NO options:0];
}

- (void)cancel {
	view_.statusLabel.text = @"Cancelling...";
	[dataSource_ cancel];
}

- (void)_exit {
	exit(0);
}

#pragma mark Properties

- (NSString *)_prefix {
  return [[NSUserDefaults standardUserDefaults] objectForKey:GHUnitPrefixKey];
}

- (void)_setPrefix:(NSString *)prefix {
  [[NSUserDefaults standardUserDefaults] setObject:prefix forKey:GHUnitPrefixKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)_setFilterIndex:(NSInteger)index {
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:index] forKey:GHUnitFilterKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)_filterIndex {
  return [[[NSUserDefaults standardUserDefaults] objectForKey:GHUnitFilterKey] integerValue];
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)_filterChanged:(id)sender {
  [self _setFilterIndex:view_.filterControl.selectedSegmentIndex];
  [self reload];
}

- (void)reloadTest:(id<GHTest>)test {
	[view_.tableView reloadData];
	if (!userDidDrag_ && !dataSource_.isEditing && ![test isDisabled] 
			&& [test status] == GHTestStatusRunning && ![test conformsToProtocol:@protocol(GHTestGroup)]) 
		[self scrollToTest:test];
}

- (void)scrollToTest:(id<GHTest>)test {
	NSIndexPath *path = [dataSource_ indexPathToTest:test];
	if (!path) return;
	[view_.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (void)scrollToBottom {
	NSInteger lastGroupIndex = [dataSource_ numberOfGroups] - 1;
	if (lastGroupIndex < 0) return;
	NSInteger lastTestIndex = [dataSource_ numberOfTestsInGroup:lastGroupIndex] - 1;
	if (lastTestIndex < 0) return;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastTestIndex inSection:lastGroupIndex];
	[view_.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)setStatusText:(NSString *)message {
	view_.statusLabel.text = message;
}

#pragma mark Delegates (UITableView)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	GHTestNode *node = [dataSource_ nodeForIndexPath:indexPath];
	if (dataSource_.isEditing) {
		[node setSelected:![node isSelected]];
		[node notifyChanged];
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
		[view_.tableView reloadData];
	} else {		
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		GHTestNode *sectionNode = [[[dataSource_ root] children] objectAtIndex:indexPath.section];
		GHTestNode *testNode = [[sectionNode children] objectAtIndex:indexPath.row];
		
    GHUnitIPhoneTestViewController *testViewController = [[GHUnitIPhoneTestViewController alloc] init];	
    [testViewController setTest:testNode.test];
    [self.navigationController pushViewController:testViewController animated:YES];
    [testViewController release];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 36.0;
}

#pragma mark Delegates (UIScrollView) 

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	userDidDrag_ = YES;
}

#pragma mark Delegates (GHTestRunner)

- (void)_setRunning:(BOOL)running runner:(GHTestRunner *)runner {
  if (running) {
    view_.filterControl.enabled = NO;
  } else {
    view_.filterControl.enabled = YES;
    GHTestStats stats = [runner.test stats];
    if (stats.failureCount > 0) {
      view_.statusLabel.textColor = [UIColor redColor];
    } else {
      view_.statusLabel.textColor = [UIColor blackColor];
    }

    runButton_.title = @"Run";
  }
}

- (void)testRunner:(GHTestRunner *)runner didLog:(NSString *)message {
	[self setStatusText:message];
}

- (void)testRunner:(GHTestRunner *)runner test:(id<GHTest>)test didLog:(NSString *)message {
	
}

- (void)testRunner:(GHTestRunner *)runner didStartTest:(id<GHTest>)test {
	[self setStatusText:[NSString stringWithFormat:@"Test '%@' started.", [test identifier]]];
	[self reloadTest:test];
}

- (void)testRunner:(GHTestRunner *)runner didUpdateTest:(id<GHTest>)test {
	[self reloadTest:test];
}

- (void)testRunner:(GHTestRunner *)runner didEndTest:(id<GHTest>)test {	
	[self reloadTest:test];
}

- (void)testRunnerDidStart:(GHTestRunner *)runner { 
  [self _setRunning:YES runner:runner];
}

- (void)testRunnerDidCancel:(GHTestRunner *)runner { 
	[self _setRunning:NO runner:runner];
  [self setStatusText:@"Cancelled..."];
}

- (void)testRunnerDidEnd:(GHTestRunner *)runner {
	[self _setRunning:NO runner:runner];
  [self setStatusText:[dataSource_ statusString:@"Tests finished. "]];
  
  // Save defaults after test run
  [self saveDefaults];
}

#pragma mark Delegates (UISearchBar)

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:YES animated:YES];	
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
  return ![dataSource_ isRunning];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	// Workaround for clearing search
	if ([searchBar.text isEqualToString:@""]) {
		[self searchBarSearchButtonClicked:searchBar];
		return;
	}
  NSString *prefix = [self _prefix];
	searchBar.text = (prefix ? prefix : @"");
	[searchBar resignFirstResponder];
	[searchBar setShowsCancelButton:NO animated:YES];	
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	[searchBar setShowsCancelButton:NO animated:YES];	
	
  [self _setPrefix:searchBar.text];
	[self reload];
}

@end
