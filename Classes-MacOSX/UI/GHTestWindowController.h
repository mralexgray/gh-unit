
#import "GHTestViewController.h"

@interface GHTestWindowController : NSWindowController

@property (strong, nonatomic) IBOutlet GHTestViewController *viewController;

- (IBAction)runTests:(id)sender;
- (IBAction)copy:(id)sender;

@end

