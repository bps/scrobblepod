//
//  iTunesWatcher.h
//  ScrobblePod
//
//  Created by Ben Gummer on 21/04/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BGLastFmSong.h"

@protocol TunesWatcherDelegate

-(void)iTunesWatcherDidDetectStartOfNewSongWithName:(NSString *)aName artist:(NSString *)anArtist artwork:(NSImage *)anArtwork;
-(void)iTunesWatcherDidDetectSongStopped;

@end

@interface iTunesWatcher : NSObject {
	id delegate;
	BGLastFmSong *currentSong;	
	NSString *currentIdentifier;
	int currentSongStarted;
	int durationPlayed;
	BOOL currentSongAlreadyScrobbled;
	
	BOOL iTunesIsPlaying;
}

+(iTunesWatcher *)sharedManager;
+(id)allocWithZone:(NSZone *)zone;
-(id)copyWithZone:(NSZone *)zone;
-(id)retain;
-(unsigned)retainCount;
-(void)release;
-(id)autorelease;

- (id)init;

@property (assign) id delegate;

-(void)manuallyRetrieveCurrentSongInfo;
-(NSImage *)artworkForCurrentTrack;

-(void)sendDelegateTrackStoppedNotification;
-(void)updateDelegateWithNewTrackName:(NSString *)aName andArtist:(NSString *)anArtist andArtwork:(NSImage *)anArtwork;
-(void)updateDelegateWithCurrentSong;

- (void)iTunesDidChangeState:(id)notification;
-(BOOL)itunesIsRunning;
-(BOOL)iTunesIsPlaying;

-(void)newSongStarted:(NSDictionary *)newSongDetails;
-(void)currentSongStopped;
-(void)forwardCurrentSong;

-(BOOL)songIsNew:(NSString *)anIdentifier;
-(BOOL)currentSongPlayedProperly;

-(void)incrementDurationWatch;

-(BGLastFmSong *)currentSong;
-(int)currentUnixDate;

@property (retain) BGLastFmSong *currentSong;
@property (assign) int currentSongStarted;
@property (copy) NSString *currentIdentifier;
@property (assign) int durationPlayed;
@property (assign) BOOL iTunesIsPlaying;
@property (assign) BOOL currentSongAlreadyScrobbled;
@end
