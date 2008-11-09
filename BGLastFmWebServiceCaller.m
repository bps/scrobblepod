//
//  BGLastFmWebServiceCaller.m
//  ApiHubTester
//
//  Created by Ben Gummer on 18/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGLastFmWebServiceCaller.h"
#import "HubStrings.h"

@implementation BGLastFmWebServiceCaller

-(BGLastFmWebServiceResponse *)callWithParameters:(BGLastFmWebServiceParameterList *)parameterList usingPostMethod:(BOOL)postBool usingAuthentication:(BOOL)needAuthentication {
	BGLastFmWebServiceResponse *responseObject;
	BOOL callWasSent = NO;
	if (!postBool || (postBool && [parameterList parameterForKey:@"sk"]!=nil && [parameterList parameterForKey:@"sk"].length>0)) {
		NSString *postString = [NSString stringWithFormat:@"%@%@",
			[parameterList concatenatedParametersString],
			(needAuthentication ? [NSString stringWithFormat:@"&api_sig=%@", [parameterList methodSignature]] : @"" )
		];
		NSURL *postURL;
		if (postBool) {
			postURL = [NSURL URLWithString:@"http://ws.audioscrobbler.com/2.0/"];
		} else {
			postURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?%@",postString]];
		}

		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		[request setURL:postURL];
		[request setHTTPMethod:(postBool ? @"POST" : @"GET")];

		if (postBool) {
			NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
			NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
			[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
			[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			[request setHTTPBody:postData];
		}

		[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
		[request setTimeoutInterval:10.00];// timeout scrobble posting after 20 seconds

		NSError *postingError;
		NSHTTPURLResponse *response = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&postingError];
		
		[request release];
		
		int responseStatusCode = [response statusCode];
		
		if (responseData!=nil && [postingError code]!=-1001 && (responseStatusCode==200 || responseStatusCode==403) ) {
			responseObject = [[BGLastFmWebServiceResponse alloc] initWithData:responseData];
			callWasSent = YES;
		} else {
			NSLog(@"Got HTTP Status Code %d and did not continue.",responseStatusCode);
		}
	} else {
		NSLog(@"Could not complete API POST request: no session key provided");
	}
	
	if (callWasSent == NO) {
		NSLog(@"-- Completed API call but nothing returned");
		responseObject = [[BGLastFmWebServiceResponse alloc] initWithData:nil];
	}
	return [responseObject autorelease];
}

@end
