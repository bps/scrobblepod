//
//  BGLastFmScrobbler.m
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 8/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import "BGLastFmScrobbler.h"
#import "BGLastFmSong.h"
#import "BGLastFmDefines.h"
#import "Defines.h"
#import "NSString+UrlEncoding.h"


@implementation BGLastFmScrobbler

-(id)init {
	self = [super init];
	if (self != nil) {
		
	}
	return self;
}

- (void) dealloc {
	[super dealloc];
}

-(BGLastFmScrobbleResponse *)performScrobbleWithSongs:(NSArray *)songList andSessionKey:(NSString *)theSessionKey toURL:(NSURL *)postURL {
	BGLastFmScrobbleResponse *theResponse = [[BGLastFmScrobbleResponse alloc] init];
	int songIndex = 0;
	
	int multiLimitPref = MultiPostMax;
	if (![[NSUserDefaults standardUserDefaults] boolForKey:BGPrefWantMultiPost]) multiLimitPref = 1;
	
	while ( songIndex<[songList count] && [theResponse wasSuccessful]) {

		NSMutableString *postString = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"s=%@",theSessionKey]]; //session		
		int efficientPostIndex = 0;

		NSCalendarDate *playedDate_Original;

		while ( songIndex+efficientPostIndex<[songList count] && efficientPostIndex<multiLimitPref ) {

			int totalIndex = songIndex+efficientPostIndex;

			BGLastFmSong *currentTrackDetails = [songList objectAtIndex:totalIndex];

			int trackLength = [currentTrackDetails length];

			playedDate_Original = currentTrackDetails.lastPlayed;
			
			NSCalendarDate *playedDate = [playedDate_Original copy];
			[playedDate setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			playedDate = [playedDate dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:(trackLength*-1)];
			NSString *playedDateUTC = [NSString stringWithFormat:@"%d",(int)[playedDate timeIntervalSince1970]];
			
			[postString appendString:[NSString stringWithFormat:@"&a[%d]=%@",efficientPostIndex,[[currentTrackDetails artist] urlEncodedString]]]; //artist
			[postString appendString:[NSString stringWithFormat:@"&t[%d]=%@",efficientPostIndex,[[currentTrackDetails title] urlEncodedString]]]; // track
			[postString appendString:[NSString stringWithFormat:@"&i[%d]=%@",efficientPostIndex,playedDateUTC]]; //timeplaystarted
			[postString appendString:[NSString stringWithFormat:@"&o[%d]=P",efficientPostIndex]]; //source
			[postString appendString:[NSString stringWithFormat:@"&r[%d]=",efficientPostIndex]]; //rating
			[postString appendString:[NSString stringWithFormat:@"&l[%d]=%d",efficientPostIndex,trackLength]]; //tracklength
			[postString appendString:[NSString stringWithFormat:@"&b[%d]=%@",efficientPostIndex,[[currentTrackDetails album] urlEncodedString]]]; //album
			[postString appendString:[NSString stringWithFormat:@"&n[%d]=",efficientPostIndex]]; //tracknumber
			[postString appendString:[NSString stringWithFormat:@"&m[%d]=",efficientPostIndex]]; //musicbrainz

			efficientPostIndex++;

		}
		
		NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
		
		NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
		[request setURL:postURL];
		[request setHTTPMethod:@"POST"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
		[request setTimeoutInterval:10.00];// timeout scrobble posting after 20 seconds
		[request setHTTPBody:postData];
		
		[postString release];

		NSError *postingError;
		NSHTTPURLResponse *response = nil;
		NSData *scrobbleResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&postingError];
		
		NSLog(@"STATUS CODE: %d",[response statusCode]);
		NSLog(@"ERROR CODE: %d",[postingError code]);
		
		if (scrobbleResponseData!=nil/* && [postingError code]!=-1001 && [response statusCode]==200*/) {
			NSString *scrobbleResponseString = [[NSString alloc] initWithData:scrobbleResponseData encoding:NSUTF8StringEncoding];
			if (theResponse) [theResponse release];
			theResponse = [[BGLastFmScrobbleResponse alloc] initWithScrobbleResponseString:scrobbleResponseString];
			[scrobbleResponseString release];
			
			if ([theResponse wasSuccessful]) {
				[theResponse setLastScrobbleDate:[playedDate_Original dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:5]];//add small amount of time so that applescript does not pick up same track twice
			}
		} else {
			[theResponse setWasSuccessful:NO];
		}
		
		songIndex = songIndex + efficientPostIndex;

	}
	return theResponse;
}

@end
