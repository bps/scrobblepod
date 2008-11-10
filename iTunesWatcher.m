//
//  iTunesWatcher.m
//  ScrobblePod
//
//  Created by Ben Gummer on 21/04/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import "iTunesWatcher.h"
#import "iTunes.h"//ScriptingBridgeDefs
#import "Defines.h"

static iTunesWatcher *sharedTunesManager = nil;

#define ITUNES_NOTIFICATION_KEY @"com.apple.iTunes.playerInfo"
#define ITUNES_BUNDLE_IDENTIFIER @"com.apple.iTunes"

@implementation iTunesWatcher

+(iTunesWatcher *)sharedManager {
	@synchronized(self) {
		if (sharedTunesManager == nil) {
			[[self alloc] init]; // assignment not done here
		}
	}
	return sharedTunesManager;
}

+(id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedTunesManager == nil) {
			sharedTunesManager = [super allocWithZone:zone];
			return sharedTunesManager;  // assignment and return on first allocation
		}
	}
	return nil; //on subsequent allocation attempts return nil
}

-(id)copyWithZone:(NSZone *)zone {
	return self;
}

-(id)retain {
	return self;
}

- (unsigned)retainCount {
	return UINT_MAX;  //denotes an object that cannot be released
}
 
-(void)release {
	//do nothing
}
 
-(id)autorelease {
	return self;
}

-(id)init {
	self = [super init];
	if (self != nil) {
		iTunesIsPlaying = NO;
		[self manuallyRetrieveCurrentSongInfo];
		[self updateDelegateWithCurrentSong];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(iTunesDidChangeState:) name:ITUNES_NOTIFICATION_KEY object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:ITUNES_NOTIFICATION_KEY object:nil];
	[currentSong release];
	[super dealloc];
}

-(void)setDelegate:(id)aDelegate {
	delegate = aDelegate;
	[self updateDelegateWithCurrentSong];
}

@synthesize delegate;

#pragma mark iTunes Status

@synthesize currentSong;
@synthesize currentIdentifier;
@synthesize currentSongStarted;
@synthesize durationPlayed;
@synthesize iTunesIsPlaying;
@synthesize currentSongAlreadyScrobbled;

-(BOOL)itunesIsRunning {
	NSEnumerator *e = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	NSDictionary *proc;
	while (proc = [e nextObject]) {
		NSString *procName = [proc objectForKey:@"NSApplicationBundleIdentifier"];
		if ([procName caseInsensitiveCompare:ITUNES_BUNDLE_IDENTIFIER] == NSOrderedSame) return YES;
	}
	return NO;
}

-(BGLastFmSong *)currentSong {
	return (iTunesIsPlaying ? currentSong : nil);
}

#pragma mark Notification Handlers

- (void)iTunesDidChangeState:(id)notification {
	NSDictionary *playerInfo = [notification userInfo];

	if ([[playerInfo objectForKey:@"Player State"] isEqualToString:@"Stopped"] || [[playerInfo objectForKey:@"Player State"] isEqualToString:@"Paused"]) {
		NSLog(@"--SONG STOPPED");
		[self incrementDurationWatch];
		[self currentSongStopped];
	} else if ([[playerInfo objectForKey:@"Player State"] isEqualToString:@"Playing"]) {
		NSLog(@"--SONG PLAYING");
		[self newSongStarted:playerInfo];
	}
}

-(void)newSongStarted:(NSDictionary *)newSongDetails {
	
	self.iTunesIsPlaying = YES;
	NSString *newIdentifier = [[newSongDetails objectForKey:@"PersistentID"] stringValue];
	
	if ( [self songIsNew:newIdentifier] ) {

		NSLog(@"Started new song");

		self.currentIdentifier = newIdentifier;

		// Check if old song was played sufficiently. If so, add it to the queue for scrobbling
		[self incrementDurationWatch];
		
		// Keep track of the song that just started playing
		NSString *trackName  = [newSongDetails objectForKey:@"Name"];

		BOOL useAlbumArtist = [[NSUserDefaults standardUserDefaults] boolForKey:BGPrefShouldUseAlbumArtist];
		
		NSString *artistName = nil;
		if (useAlbumArtist) artistName = [newSongDetails objectForKey:@"Album Artist"];
		if (!artistName) artistName = [newSongDetails objectForKey:@"Artist"];
		if (!artistName) artistName = @"Unknown Artist";
		
		NSString *songGenre = [newSongDetails objectForKey:@"Genre"];
		if (!songGenre) songGenre = @"";

		NSString *albumName  = [newSongDetails objectForKey:@"Album"];
		int trackDuration    = (int)([[newSongDetails objectForKey:@"Total Time"] intValue]/1000);

		BGLastFmSong *newSong = [[BGLastFmSong alloc] initWithTitle:trackName artist:artistName album:albumName];
			newSong.length = trackDuration;
			newSong.genre  = songGenre;
			self.currentSong = newSong;
		[newSong release];

		self.durationPlayed = 0;
		self.currentSongAlreadyScrobbled = NO;
		
	} else {
		NSLog(@"--CONTINUING SAME SONG");
	}
	
	NSLog(@"Artist: %@",currentSong.artist);
	
	self.currentSongStarted = [self currentUnixDate];
	
	[self updateDelegateWithCurrentSong];
}

