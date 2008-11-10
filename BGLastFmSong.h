//
//  BGLastFmSong.h
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 28/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BGLastFmSong : NSObject {
	NSString *title;
	NSString *artist;
	NSString *album;
	NSString *comment;
	NSString *genre;
	NSCalendarDate *lastPlayed;
	int length;
	int extraPlays;
	int playCount;
	NSString *uniqueIdentifier;
	BOOL isExtra;
}

-(id)initWithTitle:(NSString *)aTitle artist:(NSString *)anArtist album:(NSString *)anAlbum;

@property (copy) NSString *title;
@property (copy) NSString *artist;
@property (copy) NSString *album;
@property (copy) NSString *comment;
@property (copy) NSString *genre;
@property (copy) NSCalendarDate *lastPlayed;
@property (assign) int length;
@property (assign) int extraPlays;
@property (assign) int playCount;
@property (copy) NSString *uniqueIdentifier;
@property (assign) BOOL isExtra;

@property (readonly) int unixPlayedDate;

@end
