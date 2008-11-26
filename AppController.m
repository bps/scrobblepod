#import "AppController.h"
#import "Defines.h"
#import "HubStrings.h"

#import <Security/Security.h>
#import <QuartzCore/CoreAnimation.h>
#import "CocoaCryptoHashing.h"
#import "GrowlHub.h"

#import "iPodWatcher.h"
#import "BGTrackCollector.h"
#import "BGScrobbleDecisionManager.h"

#import "BGLastFmHandshaker.h"
#import "BGLastFmHandshakeResponse.h"
#import "BGLastFmScrobbler.h"
#import "BGLastFmScrobbleResponse.h"
#import "BGLastFmWebServiceCaller.h"
#import "BGLastFmWebServiceParameterList.h"
#import "BGLastFmWebServiceResponse.h"

#import "BGMultipleSongPlayManager.h"

#import "NSCalendarDate+RelativeDateDescription.h"
#import "SFHFKeychainUtils.h"
#import "StatusItemView.h"

#include <ApplicationServices/ApplicationServices.h>

#import "NSString+UrlEncoding.h"

//#import "BGConnectionCaller.h"

@implementation AppController

#pragma mark Application Starting/Quitting

-(void)showStatusMenu:(id)sender {
	[statusItem popUpStatusItemMenu:statusMenu];
}

-(void)menuWillOpen:(NSMenu *)menu {
	[[BGScrobbleDecisionManager sharedManager] resetRefreshTimer];
	[arrowWindow properClose];
}

-(void)awakeFromNib {

	[self setIsScrobbling:NO];
	[self setIsPostingNP:NO];
	
	isLoadingCommonTags = NO;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
		@"...",BGPrefUsername,
		@"",BGWebServiceSessionKey,
		@"",BGSubmissionSessionKey,
		[NSNumber numberWithBool:YES],BGPrefFirstRunKey,
		[[[NSCalendarDate calendarDate] dateByAddingYears:0 months:0 days:0 hours:0 minutes:-2 seconds:0] descriptionWithCalendarFormat:DATE_FORMAT_STRING],BGPrefLastScrobbled,
		[NSNumber numberWithBool:YES],@"SUEnableAutomaticChecks",
		[NSNumber numberWithBool:YES],BGPrefWantMultiPost,
		[NSNumber numberWithBool:NO],BGPrefShouldPlaySound,
		[NSNumber numberWithBool:NO],BGPrefShouldIgnoreComments,
		@"dontpost",BGPrefIgnoreCommentString,
		[NSNumber numberWithBool:NO],BGPrefShouldIgnoreGenre,
		@"",BGPrefIgnoreGenreString,
		[NSNumber numberWithBool:YES],BGPrefShouldIgnoreShort,
		[NSNumber numberWithInt:30],BGPrefIgnoreShortLength,
		[NSNumber numberWithInt:3],BGPrefPodFreshnessInterval,
		[NSNumber numberWithBool:YES],BGPrefShouldIgnorePodcasts,
		[NSNumber numberWithBool:YES],BGPrefShouldIgnoreVideo,
		[NSNumber numberWithBool:YES],BGPrefWantNowPlaying,
		[NSNumber numberWithBool:YES],BGPrefWantStatusItem,
		[NSNumber numberWithBool:YES],BGPrefUsePodFreshnessInterval,
		[NSNumber numberWithInt:0],BGTracksScrobbledTotal,
		[NSNumber numberWithBool:YES],BGPref_Growl_SongChange,
		[NSNumber numberWithBool:YES],BGPref_Growl_ScrobbleFail,
		[NSNumber numberWithBool:YES],BGPref_Growl_ScrobbleDecisionChanged,
		[NSNumber numberWithBool:NO],BGPrefWantOldIcon,
		[NSNumber numberWithBool:NO],BGPrefShouldDoMultiPlay,
		[NSNumber numberWithBool:NO],BGPrefShouldUseAlbumArtist,
		@"~/Music/iTunes/iTunes Music Library.xml",BGPrefXmlLocation,
nil] ];

	NSLog(@"Last iPod Sync Date: %@",[defaults objectForKey:BGLastSyncDate]);
	NSLog(@"Last Scrobbled: %@",[defaults objectForKey:BGPrefLastScrobbled]);

	statusItem = nil;
	if ([defaults boolForKey:BGPrefWantStatusItem])  {
		statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:23];//NSVariableStatusItemLength
		[statusItem setEnabled:YES];
