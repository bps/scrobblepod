//
//  BGLastFmSubmissionHandshaker.m
//  ApiHubTester
//
//  Created by Ben Gummer on 17/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGLastFmSubmissionHandshaker.h"
#import "CocoaCryptoHashing.h"
#import "HubStrings.h"
#import "HubNotifications.h"

@implementation BGLastFmSubmissionHandshaker

-(BGLastFmSubmissionHandshakeResponse *)performSubmissionHandshakeForUser:(NSString *)username withWebServiceSessionKey:(NSString *)wsSessionKey {
	NSString *currentUnixTime = [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]]; 
	NSString *authString = [[NSString stringWithFormat:@"%@%@",API_SECRET,currentUnixTime] md5HexHash];

	NSString *handshakeUrlString = [NSString stringWithFormat:@"http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=sld&v=0.52&u=%@&t=%@&a=%@&api_key=%@&sk=%@",username,currentUnixTime,authString,API_KEY,wsSessionKey];
	
	NSURL *postURL = [NSURL URLWithString:handshakeUrlString];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:postURL];
	[request setHTTPMethod:@"GET"];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	[request setTimeoutInterval:10.00];// timeout scrobble posting after 20 seconds

	NSError *postingError;
	NSHTTPURLResponse *response = nil;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&postingError];
	
	[request release];
	
	BGLastFmSubmissionHandshakeResponse *responseObject;
	if (responseData!=nil && [postingError code]!=-1001 && [response statusCode]==200) {
		responseObject = [[BGLastFmSubmissionHandshakeResponse alloc] initWithData:responseData];
		NSLog(@"SUB");
		[[NSNotificationCenter defaultCenter] postNotificationName:APIHUB_WebServiceAuthorizationCompleted object:nil];
	} else {
		responseObject = [[BGLastFmSubmissionHandshakeResponse alloc] initWithData:nil];
	}
	return [responseObject autorelease];
}

@end
