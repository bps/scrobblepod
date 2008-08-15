//
//  BGLastFmScrobbleResponse.m
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 8/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import "BGLastFmScrobbleResponse.h"
#import "BGLastFmDefines.h"


@implementation BGLastFmScrobbleResponse

- (id) init {
	self = [super init];
	if (self != nil) {
		responseComponents = [NSMutableDictionary new];
		[responseComponents setValue:[NSNumber numberWithBool:YES] forKey:Scrobble_WasSuccessful];
	}
	return self;
}


-(id)initWithScrobbleResponseString:(NSString *)aString {
	self = [super init];
	if (self != nil) {
		NSLog(@"%@",aString);
		responseLines = [[aString componentsSeparatedByString:@"\n"] retain];

		NSString *statusLine = [responseLines objectAtIndex:0];
		responseType = 0;
		if ([statusLine rangeOfString:@"OK"].length > 0) {
			responseType = 1;
		} else if ([statusLine rangeOfString:@"BADSESSION"].length > 0) {
			responseType = 2;
		} else if ([statusLine rangeOfString:@"FAILED"].length > 0) {
			responseType = 3;
		}
		responseComponents = [[self parseResponse] retain];
	}
	return self;
}

- (void) dealloc {
	[responseLines release];
	[responseComponents release];
	[self setLastScrobbleDate:nil];
	[super dealloc];
}

-(NSDictionary *)parseResponse {
	NSMutableDictionary *responseDetailsDictionary = [[NSMutableDictionary new] autorelease];

	if (responseType==1) {
		[responseDetailsDictionary setObject:@"OK" forKey:Scrobble_ResponseTypeString];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Scrobble_WasSuccessful];
	} else if (responseType==2) {
		[responseDetailsDictionary setObject:@"BADSESSION" forKey:Scrobble_ResponseTypeString];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:NO] forKey:Scrobble_WasSuccessful];
		[responseDetailsDictionary setObject:@"The supplied session key was invalid" forKey:Scrobble_FailureReason];
	} else if (responseType==3) {
		[responseDetailsDictionary setObject:@"FAILED" forKey:Scrobble_ResponseTypeString];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:NO] forKey:Scrobble_WasSuccessful];
		[responseDetailsDictionary setObject:[[responseLines objectAtIndex:0] substringFromIndex:7] forKey:Scrobble_FailureReason];
	} else if (responseType==0) {
		[responseDetailsDictionary setObject:@"UNKNOWNRESPONSE" forKey:Scrobble_ResponseTypeString];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:NO] forKey:Scrobble_WasSuccessful];
		[responseDetailsDictionary setObject:@"Scrobble response could not be parsed" forKey:Scrobble_FailureReason];
	}

	return responseDetailsDictionary;
}

-(BOOL)wasSuccessful {
	return [[responseComponents objectForKey:Scrobble_WasSuccessful] boolValue];
}

-(void)setWasSuccessful:(BOOL)aBool {
	[responseComponents setValue:[NSNumber numberWithBool:aBool] forKey:Scrobble_WasSuccessful];
}

-(int)responseType {
	return responseType;
}

-(NSString *)failureReason {
	return [responseComponents objectForKey:Scrobble_FailureReason];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@",responseComponents];
}

-(NSCalendarDate *)lastScrobbleDate {
	return lastScrobbleDate;
}

-(void)setLastScrobbleDate:(NSCalendarDate *)aDate {
	if (lastScrobbleDate!=nil) [lastScrobbleDate release];
	lastScrobbleDate = [aDate retain];
}

@end