//		[statusItem setHighlightMode:YES];
//		[statusItem setMenu:statusMenu];
//		[statusItem setImage:nil];
//		[statusItem setToolTip:@"ScrobblePod"];
//		[statusItem setTarget:self];
//		[statusItem sendActionOn:NSLeftMouseDownMask];
//		[statusItem setAction:@selector(showStatusMenu:)];

		StatusItemView *tempView = [[StatusItemView alloc] initWithStatusItem:statusItem];
			[tempView setImage:[NSImage imageNamed:(![defaults boolForKey:BGPrefWantOldIcon] ? @"MenuNote" : @"old_menu_icon")]];
			[tempView setAlternateImage:(![defaults boolForKey:BGPrefWantOldIcon] ? [NSImage imageNamed:@"MenuNote_On"] : nil)];
			[tempView setTarget:self];
			[tempView setAction:@selector(showStatusMenu:)];

			[statusItem setView:tempView];
		[tempView release];
		[statusItem retain];
	}
	
	[currentSongMenuItem setView:containerView];
	[containerView addSubview:infoView];
	
	if (![self cacheFileExists]) {
		[self primeSongPlayCache];
	}
	
	NSString *storedDateString = [defaults valueForKey:BGPrefLastScrobbled];
	if ([NSCalendarDate dateWithString:storedDateString calendarFormat:DATE_FORMAT_STRING]==nil) {
		[defaults setValue:[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:DATE_FORMAT_STRING] forKey:BGPrefLastScrobbled];
	}
	
	NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];
	[defaultNotificationCenter addObserver:self selector:@selector(podWatcherMountedPod:) name:BGNotificationPodMounted object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(xmlFileChanged:) name:XMLChangedNotification object:nil];

	 authManager = [[BGLastFmAuthenticationManager alloc] initWithDelegate:self];

	[[iTunesWatcher sharedManager] setDelegate:self];
	
	[[iPodWatcher alloc] init];
	
	NSNotificationCenter *workspaceNotificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [workspaceNotificationCenter addObserver:self selector:@selector(workspaceDidLaunchApplication:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [workspaceNotificationCenter addObserver:self selector:@selector(workspaceDidTerminateApplication:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	 xmlWatcher = [[FileWatcher alloc] init];
	 [xmlWatcher startWatchingXMLFile];
	 NSLog(@"XML Path: %@",[xmlWatcher fullXmlPath]);
	 
	 apiQueue = [NSMutableArray new];
}

#pragma mark Authorization Manager

-(IBAction)openAuthPage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/api/auth?api_key=%@",API_KEY]]];
}

-(void)newWebServiceSessionKeyAcquired {
	[[GrowlHub sharedManager] postGrowlNotificationWithName:SP_Growl_LoginComplete andTitle:@"Authorization Successful" andDescription:@"ScrobblePod is now authorized to communicate with Last.fm" andImage:nil andIdentifier:SP_Growl_LoginComplete];
}

-(void)newSubmissionSessionKeyAcquired {
	[self detachNowPlayingThread];
	[self detachScrobbleThreadWithoutConsideration:NO];
	[self popApiQueue];
}

-(void)primeSongPlayCache {
	BGTrackCollector *collector = [[BGTrackCollector alloc] init];
		NSArray *allTracks = [collector collectTracksFromXMLFile:self.fullXmlPath withCutoffDate:[[NSCalendarDate date] dateByAddingYears:-5 months:0 days:0 hours:0 minutes:0 seconds:0] includingPodcasts:YES includingVideo:YES ignoringComment:@"" ignoringGenre:nil withMinimumDuration:30];
	[collector release];
	
	NSMutableDictionary *primedCache = [[NSMutableDictionary alloc] initWithCapacity:allTracks.count];
	
	BGLastFmSong *currentSong;
	for (currentSong in allTracks) {
		[primedCache setObject:[NSNumber numberWithInt:currentSong.playCount] forKey:currentSong.uniqueIdentifier];
	}
	
	[primedCache writeToFile:[self pathForCachedDatabase] atomically:YES]; // DISABLE TEMPORARILY SO THAT WE ACTUALLY HAVE SOME EXTRA PLAYS
	
	[primedCache release];
}

-(NSString *)pathForCachedDatabase { //Method from CocoaDevCentral.com
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	NSString *folder = @"~/Library/Application Support/ScrobblePod/";
	folder = [folder stringByExpandingTildeInPath];

	if ([fileManager fileExistsAtPath: folder] == NO) [fileManager createDirectoryAtPath: folder attributes: nil];
	
	NSString *fileName = @"PlayCountDB.xml";
	return [folder stringByAppendingPathComponent: fileName]; 
}

-(BOOL)cacheFileExists {
	return [[NSFileManager defaultManager] fileExistsAtPath:[self pathForCachedDatabase]];
}

-(void)menuDidClose:(NSMenu *)menu {
	[(StatusItemView *)statusItem.view setSelected:NO];
	[infoView resetBlueToOffState];
	[infoView stopScrolling];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	prefController = [[PreferencesController alloc] init];

	NSString *username, *wsKey;
	username = [defaults objectForKey:BGPrefUsername];
	wsKey    = [defaults objectForKey:BGWebServiceSessionKey];

	if ([defaults boolForKey:BGPrefFirstRunKey] || !username || username.length==0 || [username isEqualToString:@"..."] || !wsKey || wsKey.length==0) [self doFirstRun];
	
	[self setAppropriateRoundedString];

	// let the user know if scrobbling is enabled
	[self performSelector:@selector(podWatcherMountedPod:) withObject:nil afterDelay:10.0];

}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	NSLog(@"Quit Decision - NP:%d\nSC:%d",isPostingNP,isScrobbling);
	return (!isPostingNP && !isScrobbling);
}

-(void)doFirstRun {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

		NSString *overrideCalendarDate = [[[NSCalendarDate calendarDate] dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:-60] descriptionWithCalendarFormat:DATE_FORMAT_STRING];
		[defaults setValue:overrideCalendarDate forKey:BGPrefLastScrobbled];

		[defaults setBool:FALSE forKey:BGPrefFirstRunKey];
		
		[NSApp activateIgnoringOtherApps:YES];
		[welcomeWindow center];
		[welcomeWindow orderFront:self];
}

-(IBAction)quit:(id)sender {
	[NSApp terminate:self];
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	if (statusItem) [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];

	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) dealloc {
	[statusItem release];

	[scrobbleSound release];
	[prefController release];
		
	[tagAutocompleteList release];
	[friendsAutocompleteList release];
	
	[xmlWatcher release];
	
	[apiQueue release];
		
	[super dealloc];
}

#pragma mark Delegate Methods

-(void)podWatcherMountedPod:(NSNotification *)notification {
	[[BGScrobbleDecisionManager sharedManager] refreshDecisionAndNotifyIfChanged:YES];
}

-(void)xmlFileChanged:(NSNotification *)notification {
	NSLog(@"OMG! XML change!");
	[self detachScrobbleThreadWithoutConsideration:NO];
}

-(void)workspaceDidLaunchApplication:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"]) {
		[self setAppropriateRoundedString];
    }
}

