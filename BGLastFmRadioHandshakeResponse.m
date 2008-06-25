//
//  BGLastFmHandshakeResponse.m
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 8/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import "BGLastFmRadioHandshakeResponse.h"
#import "BGLastFmDefines.h"

#define Use_Timeout_Url NO


@implementation BGLastFmRadioHandshakeResponse

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
		if ([statusLine rangeOfString:@"session="].length > 0) {
			responseType = 1;
		}
// else if ([statusLine rangeOfString:@"BANNED"].length > 0) {
//			responseType = 2;
//		} else if ([statusLine rangeOfString:@"BADAUTH"].length > 0) {
//			responseType = 3;
//		} else if ([statusLine rangeOfString:@"BADTIME"].length > 0) {
//			responseType = 4;
//		} else if ([statusLine rangeOfString:@"FAILED"].length > 0) {
//			responseType = 5;
//		}
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
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:NO] forKey:Handshake_DidFail];
		
		NSString *currentLine;
		for (currentLine in responseLines) {

			if ([currentLine rangeOfString:@"session="].length > 0) {
				NSString *extractedSessionKey = [[currentLine componentsSeparatedByString:@"="] objectAtIndex:1];
				[responseDetailsDictionary setObject:extractedSessionKey forKey:Handshake_SessionKey];
			} else if ([currentLine rangeOfString:@"base_url="].length > 0) {
				NSString *extractedBaseUrl = [[currentLine componentsSeparatedByString:@"="] objectAtIndex:1];
				[responseDetailsDictionary setObject:extractedBaseUrl forKey:AudioScrobbler_ServiceBaseUrl];
			}

		}
		
	} else {
		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
	}
	
	
	
//	else if (responseType==2) {
//		[responseDetailsDictionary setObject:@"BANNED" forKey:Handshake_ResponseTypeString];
//		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
//		[responseDetailsDictionary setObject:@"Client is banned from accessing audioscrobbler webservice" forKey:Handshake_FailureReason];
//	} else if (responseType==3) {
//		[responseDetailsDictionary setObject:@"BADAUTH" forKey:Handshake_ResponseTypeString];
//		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
//		[responseDetailsDictionary setObject:@"Authentication details provided were incorrect" forKey:Handshake_FailureReason];
//	} else if (responseType==4) {
//		[responseDetailsDictionary setObject:@"BADTIME" forKey:Handshake_ResponseTypeString];
//		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
//		[responseDetailsDictionary setObject:@"The timestamp provided was not close enough to the current time" forKey:Handshake_FailureReason];
//	} else if (responseType==5) {
//		[responseDetailsDictionary setObject:@"FAILED" forKey:Handshake_ResponseTypeString];
//		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
//		[responseDetailsDictionary setObject:[[responseLines objectAtIndex:0] substringFromIndex:7] forKey:Handshake_FailureReason];
//	} else if (responseType==0) {
//		[responseDetailsDictionary setObject:@"UNKNOWNRESPONSE" forKey:Handshake_ResponseTypeString];
//		[responseDetailsDictionary setObject:[NSNumber numberWithBool:YES] forKey:Handshake_DidFail];
//		[responseDetailsDictionary setObject:@"Handshake response could not be parsed" forKey:Handshake_FailureReason];
//	}
	return responseDetailsDictionary;
}

-(NSString *)sessionKey {
	return [responseComponents objectForKey:Handshake_SessionKey];
}

-(NSString *)baseURL {
	return [responseComponents objectForKey:AudioScrobbler_ServiceBaseUrl];
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

-(NSString *)description {
	return [NSString stringWithFormat:@"%@",responseComponents];
}

@end
