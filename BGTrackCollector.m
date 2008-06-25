//
//  BGTrackCollector.m
//  ScrobblePod
//
//  Created by Ben on 13/01/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGTrackCollector.h"
#import "BGLastFmSong.h"
#import "NSDictionary+ExclusionTest.h"

@implementation BGTrackCollector
-(NSMutableArray *)collectTracksFromXMLFile:(NSString *)xmlPath withCutoffDate:(NSDate *)cutoffDate includingPodcasts:(BOOL)includePodcasts includingVideo:(BOOL)includeVideo ignoringComment:(NSString *)ignoreString withMinimumDuration:(int)minimumDuration {

	if (!xmlPath || ![[NSFileManager defaultManager] fileExistsAtPath:xmlPath]) xmlPath = [@"~/Music/iTunes/iTunes Music Library.xml" stringByExpandingTildeInPath];

	NSDictionary *itunesLibrary = [NSDictionary dictionaryWithContentsOfFile:xmlPath];
	
	//check to see if library load was successful
	
	NSMutableArray *resultSongArray = [NSMutableArray new];
	
	if (itunesLibrary) {
	
		NSDictionary *itunesTracks = [itunesLibrary objectForKey:@"Tracks"];
		NSMutableArray *wantedTracks = [NSMutableArray new];
		
		NSString *key;	
		for (key in itunesTracks) {
			NSDictionary *trackDetails = [itunesTracks objectForKey:key];
			BOOL trackPassed = [trackDetails passesExclusionTestWithCutoffDate:cutoffDate includingPodcasts:includePodcasts includingVideo:includeVideo ignoringComment:ignoreString withMinimumDuration:minimumDuration];
			if (trackPassed==YES)	[wantedTracks addObject:trackDetails];
		}
		NSLog(@"Tracks Passed: %d",wantedTracks.count);
		
		NSSortDescriptor *d = [[[NSSortDescriptor alloc] initWithKey: @"Play Date UTC" ascending: YES] autorelease];
		NSArray *wantedTracksSorted = [wantedTracks sortedArrayUsingDescriptors: [NSArray arrayWithObject: d]];
		
		[wantedTracks release];

		NSDictionary *trackStuff;
		for (trackStuff in wantedTracksSorted) {
			NSString *nameString = [trackStuff objectForKey:@"Name"];
			if (!nameString) nameString = @"";
			NSString *artistString = [trackStuff objectForKey:@"Artist"];
			if (!artistString) artistString = @"";
			NSString *albumString = [trackStuff objectForKey:@"Album"];
			if (!albumString) albumString = @"";
			NSString *theduration = [NSString stringWithFormat:@"%i",(int)([[trackStuff objectForKey:@"Total Time"] intValue]/1000)];
			NSString *playedString = [[trackStuff objectForKey:@"Play Date UTC"] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil];
			NSCalendarDate *playedDate = [NSCalendarDate dateWithString:playedString calendarFormat:@"%Y-%m-%d %H:%M:%S"];
			int playCount = [[trackStuff objectForKey:@"Play Count"] intValue];
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

			
	}
	
	//itunesLibrary

	return resultSongArray;
}
@end
