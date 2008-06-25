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
	NSDictionary *currentSongInfo;
	
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

@property (retain) BGLastFmSong *currentSong;
@property (retain) NSDictionary *currentSongInfo;
@end
