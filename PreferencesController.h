/* PreferencesController */

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController
{
	#pragma mark Individual Pane Views
	IBOutlet NSView *welcomeView;	
	IBOutlet NSView *generalPrefsView;
	IBOutlet NSView *lastfmPrefsView;
	IBOutlet NSView *exclusionsView;
	IBOutlet NSView *historyView;
	
	#pragma mark Toolbar
	NSMutableDictionary *toolbarItems;
	IBOutlet NSToolbar *prefToolbar;
	IBOutlet NSToolbarItem *generalPrefsToolbarItem;
	IBOutlet NSToolbarItem *lastFmToolbarItem;
	
	#pragma mark General Prefs
	IBOutlet NSButton *startAtLogin;
	
	#pragma mark Last.fm Login
	IBOutlet NSBox *currentLoginContainer;
	IBOutlet NSTextField *currentLogin;
	IBOutlet NSProgressIndicator *authSpinner;
	
	#pragma mark History
	IBOutlet NSArrayController *historyController;
	IBOutlet NSTableView *historyTable;
	IBOutlet NSTableColumn *historyIconTableColumn;
}

#pragma mark WindowController Methods
- (NSString *)windowNibName;
- (IBAction)showWindow:(id)sender;

#pragma mark Changing Views
-(IBAction)changeView:(NSToolbarItem *)sender;
-(void)setPreferencesView:(NSView *)inputView;

#pragma mark Pane:General - Actions
-(IBAction)setLoginStart:(id)sender;
-(IBAction)startChooseXML:(id)sender;
-(IBAction)updateAutoDecision:(id)sender;

#pragma mark Pane:LastFmLogin - Actions
-(IBAction)openLastFmWebsite:(id)sender;
-(IBAction)openAuthWebsite:(id)sender;
-(void)loginProcessing;
-(void)loginComplete;
-(void)startAuthSpinner;

#pragma mark Pane:History - Actions
-(void)addHistoryWithSuccess:(BOOL)wasSuccess andDate:(NSDate *)aDate andDescription:(NSString *)aDescription;
@end
