/* AppController */

#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"
#import "BGRoundedInfoView.h"
#import "BGLastFmSong.h"
#import "BGPointWindow.h"
#import "iTunesWatcher.h"
#import "FileWatcher.h"
#import "BGLastFmAuthenticationManager.h"

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
	
	BGLastFmAuthenticationManager *authManager;
	
	BOOL isLoadingCommonTags;

	BOOL isScrobbling;
	BOOL isPostingNP;
	NSSound *scrobbleSound;
	
	PreferencesController *prefController;
	
	NSArray *tagAutocompleteList;
	NSArray *friendsAutocompleteList;
	
	IBOutlet NSWindow *welcomeWindow;
	
	FileWatcher *xmlWatcher;
}

-(NSString *)pathForCachedDatabase;
-(BOOL)cacheFileExists;
-(void)primeSongPlayCache;

@property (retain) NSArray *tagAutocompleteList;
@property (retain) NSArray *friendsAutocompleteList;

-(IBAction)openAuthPage:(id)sender;

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
-(NSString *)fullXmlPath;
-(IBAction)quit:(id)sender;

#pragma mark Main Scrobbling Methods
-(IBAction)manualScrobble:(id)sender;
-(void)detachScrobbleThreadWithoutConsideration:(BOOL)passThrough;
-(void)postScrobble;
-(void)postNowPlayingNotificationForSong:(BGLastFmSong *)nowPlayingSong;
-(void)detachNowPlayingThread;
-(void)playScrobblingSound;
-(void)xmlFileChanged:(NSNotification *)notification;

#pragma mark Secondary Last.fm Methods
-(BOOL)dataIsAvailableForAPICallUsingArtist:(BOOL)useArtist andAlbum:(BOOL)useAlbum andTrack:(BOOL)useTrack;
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
