//
//  BGLastFmHandshakeResponse.m
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 8/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import "BGLastFmHandshakeResponse.h"
#import "BGLastFmDefines.h"

#define Use_Timeout_Url NO


@implementation BGLastFmHandshakeResponse

- (id) init {
	self = [super init];
	if (self != nil) {
		responseComponents = [NSMutableDictionary new];
		[responseComponents setObject:[NSNumber numberWithBool:NO] forKey:Handshake_DidFail];
	}
	return self;
}


-(id)initWithHandshakeResponseString:(NSString *)aString {
	self = [super init];
	if (self != nil) {
		responseLines = [[aString componentsSeparatedByString:@"\n"] retain];

		NSString *statusLine = [responseLines objectAtIndex:0];
		responseType = 0;
		if ([statusLine rangeOfString:@"OK"].length > 0) {
			responseType = 1;
		} else if ([statusLine rangeOfString:@"BANNED"].length > 0) {
			responseType = 2;
		} else if ([statusLine rangeOfString:@"BADAUTH"].length > 0) {
			responseType = 3;
		} else if ([statusLine rangeOfString:@"BADTIME"].length > 0) {
			responseType = 4;
		} else if ([statusLine rangeOfString:@"FAILED"].length > 0) {
			responseType = 5;
		}
		responseComponents = [[self parseResponse] retain];
	}
	return self;
}

- (void) dealloc {
	[responseLines release];
	[responseComponents release];
	[super dealloc];
}

-(NSDictionary *)parseResponse {
	NSMutableDictionary *responseDetailsDictionary = [[NSMutableDictionary new] autorelease];

	if (responseType==1) {
		[responseDetailsDictionary setObject:@"OK" forKey:Handshake_ResponseTypeString];
		[responseDetailsDictionary setObject:[responseLines objectAtIndex:1] forKey:Handshake_SessionKey];
		[responseDetailsDictionary setObject:[NSURL URLWithString:[responseLines objectAtIndex:2]] forKey:Handshake_NowPlayingURL];
//		[responseDetailsDictionary setObject:[NSURL URLWithString:@"http://scrobblepod.sourceforge.net/timeout.php?time=25"] forKey:Handshake_PostURL];
		[responseDetailsDictionary setObject:[NSURL URLWithString:[responseLines objectAtIndex:3]] forKey:Handshake_PostURL];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:NO] forKey:Handshake_DidFail];
	} else if (responseType==2) {
		[responseDetailsDictionary setObject:@"BANNED" forKey:Handshake_ResponseTypeString];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
		[responseDetailsDictionary setObject:@"Client is banned from accessing audioscrobbler webservice" forKey:Handshake_FailureReason];
	} else if (responseType==3) {
		[responseDetailsDictionary setObject:@"BADAUTH" forKey:Handshake_ResponseTypeString];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
		[responseDetailsDictionary setObject:@"Authentication details provided were incorrect" forKey:Handshake_FailureReason];
	} else if (responseType==4) {
		[responseDetailsDictionary setObject:@"BADTIME" forKey:Handshake_ResponseTypeString];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
		[responseDetailsDictionary setObject:@"The timestamp provided was not close enough to the current time" forKey:Handshake_FailureReason];
	} else if (responseType==5) {
		[responseDetailsDictionary setObject:@"FAILED" forKey:Handshake_ResponseTypeString];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
		[responseDetailsDictionary setObject:[[responseLines objectAtIndex:0] substringFromIndex:7] forKey:Handshake_FailureReason];
	} else if (responseType==0) {
		[responseDetailsDictionary setObject:@"UNKNOWNRESPONSE" forKey:Handshake_ResponseTypeString];
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
		[responseDetailsDictionary setObject:@"Handshake response could not be parsed" forKey:Handshake_FailureReason];
	}
	return responseDetailsDictionary;
}

-(NSString *)sessionKey {
	return [responseComponents objectForKey:Handshake_SessionKey];
}

-(NSString *)failureReason {
	return [responseComponents objectForKey:Handshake_FailureReason];
}

-(BOOL)didFail {
	return [[responseComponents objectForKey:Handshake_DidFail] boolValue];
}

-(void)setDidFail:(BOOL)aBool {
	[responseComponents setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
}

-(int)responseType {
	return responseType;
}

-(NSURL *)nowPlayingURL {
	return [responseComponents objectForKey:Handshake_NowPlayingURL];
}

-(NSURL *)postURL {
	if (Use_Timeout_Url) return [NSURL URLWithString:@"http://scrobblepod.sourceforge.net/timeout.php?time=25"];
	return [responseComponents objectForKey:Handshake_PostURL];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@",responseComponents];
}

@end