-(void)workspaceDidTerminateApplication:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"]) {
		[self setAppropriateRoundedString];
    }
}

-(void)iTunesWatcherDidDetectStartOfNewSongWithName:(NSString *)aName artist:(NSString *)anArtist artwork:(NSImage *)anArtwork {
	NSImage *growlImage;
	if (anArtwork) {
		growlImage = anArtwork;
	} else {
		growlImage = [NSImage imageNamed:@"iTunesSmall"];
	}
	
	[[GrowlHub sharedManager] postGrowlNotificationWithName:SP_Growl_TrackChanged andTitle:aName andDescription:anArtist andImage:[NSData dataWithData:[growlImage TIFFRepresentation]] andIdentifier:@"SP_Track"];

	NSString *songTitleString = [NSString stringWithFormat:@"%@: %@ ",anArtist,aName];
	[infoView setStringValue:songTitleString isActive:YES];

	[self detachNowPlayingThread];
	
	if ([arrowWindow isVisible]) [self updateTagLabel:self];
}

-(void)iTunesWatcherDidDetectSongStopped {
	[self setAppropriateRoundedString];
	if ([arrowWindow isVisible]) [arrowWindow close];
}

-(NSString *)fullXmlPath {
	return [[[NSUserDefaults standardUserDefaults] stringForKey:BGPrefXmlLocation] stringByExpandingTildeInPath];
}

-(IBAction)updateTagLabel:(id)sender {
	NSString *properString;
	BGLastFmSong *currentSong = [[iTunesWatcher sharedManager] currentSong];
	if (currentSong) {
		if (!isLoadingCommonTags) {
			[arrowWindow setShouldClose:NO];
			int selectedTag = [tagTypeChooser selectedSegment];
			if (selectedTag==0) {
				properString = currentSong.title;
			} else if (selectedTag==1) {
				properString = currentSong.artist;
			} else if (selectedTag==2) {
				properString = currentSong.album;
			}
			tagLabel.stringValue = [NSString stringWithFormat:@"Tags for: \"%@\"",properString];
			
			[NSThread detachNewThreadSelector:@selector(populateCommonTags) toTarget:self withObject:nil];
			[arrowWindow setShouldClose:YES];
		}
	} else {
		[arrowWindow close];
	}
}

-(NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int *)selectedIndex {
	NSArray *arrayToMatchAgainst;
	arrayToMatchAgainst = (tokenField==tagEntryField ? tagAutocompleteList : friendsAutocompleteList);
	NSMutableArray *matchingTags = [NSMutableArray array];
	NSString *substringLower = [substring lowercaseString];
	NSString *currentTag;
	for (currentTag in arrayToMatchAgainst) {
		if ([currentTag.lowercaseString rangeOfString:substringLower].location == 0) [matchingTags addObject:currentTag];
	}

	return matchingTags;
}

@synthesize tagAutocompleteList;
@synthesize friendsAutocompleteList;

-(void)populateCommonTags {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	isLoadingCommonTags = YES;
	[commonTagsField setObjectValue:[NSArray array]];
	[commonTagsLoadingView setHidden:NO];
	[commonTagsLoadingIndicator startAnimation:self];

	NSArray *tagList = [self popularTagsForCurrentSong];
	if (tagList.count > 0) {
		self.tagAutocompleteList = tagList;
	} else {
		self.tagAutocompleteList = [NSArray arrayWithObjects:@"Tags", @"Could", @"Not", @"Be", @"Loaded",nil];
	}

	[commonTagsField setObjectValue:self.tagAutocompleteList];

	[commonTagsLoadingIndicator stopAnimation:self];
	[commonTagsLoadingView setHidden:YES];
	isLoadingCommonTags = NO;
	[pool release];
}

