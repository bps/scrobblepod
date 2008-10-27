//
//  BGLastFmSong.m
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 28/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import "BGLastFmSong.h"


@implementation BGLastFmSong

-(id)initWithTitle:(NSString *)aTitle artist:(NSString *)anArtist album:(NSString *)anAlbum {
	self = [super init];
	if (self != nil) {
		self.title = aTitle;
		self.artist = anArtist;
		self.album = anAlbum;
		self.isExtra = NO;
	}
	return self;
}

- (void) dealloc {
	[title release];
	[artist release];
	[album release];
	[comment release];
	[lastPlayed release];
	[uniqueIdentifier release];
	[super dealloc];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"'%@'%@ at %@", self.title, (self.isExtra ? @" (EXTRA)" : @""),self.lastPlayed];
}

- (id)copyWithZone:(NSZone *)zone {
    BGLastFmSong *copy = [[[self class] allocWithZone: zone] initWithTitle:self.title
																	artist:self.artist
																	 album:self.album];
	copy.lastPlayed = self.lastPlayed;
	copy.uniqueIdentifier = self.uniqueIdentifier;
	copy.length = self.length;
	copy.extraPlays = self.extraPlays;
	copy.playCount = self.playCount;
	copy.isExtra = self.isExtra;
 
    return copy;
}

-(int)unixPlayedDate { // this probably isnt stringly the unix method, but whatever ;)
	return [self.lastPlayed timeIntervalSinceReferenceDate];
}

@synthesize title;
@synthesize artist;
@synthesize album;
@synthesize comment;
@synthesize lastPlayed;
@synthesize length;
@synthesize extraPlays;
@synthesize playCount;
@synthesize uniqueIdentifier;
@synthesize isExtra;
@synthesize unixPlayedDate;

@end