-(int)currentUnixDate {
	return (int)[[NSDate date] timeIntervalSince1970];
}

-(void)incrementDurationWatch {
	if (self.currentSongStarted>0) {
		int recentDuration = [self currentUnixDate] - self.currentSongStarted;
		self.durationPlayed += recentDuration;
		[self forwardCurrentSong];
	}
}

-(void)currentSongStopped {
	self.iTunesIsPlaying = NO;
	[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(sendDelegateTrackStoppedNotification) userInfo:nil repeats:NO];
}

-(void)forwardCurrentSong {
	if (currentIdentifier && [self currentSongPlayedProperly] && self.currentSongAlreadyScrobbled==NO) {
		//Add currentSong to queue
		NSLog(@"Scrobbling current song: %@",currentSong.title);
		self.currentSongAlreadyScrobbled = YES;
	}
}

-(BOOL)currentSongPlayedProperly {
	return (durationPlayed >= 240 || durationPlayed >= currentSong.length/2);
}

-(BOOL)songIsNew:(NSString *)anIdentifier {
	return (anIdentifier==nil || [anIdentifier isEqualToString:currentIdentifier]==false);
}

#pragma mark Outbound Delegate Communications
	
-(void)updateDelegateWithNewTrackName:(NSString *)aName andArtist:(NSString *)anArtist andArtwork:(NSImage *)anArtwork {
	if (delegate && [delegate conformsToProtocol:@protocol(TunesWatcherDelegate)] && [delegate respondsToSelector:@selector(iTunesWatcherDidDetectStartOfNewSongWithName:artist:artwork:)]) {
		[delegate iTunesWatcherDidDetectStartOfNewSongWithName:aName artist:anArtist artwork:anArtwork];
	}
}

-(void)updateDelegateWithCurrentSong {
	if (delegate && [delegate conformsToProtocol:@protocol(TunesWatcherDelegate)] && [delegate respondsToSelector:@selector(iTunesWatcherDidDetectStartOfNewSongWithName:artist:artwork:)] && currentSong) {
		[self updateDelegateWithNewTrackName:[currentSong title] andArtist:[currentSong artist] andArtwork:[self artworkForCurrentTrack]];
	}
}

-(void)sendDelegateTrackStoppedNotification {
	if (delegate && [delegate conformsToProtocol:@protocol(TunesWatcherDelegate)] && [delegate respondsToSelector:@selector(iTunesWatcherDidDetectSongStopped)]) {
		[delegate iTunesWatcherDidDetectSongStopped];
	}
}

#pragma mark Other Methods / Direct iTunes Interaction

/*
Be careful with this method, as it may crash if the current
song is being played from a shared library.
*/

-(void)manuallyRetrieveCurrentSongInfo {
	if ([self itunesIsRunning]) {
		iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:ITUNES_BUNDLE_IDENTIFIER];
		iTunesTrack *currentTrack = [iTunes currentTrack];
		if (iTunes.playerState == iTunesEPlSPlaying) {
			iTunesIsPlaying = YES;
			BGLastFmSong *manualSong = [[BGLastFmSong alloc] initWithTitle:currentTrack.name artist:currentTrack.artist album:currentTrack.album];
			manualSong.length        = currentTrack.duration;
			manualSong.comment       = currentTrack.comment;
			manualSong.genre         = currentTrack.genre;
			self.currentSong = manualSong;
			[manualSong release];
		} else {
			self.currentSong = nil;
		}
	} else {
		self.currentSong = nil;
	}
}

-(NSImage *)artworkForCurrentTrack {
	if (self.iTunesIsPlaying && currentIdentifier != nil) {
		iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:ITUNES_BUNDLE_IDENTIFIER];
		iTunesTrack *currentTrack = [iTunes currentTrack];
		if (self.iTunesIsPlaying) {
				iTunesIsPlaying = YES;
				NSArray *artworkArray = [currentTrack artworks];
				if ([artworkArray count]>0) return (NSImage *)[[artworkArray objectAtIndex:0] data];
		}
	}
	return [NSImage imageNamed:@"iTunesSmall"];
}

@end