-(NSArray *)popularTagsForCurrentSong {
	NSMutableArray *tagList = [NSMutableArray array];
	int tagType = tagTypeChooser.selectedSegment;
	BOOL needAlbum = BGOperationType_Album == tagType;
	BOOL needTrack = BGOperationType_Song  == tagType;
	if ([self dataIsAvailableForAPICallUsingArtist:NO andAlbum:needAlbum andTrack:needTrack]) {
		NSString *sessionKey = authManager.webServiceSessionKey;

		NSString *apiMethod;
		switch (tagType) {
			case BGOperationType_Song:
				apiMethod = @"track.getTopTags";
				break;
			case BGOperationType_Artist:
				apiMethod = @"artist.getTopTags";
				break;
			case BGOperationType_Album:
				apiMethod = nil;//@"album.addTags";
				break;
			default:
				apiMethod = nil;
				break;
		}
		
		if (apiMethod) {
			BGLastFmWebServiceParameterList *params = [[BGLastFmWebServiceParameterList alloc] initWithMethod:apiMethod andSessionKey:sessionKey];

			BGLastFmSong *currentSong = [iTunesWatcher sharedManager].currentSong;		
			[params setParameter:currentSong.artist forKey:@"artist"];
			if (needTrack) [params setParameter:currentSong.title  forKey:@"track"];
			if (needAlbum) [params setParameter:currentSong.album  forKey:@"album"];

			BGLastFmWebServiceCaller *sc = [[BGLastFmWebServiceCaller alloc] init];
				BGLastFmWebServiceResponse *resp = [sc callWithParameters:params usingPostMethod:YES usingAuthentication:NO];
				
				NSXMLDocument *tagsXML = resp.responseDocument;
				NSArray *tagNodes = [tagsXML nodesForXPath:@"/lfm/toptags/tag/name" error:nil];
				NSXMLNode *currentTagNode;
				for (currentTagNode in tagNodes) {
					[tagList addObject:[currentTagNode stringValue]];
				}
			[sc release];

			[params release];
		}
	}
	return tagList;
}

#pragma mark Scrobbling Status Methods

-(void)setAppropriateRoundedString {
	iTunesWatcher *tunesWatcher = [iTunesWatcher sharedManager];
	if ([tunesWatcher itunesIsRunning]) {
		if (![tunesWatcher iTunesIsPlaying]) {
			[infoView setStringValue:@"iTunes is not playing" isActive:NO];
		} else {
			[infoView setActive:YES];
		}
	} else {
		[infoView setStringValue:@"iTunes is not running" isActive:NO];
	}
}

-(void)setIsScrobblingWithNumber:(NSNumber *)aNumber {
	[self setIsScrobbling: [aNumber boolValue] ];
}

-(void)setIsScrobbling:(BOOL)aBool {
	isScrobbling = aBool;
}

-(void)setIsPostingNP:(BOOL)aBool {
	isPostingNP = aBool;
}

#pragma mark Last.fm API Interaction

-(void)queueApiCall:(BGLastFmWebServiceParameterList *)theCall popQueueToo:(BOOL)shouldPopQueue {
	[apiQueue addObject:theCall];
	if (shouldPopQueue) [self popApiQueue];
}

-(void)popApiQueue {
	if (apiQueue.count > 0) {
		BGLastFmWebServiceParameterList *params = [apiQueue objectAtIndex:0];
		//NSLog(@"Going to pop queue with params:%@",params);
		BGLastFmWebServiceCaller *sc = [[BGLastFmWebServiceCaller alloc] init];
			BGLastFmWebServiceResponse *resp = [sc callWithParameters:params usingPostMethod:YES usingAuthentication:YES];
			NSLog(@"Got response: '%@'",[resp className]);
			if (resp.wasOK) {
				[apiQueue removeObject:params];
				if (apiQueue.count > 0) [self performSelector:@selector(popApiQueue) withObject:nil afterDelay:1.0];
			} else if (resp.failedDueToInvalidKey) {
				[self openAuthPage:self];
			}
		[sc release];
	}
}

-(IBAction)loveSong:(id)sender {		
	[self startTasteCommand:ServiceWorker_LoveCommand];
}

-(IBAction)banSong:(id)sender {
	[self startTasteCommand:ServiceWorker_BanCommand];
}

-(BOOL)dataIsAvailableForAPICallUsingArtist:(BOOL)useArtist andAlbum:(BOOL)useAlbum andTrack:(BOOL)useTrack {
	iTunesWatcher *tunesWatcher = [iTunesWatcher sharedManager];

	NSString *username = authManager.username;
	NSString *sessionKey = authManager.webServiceSessionKey;
	BOOL isPlaying = tunesWatcher.iTunesIsPlaying;

	if (isPlaying && username && username.length > 0 && sessionKey && sessionKey.length > 0) {
		BGLastFmSong *currentSong = tunesWatcher.currentSong;
		
		if (currentSong) {
			NSString *songTitle = currentSong.title;
			NSString *songArtist = currentSong.artist;
			NSString *songAlbum = currentSong.album;
			
			return ( (!useArtist || (useArtist && songArtist)) && (!useAlbum || (useAlbum && songAlbum)) && (!useTrack || (useTrack && songTitle)) );
		} else return NO;
	} else return NO;
}

