
#import "GHTestViewModel.h"
#import "GHTestGroup.h"
#import "GHTestOutlineViewModel.h" 

@interface GHTestViewController : NSViewController <GHTestRunnerDelegate, GHTestOutlineViewModelDelegate, NSSplitViewDelegate>

@property (assign) IBOutlet        NSSplitView * splitView;
@property (assign) IBOutlet             NSView * statusView,
                                               * detailsView;
@property (assign) IBOutlet      NSOutlineView * outlineView;
@property (assign) IBOutlet         NSTextView * textView;
@property (assign) IBOutlet NSSegmentedControl * textSegmentedControl,
                                               * segmentedControl;
@property (assign) IBOutlet      NSSearchField * searchField;
@property (assign) IBOutlet           NSButton * detailsToggleButton;

@property  (readonly)   GHTestOutlineViewModel * dataSource;
@property  (readonly) 	  			    id<GHTest>   selectedTest;
@property  (readonly)                     BOOL   showingDetails;
@property (nonatomic) 			  		      double   statusProgress;
@property (nonatomic) 				       NSInteger   exceptionLineNumber;
@property (nonatomic)                     BOOL   wrapInTextView,
                                                 reraiseExceptions,
                                                 runInParallel,
                                                 running;
@property (nonatomic) 			       GHTestSuite * suite;
@property (nonatomic) 				        NSString * status,
                                               * runLabel,
                                               * exceptionFilename;

-    	  (void) selectRow:             (NSInteger)row;
-   (IBAction) copy:                  (id)x;
-   (IBAction) runTests:              (id)x;
-   (IBAction) toggleDetails:         (id)x;
-   (IBAction) updateTextSegment:     (id)x;
-   (IBAction) updateMode:            (id)x;
-   (IBAction) updateSearchFilter:		(id)x;
-   (IBAction) openExceptionFilename:	(id)x;
- 	(IBAction) rerunTest:             (id)x;
-       (void) loadTestSuite;
- 		  (void) selectFirstFailure;
-  	    (void) runTests;
-		    (void) reload;
- 	    (void) loadDefaults;
- 	    (void) saveDefaults;

@end
