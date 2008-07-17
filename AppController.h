/* AppController */

#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"
#import <Sparkle/SUUpdater.h>
#import "BGRoundedInfoView.h"
#import "UKKQueue.h"
#import "BGLastFmSong.h"
#import "BGPointWindow.h"
#import "iTunesWatcher.h"

@interface AppController : NSObject <TunesWatcherDelegate> {
	NSStatusItem *statusItem;
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSMenuItem *statusMenuItem;
	IBOutlet NSMenuItem *currentSongMenuItem;
	IBOutlet NSView *tagEntryView;
	IBOutlet NSView *recommendationEntryView;
	IBOutlet NSView *containerView;
	IBOutlet BGRoundedInfoView *infoView;
	IBOutlet BGPointWindow *arrowWindow;
	IBOutlet NSTokenField *tagEntryField;
	IBOutlet NSTokenField *commonTagsField;
	IBOutlet NSTokenField *friendsEntryField;
	IBOutlet NSTextField *recommendMessageField;
	IBOutlet NSTextField *tagLabel;
	IBOutlet NSSegmentedControl *tagTypeChooser;
	IBOutlet NSSegmentedControl *recommendTypeChooser;
	
	IBOutlet NSView *commonTagsLoadingView;
	IBOutlet NSProgressIndicator *commonTagsLoadingIndicator;
	
	IBOutlet SUUpdater *softwareUpdater;
	
	BOOL isLoadingCommonTags;

	BOOL isScrobbling;
	BOOL isPostingNP;
	NSSound *scrobbleSound;
	
	PreferencesController *prefController;
	
	NSString *currentSessionKey;
	NSURL *currentPostUrl;
	NSURL *currentNowPlayingUrl;
	
	NSTimer *nowPlayingDelay;
	
	NSArray *tagAutocompleteList;
	NSArray *friendsAutocompleteList;
	
	IBOutlet NSWindow *welcomeWindow;
	IBOutlet NSPanel *authorizationWaitPanel;
}

-(IBAction)showWaitPanel:(id)sender;

@property (retain) NSArray *tagAutocompleteList;
@property (retain) NSArray *friendsAutocompleteList;

-(IBAction)updateTagLabel:(id)sender;
-(void)populateCommonTags;

#pragma mark Required Methods
-(IBAction)showAboutPanel:(id)sender;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)aNotification;
-(void)doFirstRun;

#pragma mark ScrobblePod Status
-(void)setAppropriateRoundedString;
-(void)setIsScrobbling:(BOOL)aBool;
-(void)setIsPostingNP:(BOOL)aBool;

#pragma mark Managing iTunes
- (void)workspaceDidLaunchApplication:(NSNotification *)notification;
- (void)workspaceDidTerminateApplication:(NSNotification *)notification;

#pragma mark XML Notifications
-(void)applyForXmlChangeNotification;
-(void)watcher:(id<UKFileWatcher>)watcher receivedNotification:(NSString *)notification forPath:(NSString *)path;//XML
-(NSString *)fullXmlPath;
-(IBAction)quit:(id)sender;

#pragma mark Main Scrobbling Methods
-(IBAction)manualScrobble:(id)sender;
-(void)detachScrobbleThreadWithoutConsideration:(BOOL)passThrough;
-(void)postScrobble;
-(void)startNowPlayingTimer;
-(void)postNowPlayingNotificationForSong:(BGLastFmSong *)nowPlayingSong;
-(void)detachNowPlayingThread:(NSTimer *)fromTimer;
-(void)playScrobblingSound;

#pragma mark Secondary Last.fm Methods
-(IBAction)goToUserProfilePage:(id)sender;
-(IBAction)loveSong:(id)sender;
-(IBAction)banSong:(id)sender;
-(IBAction)tagSong:(id)sender;
-(IBAction)recommendSong:(id)sender;
-(void)startTasteCommand:(NSString *)tasteCommand;
-(IBAction)performTagSong:(id)sender;

-(void)showArrowWindowForView:(NSView *)theView;
-(void)updateFriendsList;
-(IBAction)performRecommendSong:(id)sender;

#pragma mark Preference Integration
-(IBAction)raiseLoginPanel:(id)sender;//show pref window
@end
