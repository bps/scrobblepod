//
//  BGLastFMPasswordChecker.m
//  ScrobblePod
//
//  Created by Ben on 8/02/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGLastFMPasswordChecker.h"
#import "CocoaCryptoHashing.h"

@implementation BGLastFMPasswordChecker

-(BOOL)checkCredentialsWithUsername:(NSString *)theUsername andPassword:(NSString *)thePassword {
	BOOL credentialsAreValid = TRUE; // default to true just in case i did something wrong... dont want to lock people out!
	
	NSString *currentUnixTime = [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]]; 
	NSString *authenticationHashOne = [[NSString stringWithFormat:@"%@%@",[thePassword md5HexHash],currentUnixTime] md5HexHash];
	NSString *authenticationHashTwo = [[NSString stringWithFormat:@"%@%@",[[thePassword lowercaseString] md5HexHash],currentUnixTime] md5HexHash];

	NSURL *passwordCheckURL = [NSURL URLWithString: [NSString stringWithFormat:@"http://ws.audioscrobbler.com//ass/pwcheck.php?time=%@&username=%@&auth=%@&auth2=%@&defaultplayer=",currentUnixTime,theUsername,authenticationHashOne,authenticationHashTwo]];

	NSMutableURLRequest *passwordRequest = [[NSMutableURLRequest alloc] initWithURL:passwordCheckURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0];
	[passwordRequest setHTTPMethod:@"GET"];

	NSError *passwordAccessError;
	NSData *passwordResponseData = [NSURLConnection sendSynchronousRequest:passwordRequest returningResponse:nil error:&passwordAccessError];
			
	[passwordRequest release];
			
	if (passwordResponseData!=nil && passwordAccessError==nil) {
		NSString *passwordResponseString = [[NSString alloc] initWithData:passwordResponseData encoding:NSUTF8StringEncoding];
		if ([passwordResponseString rangeOfString:@"OK"].length == 0) credentialsAreValid = NO;
	}

	return credentialsAreValid;

}

@end
