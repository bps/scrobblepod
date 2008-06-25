//
//  iTunesWatcher.m
//  ScrobblePod
//
//  Created by Ben Gummer on 21/04/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import "iTunesWatcher.h"
#import "iTunes.h"//ScriptingBridgeDefs

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
	[currentSongInfo release];
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
@synthesize currentSongInfo;

- (BOOL)itunesIsRunning {
	NSEnumerator *e = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	NSDictionary *proc;
	while (proc = [e nextObject]) {
		NSString *procName = [proc objectForKey:@"NSApplicationBundleIdentifier"];
		if ([procName caseInsensitiveCompare:ITUNES_BUNDLE_IDENTIFIER] == NSOrderedSame) return YES;
	}
	return NO;
}

-(BOOL)iTunesIsPlaying {
	return iTunesIsPlaying;
}

#pragma mark Notification Handlers

-(void)handleSongChange:(NSTimer*)theTimer {
	NSDictionary *playerInfo = [theTimer userInfo];
	self.currentSongInfo = playerInfo;

	if ([[playerInfo objectForKey:@"Player State"] isEqualToString:@"Playing"]) {
		iTunesIsPlaying = YES;
		NSString *trackName = [playerInfo objectForKey:@"Name"];
		NSString *artistName = [playerInfo objectForKey:@"Artist"];
		NSString *albumName = [playerInfo objectForKey:@"Album"];
		int trackLength = (int)([[playerInfo objectForKey:@"Total Time"] intValue]/1000);
		BGLastFmSong *newSong = [[BGLastFmSong alloc] initWithTitle:trackName artist:artistName album:albumName];
			newSong.length = trackLength;
			self.currentSong = newSong;
		[newSong release];
		[self updateDelegateWithCurrentSong];
	} else {
		iTunesIsPlaying = NO;
	}
}

- (void)iTunesDidChangeState:(id)notification {
	NSDictionary *playerInfo = [notification userInfo];

	if ([[playerInfo objectForKey:@"Player State"] isEqualToString:@"Stopped"] || [[playerInfo objectForKey:@"Player State"] isEqualToString:@"Paused"]) {
		self.currentSong = nil;
		iTunesIsPlaying = NO;
		[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(sendDelegateTrackStoppedNotification) userInfo:nil repeats:NO];
	} else {
		[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(handleSongChange:) userInfo:playerInfo repeats:NO];
	}
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
			manualSong.length = currentTrack.duration;
												  
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
	if (currentSongInfo != nil) {
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