-(void)startTasteCommand:(NSString *)tasteCommand { //tasteCommand is either @"track.love" or @"track.ban"
	if ([self dataIsAvailableForAPICallUsingArtist:YES andAlbum:NO andTrack:YES]) {
		NSString *sessionKey = authManager.webServiceSessionKey;
		BGLastFmSong *currentSong = [iTunesWatcher sharedManager].currentSong;

		BGLastFmWebServiceParameterList *params = [[BGLastFmWebServiceParameterList alloc] initWithMethod:tasteCommand andSessionKey:sessionKey];
		[params setParameter:currentSong.title  forKey:@"track"];
		[params setParameter:currentSong.artist forKey:@"artist"];

		[self queueApiCall:params popQueueToo:YES];

		[params release];
	}
}

-(IBAction)tagSong:(id)sender {
	[tagEntryField setObjectValue:[NSArray array]];
	[self showArrowWindowForView:tagEntryView];
	[self updateTagLabel:self];
	[arrowWindow makeFirstResponder:tagEntryField];
}

-(IBAction)performTagSong:(id)sender {
	[arrowWindow setShouldClose:NO];
	
	int tagType = [tagTypeChooser selectedSegment];
	BOOL needAlbum = BGOperationType_Album == tagType;
	BOOL needTrack = BGOperationType_Song  == tagType;
	
	if ([self dataIsAvailableForAPICallUsingArtist:YES andAlbum:needAlbum andTrack:needTrack]) {
	
		NSString *apiMethod;
		switch (tagType) {
			case BGOperationType_Song:
				apiMethod = @"track.addTags";
				break;
			case BGOperationType_Artist:
				apiMethod = @"artist.addTags";
				break;
			case BGOperationType_Album:
				apiMethod = @"album.addTags";
				break;
			default:
				apiMethod = nil;
				break;
		}
		
		if (apiMethod != nil) {
			NSString *sessionKey = authManager.webServiceSessionKey;
			BGLastFmSong *currentSong = [iTunesWatcher sharedManager].currentSong;

			BGLastFmWebServiceParameterList *params = [[BGLastFmWebServiceParameterList alloc] initWithMethod:apiMethod andSessionKey:sessionKey];
			[params setParameter:currentSong.artist forKey:@"artist"];
			if (needTrack) [params setParameter:currentSong.title  forKey:@"track"];
			if (needAlbum) [params setParameter:currentSong.album  forKey:@"album"];
			
			NSArray *theTags = [tagEntryField objectValue];
			if (theTags.count > 0) {
				[params setParameter:[theTags componentsJoinedByString:@","] forKey:@"tags"];
			}

			[self queueApiCall:params popQueueToo:YES];

			[params release];
		}
	}
	
	[arrowWindow setShouldClose:YES];
}

-(IBAction)recommendSong:(id)sender {
	[self showArrowWindowForView:recommendationEntryView];
//	[self updateTagLabel:self];
	[self updateFriendsList];
	[arrowWindow makeFirstResponder:tagEntryField];
}

-(IBAction)performRecommendSong:(id)sender {
	[arrowWindow setShouldClose:NO];
	
	int tagType = recommendTypeChooser.selectedSegment;
	BOOL needAlbum = BGOperationType_Album == tagType;
	BOOL needTrack = BGOperationType_Song  == tagType;
	
	if ([self dataIsAvailableForAPICallUsingArtist:YES andAlbum:needAlbum andTrack:needTrack]) {
	
		NSString *apiMethod;
		switch (tagType) {
			case BGOperationType_Song:
				apiMethod = @"track.share";
				break;
			case BGOperationType_Artist:
				apiMethod = @"artist.share";
				break;
			case BGOperationType_Album:
				apiMethod = nil;//@"album.share"; //album.share not yet supported by last.fm
				break;
			default:
				apiMethod = nil;
				break;
		}
		
		if (apiMethod != nil) {
			NSString *sessionKey = authManager.webServiceSessionKey;
			BGLastFmSong *currentSong = [iTunesWatcher sharedManager].currentSong;

			BGLastFmWebServiceParameterList *params = [[BGLastFmWebServiceParameterList alloc] initWithMethod:apiMethod andSessionKey:sessionKey];
			[params setParameter:currentSong.artist forKey:@"artist"];
			if (needTrack) [params setParameter:currentSong.title  forKey:@"track"];
			if (needAlbum) [params setParameter:currentSong.album  forKey:@"album"];
			
			NSArray *theFriends = [friendsEntryField objectValue];
			if (theFriends.count > 10) theFriends = [theFriends objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 9)]];
			if (theFriends.count > 0) {
				[params setParameter:[theFriends componentsJoinedByString:@","] forKey:@"recipient"];
			}
			
			NSString *theMessage = recommendMessageField.stringValue;
			if (theMessage.length > 0) [params setParameter:theMessage forKey:@"message"];

			[self queueApiCall:params popQueueToo:YES];

			[params release];
		}
	}

	[arrowWindow setShouldClose:YES];
}

-(void)updateFriendsList {
	self.friendsAutocompleteList = [self friendsForUser];
}

