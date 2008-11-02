//
//  BGLastFmHandshaker.m
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 8/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import "BGLastFmHandshaker.h"
#import "CocoaCryptoHashing.h"
#import "HubStrings.h"

@implementation BGLastFmHandshaker

-(id)init {
	self = [super init];
	if (self != nil) {
		
	}
	return self;
}

- (void) dealloc {
	[super dealloc];
}

-(BGLastFmHandshakeResponse *)performHandshakeWithUsername:(NSString *)theUsername usingApiSessionKey:(NSString *)apiSessionKey {

	NSString *currentUnixTime;
	NSString *authenticationHash;
	NSURL *handshakeURL;

	int handshakeAttempts = 0;
	BGLastFmHandshakeResponse *theResponse = [[BGLastFmHandshakeResponse alloc] init];

	while ([theResponse sessionKey]==nil && ![theResponse didFail] && handshakeAttempts<3 ) {
		
		currentUnixTime = [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]]; 
		authenticationHash = [[NSString stringWithFormat:@"%@%@",[API_SECRET md5HexHash],currentUnixTime] md5HexHash];

		handshakeURL = [NSURL URLWithString: [NSString stringWithFormat:@"http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=sld&v=0.50.11&u=%@&t=%@&a=%@&sk=%@",theUsername,currentUnixTime,authenticationHash,apiSessionKey]];

		NSMutableURLRequest *handshakeRequest = [[NSMutableURLRequest alloc] initWithURL:handshakeURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:2.0];
		[handshakeRequest setHTTPMethod:@"GET"];
		[handshakeRequest setTimeoutInterval:10.0];

		NSError *handshakeAccessError;
		NSHTTPURLResponse *response = nil;
		NSData *handshakeResponseData = [NSURLConnection sendSynchronousRequest:handshakeRequest returningResponse:&response error:&handshakeAccessError];
			
		[handshakeRequest release];
		if (handshakeResponseData!=nil && [response statusCode]==200  && [handshakeAccessError code]!=-1001) {
			NSString *handshakeResponseString = [[NSString alloc] initWithData:handshakeResponseData encoding:NSUTF8StringEncoding];
			if (theResponse) [theResponse release];
			theResponse = [[BGLastFmHandshakeResponse alloc] initWithHandshakeResponseString:handshakeResponseString];
			[handshakeResponseString release];
		} else {
			[theResponse setDidFail:YES];
		}

		handshakeAttempts++;

	}
	
	return theResponse;

}

@end
