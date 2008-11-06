//
//  BGTrackCollector.m
//  ScrobblePod
//
//  Created by Ben on 13/01/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGTrackCollector.h"
#import "BGLastFmSong.h"
#import "Defines.h"
#import "NSDictionary+ExclusionTest.h"

@implementation BGTrackCollector
-(NSMutableArray *)collectTracksFromXMLFile:(NSString *)xmlPath withCutoffDate:(NSDate *)cutoffDate includingPodcasts:(BOOL)includePodcasts includingVideo:(BOOL)includeVideo ignoringComment:(NSString *)ignoreString ignoringGenre:(NSString *)genreString withMinimumDuration:(int)minimumDuration {

	if (!xmlPath || ![[NSFileManager defaultManager] fileExistsAtPath:xmlPath]) {
		NSLog(@"Supplied XML path does not exist - Using default XML path");
		xmlPath = [@"~/Music/iTunes/iTunes Music Library.xml" stringByExpandingTildeInPath];
	}

	NSLog(@"Starting XML contents read");
	NSDictionary *itunesLibrary = [NSDictionary dictionaryWithContentsOfFile:xmlPath];
	NSLog(@"Completed XML contents read");
		
	//check to see if library load was successful
	
	NSMutableArray *resultSongArray = [NSMutableArray new];
	
	BOOL useAlbumArtist = [[NSUserDefaults standardUserDefaults] boolForKey:BGPrefShouldUseAlbumArtist];
	
	if (itunesLibrary) {
		NSLog(@"Parsing XML contents");
		NSDictionary *itunesTracks = [itunesLibrary objectForKey:@"Tracks"];
		
		if (itunesTracks) {
			NSMutableArray *wantedTracks = [NSMutableArray new];
			
			NSString *key;	
			for (key in itunesTracks) {
				NSDictionary *trackDetails = [itunesTracks objectForKey:key];
				BOOL trackPassed = [trackDetails passesExclusionTestWithCutoffDate:cutoffDate includingPodcasts:includePodcasts includingVideo:includeVideo ignoringComment:ignoreString ignoringGenre:genreString withMinimumDuration:minimumDuration];
				if (trackPassed==YES)	[wantedTracks addObject:trackDetails];
			}
			NSLog(@"Tracks Passed: %d",wantedTracks.count);
			
			NSSortDescriptor *d = [[[NSSortDescriptor alloc] initWithKey: @"Play Date UTC" ascending: YES] autorelease];
			NSArray *wantedTracksSorted = [wantedTracks sortedArrayUsingDescriptors: [NSArray arrayWithObject: d]];
			
			[wantedTracks release];

			NSDictionary *trackStuff;
			for (trackStuff in wantedTracksSorted) {
				// track name
				NSString *nameString = [trackStuff objectForKey:@"Name"];
				if (!nameString) nameString = @"";
				
				// artist, using album artist where possible
				NSString *artistString = nil;
				if (useAlbumArtist) artistString = [trackStuff objectForKey:@"Album Artist"];
				if (!artistString)  artistString = [trackStuff objectForKey:@"Artist"];
				if (!artistString)  artistString = @"";
				
				// album name
				NSString *albumString = [trackStuff objectForKey:@"Album"];
				if (!albumString) albumString = @"";
				
				// track duration
				NSString *theduration = [NSString stringWithFormat:@"%i",(int)([[trackStuff objectForKey:@"Total Time"] intValue]/1000)];
				
				// played date
				NSString *playedString = [[trackStuff objectForKey:@"Play Date UTC"] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil];
				NSCalendarDate *playedDate = [NSCalendarDate dateWithString:playedString calendarFormat:@"%Y-%m-%d %H:%M:%S"];
				
				// play count
				int playCount = [[trackStuff objectForKey:@"Play Count"] intValue];
				
				// unique identifier
				NSString *uniqueIdentifier = [[trackStuff objectForKey:@"Track ID"] stringValue];
				
				BGLastFmSong *newSong;
				newSong = [[BGLastFmSong alloc] initWithTitle:nameString
													   artist:artistString
														album:albumString];
				[newSong setLength:[theduration intValue]];
				[newSong setLastPlayed:playedDate];
				[newSong setExtraPlays:0];
				[newSong setPlayCount:playCount];
				[newSong setUniqueIdentifier:uniqueIdentifier];
				
				[resultSongArray addObject:newSong];
				[newSong release];
			}
		
		} else NSLog(@"Could not load track item from dictionary, but XML was loaded OK");
			
	} else NSLog(@"Could not load dictionary from XML");
	
	//itunesLibrary

	return resultSongArray;
}
@end