-(NSArray *)friendsForUser {
	NSMutableArray *friendsList = [NSMutableArray array];
	if ([self dataIsAvailableForAPICallUsingArtist:NO andAlbum:NO andTrack:NO]) {
		NSString *username = authManager.username;
		NSString *sessionKey = authManager.webServiceSessionKey;

		BGLastFmWebServiceParameterList *params = [[BGLastFmWebServiceParameterList alloc] initWithMethod:@"user.getFriends" andSessionKey:sessionKey];
		[params setParameter:username forKey:@"user"];

		BGLastFmWebServiceCaller *sc = [[BGLastFmWebServiceCaller alloc] init];
			BGLastFmWebServiceResponse *resp = [sc callWithParameters:params usingPostMethod:YES usingAuthentication:NO];
			
			NSXMLDocument *friendsXML = resp.responseDocument;
			NSArray *friendNodes = [friendsXML nodesForXPath:@"/lfm/friends/user/name" error:nil];
			NSXMLNode *currentNameNode;
			for (currentNameNode in friendNodes) {
				[friendsList addObject:[currentNameNode stringValue]];
			}
			
		[sc release];

		[params release];
	}
	return friendsList;
}

-(void)showArrowWindowForView:(NSView *)theView {
	float xVal, yVal;
	NSPoint statusItemLocation = [[[statusItem view] window] frame].origin;
	xVal = statusItemLocation.x;
	yVal = statusItemLocation.y;
	[NSApp activateIgnoringOtherApps:YES];
	[statusMenu cancelTracking];
	[arrowWindow setFrame:theView.frame display:YES];
	[arrowWindow setContentView:theView];
	[arrowWindow positionAtMenuBarForHorizontalValue:xVal-(theView.frame.size.width/2)+(statusItem.view.frame.size.width/2) andVerticalValue:yVal-theView.frame.size.height+2];
	[arrowWindow setInitialFirstResponder:tagEntryField];
	[self performSelector:@selector(showArrowWindow) withObject:nil afterDelay:0.15];
}

-(void)showArrowWindow {
	arrowWindow.alphaValue = 0.0;
	[arrowWindow makeKeyAndOrderFront:self];
	[arrowWindow makeMainWindow];
	[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.1];
		[arrowWindow.animator setAlphaValue:1.0f];
	[NSAnimationContext endGrouping];
}

#pragma mark Preferences

-(IBAction)showAboutPanel:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:self];
}

-(IBAction)raiseLoginPanel:(id)sender {
	if (!prefController) {
		prefController = [[PreferencesController alloc] init];
	}
	[prefController showWindow:self];
}

#pragma mark Main Scrobbling Methods

-(void)detachScrobbleThreadWithoutConsideration:(BOOL)passThrough {
	if (!isScrobbling) {
		BOOL shouldContinue = passThrough;
		if (!passThrough) shouldContinue = [[BGScrobbleDecisionManager sharedManager] shouldScrobble];
		if (shouldContinue) [NSThread detachNewThreadSelector:@selector(postScrobble) toTarget:self withObject:nil];
	}
}

-(IBAction)goToUserProfilePage:(id)sender {
	[statusMenu cancelTracking];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/user/%@",[[NSUserDefaults standardUserDefaults] stringForKey:BGPrefUsername] ] ]];
}

-(IBAction)manualScrobble:(id)sender {
	NSCalendarDate *lastScrobbled = [NSCalendarDate dateWithString:[[NSUserDefaults standardUserDefaults] valueForKey:BGPrefLastScrobbled] calendarFormat:DATE_FORMAT_STRING];
	[NSApp activateIgnoringOtherApps:YES];
	int shouldForceScrobble = NSRunAlertPanel(@"Scrobble songs before syncing your iPod?", @"Songs played on your iPod after %@ will not be scrobbled when the iPod is next connected." , @"Scrobble Anyway", @"Cancel", nil,[lastScrobbled relativeDateDescription], nil);
	if (shouldForceScrobble == NSAlertDefaultReturn) [self detachScrobbleThreadWithoutConsideration:YES];
}

-(void)postScrobble {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[self performSelectorOnMainThread:@selector(setIsScrobblingWithNumber:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];// setIsScrobbling:YES];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString *lastScrobbleDateString = 	[defaults valueForKey:BGPrefLastScrobbled];
	NSLog(@"-- Last Scrobbled Date: %@",lastScrobbleDateString);
	NSCalendarDate *applescriptInputDateString = [NSCalendarDate dateWithString:lastScrobbleDateString calendarFormat:DATE_FORMAT_STRING];// descriptionWithCalendarFormat:DATE_FORMAT_STRING];

	NSLog(@"Collecting previously played tracks");	
	BGTrackCollector *trackCollector = [[BGTrackCollector alloc] init];
		NSArray *recentTracksSimple = [trackCollector collectTracksFromXMLFile:self.fullXmlPath withCutoffDate:applescriptInputDateString includingPodcasts:(![defaults boolForKey:BGPrefShouldIgnorePodcasts]) includingVideo:(![defaults boolForKey:BGPrefShouldIgnoreVideo]) ignoringComment:([defaults boolForKey:BGPrefShouldIgnoreComments] ? [defaults stringForKey:BGPrefIgnoreCommentString] : nil) ignoringGenre:([defaults boolForKey:BGPrefShouldIgnoreGenre] ? [defaults stringForKey:BGPrefIgnoreGenreString] : nil) withMinimumDuration:[defaults integerForKey:BGPrefIgnoreShortLength]];//![defaults boolForKey:BGPrefShouldIgnorePodcasts]
	[trackCollector release];
	
	NSLog(@"Assigning song list to variable");
	NSArray *allRecentTracks;
	// Calculate extra plays, and insert them into recent songs array
	if ([defaults boolForKey:BGPrefShouldDoMultiPlay]) {
		BGMultipleSongPlayManager *multiPlayManager = [[BGMultipleSongPlayManager alloc] init];
		allRecentTracks = [multiPlayManager completeSongListForRecentTracks:recentTracksSimple sinceDate:applescriptInputDateString];
		[multiPlayManager release];
	} else {
		allRecentTracks = recentTracksSimple;
	}
	
	[recentTracksSimple autorelease];
	
	NSLog(@"Using multi-play: %@",([defaults boolForKey:BGPrefShouldDoMultiPlay] ? @"Yes" : @"No"));
	NSLog(@"Got all recent tracks:\n%@",allRecentTracks);
	
	int recentTracksCount = allRecentTracks.count;
	
	if (recentTracksCount > 0) {
	
		if (recentTracksCount > 1) 	[[GrowlHub sharedManager] postGrowlNotificationWithName:SP_Growl_StartedScrobbling andTitle:SP_Growl_StartedScrobbling andDescription:[NSString stringWithFormat:@"Scrobbling %d track%@ to Last.fm", recentTracksCount, ( recentTracksCount == 1 ? @"" : @"s" )] andImage:nil andIdentifier:SP_Growl_StartedScrobbling];

		int scrobbleAttempts = 0;
		while (scrobbleAttempts < 2) {
		
			NSString *theSessionKey  = authManager.submissionSessionKey;
			NSString *thePostAddress = authManager.scrobbleSubmissionURL;
			
			if (theSessionKey && thePostAddress && theSessionKey.length>0 && thePostAddress.length>0) {
								
				BGLastFmScrobbler *theScrobbler = [[BGLastFmScrobbler alloc] init];
				BGLastFmScrobbleResponse *scrobbleResponse = [theScrobbler performScrobbleWithSongs:allRecentTracks andSessionKey:theSessionKey toURL:[NSURL URLWithString:thePostAddress]];

				if (!scrobbleResponse.wasSuccessful) {
					if (scrobbleResponse.responseType==SCROBBLE_RESPONSE_BADAUTH) {
						// Need to rehandshake
						[authManager fetchNewSubmissionSessionKeyUsingWebServiceSessionKey];
						scrobbleAttempts = 2;
					} else if (scrobbleResponse.responseType==SCROBBLE_RESPONSE_FAILED) {
						[[GrowlHub sharedManager] postGrowlNotificationWithName:SP_Growl_FailedScrobbling andTitle:@"Tracks could not be scrobbled" andDescription:[NSString stringWithFormat:@"Server said \"%@\"",[scrobbleResponse failureReason]] andImage:nil andIdentifier:SP_Growl_StartedScrobbling];
						[prefController addHistoryWithSuccess:NO andDate:[NSDate date] andDescription:[NSString stringWithFormat:@"Scrobble failed: ",[scrobbleResponse failureReason]]];
					} else if (scrobbleResponse.responseType==SCROBBLE_RESPONSE_UNKNOWN && scrobbleAttempts==0) {
						// Because the scrobble post URL is stored in the user defaults (and handshake is not updated on launch), there is a
						// chance that the stored URL (IP address) may no longer point to Last.fm. In this case, we re-handshake.
						[authManager fetchNewSubmissionSessionKeyUsingWebServiceSessionKey];
						scrobbleAttempts = 2;
					} else {
						if (scrobbleAttempts==1) {
							[[GrowlHub sharedManager] postGrowlNotificationWithName:SP_Growl_FailedScrobbling andTitle:@"Tracks could not be scrobbled" andDescription:@"Scrobbling probably timed out" andImage:nil andIdentifier:SP_Growl_StartedScrobbling];
							[prefController addHistoryWithSuccess:NO andDate:[NSDate date] andDescription:@"Scrobble failed likely due to timeout"];
						}
					}
				} else {
					[prefController addHistoryWithSuccess:YES andDate:[NSDate date] andDescription:[NSString stringWithFormat:@"Scrobbled %d song%@",recentTracksCount,(recentTracksCount==1?@"":@"s")]];
					NSCalendarDate *returnedDate = [scrobbleResponse lastScrobbleDate];
					NSLog(@"-- After Scrobbling Date Returned: %@",returnedDate);
					if (returnedDate!=nil) {
						NSString *updatedDateString = [returnedDate descriptionWithCalendarFormat:DATE_FORMAT_STRING];
						[defaults setValue:updatedDateString forKey:BGPrefLastScrobbled];
						NSLog(@"-- Setting Last Scrobbling Date To: %@",updatedDateString);
						[defaults synchronize];
					}
					[defaults setObject: [NSNumber numberWithInt: [[NSUserDefaults standardUserDefaults] integerForKey:BGTracksScrobbledTotal]+recentTracksCount ] forKey:BGTracksScrobbledTotal];
					if (recentTracksCount>1) [[GrowlHub sharedManager] postGrowlNotificationWithName:SP_Growl_FinishedScrobbling andTitle:@"Finished Scrobbling" andDescription:[NSString stringWithFormat:@"%d track%@ successfully scrobbled to Last.fm",recentTracksCount,( recentTracksCount == 1 ? @"" : @"s" )] andImage:nil andIdentifier:SP_Growl_StartedScrobbling];

					if ([defaults boolForKey:BGPrefShouldPlaySound]) [self playScrobblingSound];
					scrobbleAttempts = 2;
				}
				
				[scrobbleResponse release];
				[theScrobbler release];

			} else {
				NSLog(@"Scrobbling didn't work because not all values set:\n  Key:'%@'\n  URL:%@",theSessionKey,thePostAddress);
				[prefController addHistoryWithSuccess:NO andDate:[NSDate date] andDescription:@"Handshake Failed"];
			}//end if handshake worked
			scrobbleAttempts++;
		} //end while around handshake&scrobble processes
		
	}
	
	[self performSelectorOnMainThread:@selector(setIsScrobblingWithNumber:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];// setIsScrobbling:NO];
	[self performSelectorOnMainThread:@selector(detachNowPlayingThread) withObject:nil waitUntilDone:YES];
	
	[pool release];
}

-(void)playScrobblingSound {
	if (!scrobbleSound) {
		NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"bubbles" ofType:@"aif"];
		scrobbleSound = [[NSSound alloc] initWithContentsOfFile:soundPath byReference:NO];
	}
	[scrobbleSound play];
}

-(void)detachNowPlayingThread {
	NSLog(@"Detaching now playing thread");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (!isPostingNP && [defaults boolForKey:BGPrefWantNowPlaying]) {
		NSLog(@"Getting current song details");
		iTunesWatcher *tunesWatcher = [iTunesWatcher sharedManager];
		[tunesWatcher manuallyRetrieveCurrentSongInfo];
		BGLastFmSong *currentPlayingSong = tunesWatcher.currentSong;
		NSString *ignoreString = [[NSUserDefaults standardUserDefaults] stringForKey:BGPrefIgnoreCommentString];
		if (currentPlayingSong.comment && ignoreString!=nil && [ignoreString length]>0 && [currentPlayingSong.comment rangeOfString:ignoreString].length==0) {
			NSLog(@"Posting song details to Last.fm Now Playing service");
			[NSThread detachNewThreadSelector:@selector(postNowPlayingNotificationForSong:) toTarget:self withObject:currentPlayingSong];
		} else {
			NSLog(@"Did not post Now Playing notification, as song was excluded");
		}
	}
}

-(void)postNowPlayingNotificationForSong:(BGLastFmSong *)nowPlayingSong {
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];

	//////////////////////////////////////////////////////////
	
	[self setIsPostingNP:YES];
	NSLog(@"Performing now playing code");
	if (nowPlayingSong) {
		int notifyAttempts = 0;
		while (notifyAttempts < 2) {
			NSString *theSessionKey  = authManager.submissionSessionKey;
			NSString *thePostAddress = authManager.nowPlayingSubmissionURL;
			if (theSessionKey && thePostAddress && theSessionKey.length>0 && thePostAddress.length>0) {
				NSString *npPostString = [NSString stringWithFormat:@"s=%@&a=%@&t=%@&b=%@&l=%d&n=&m=",theSessionKey,nowPlayingSong.artist.urlEncodedString,nowPlayingSong.title.urlEncodedString,nowPlayingSong.album.urlEncodedString,nowPlayingSong.length];
				NSData *postData = [npPostString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
				NSString *postLength = [NSString stringWithFormat:@"%d", postData.length];
		
				NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
				[request setURL:[NSURL URLWithString:thePostAddress]];
				[request setHTTPMethod:@"POST"];
				[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
				[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
				[request setTimeoutInterval:20.0];// timeout scrobble posting after 20 seconds
				[request setHTTPBody:postData];

				NSError *postingError;
				NSData *npResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&postingError];
				
				[request release];
						
				if (npResponseData!=nil && postingError==nil) {
					NSString *npResponseString = [[NSString alloc] initWithData:npResponseData encoding:NSUTF8StringEncoding];
					
					if ([npResponseString rangeOfString:@"BADSESSION"].length>0) {
						[authManager fetchNewSubmissionSessionKeyUsingWebServiceSessionKey];
						notifyAttempts = 2;
					} else if ([npResponseString rangeOfString:@"OK"].length>0) {
						notifyAttempts = 2;
					} else {
					}
					[npResponseString release];
				}
								
			} else {
				NSLog(@"Now playing didn't work because not all values set:\n  Key:'%@'\n  URL:%@",theSessionKey,thePostAddress);
			}//end if handshake worked
	
			notifyAttempts++;
		} //end while around handshake&notifying processes		
	}
	
	//////////////////////////////////////////////////////////
	
	[self setIsPostingNP:NO];
	[pool release];
}

@end
