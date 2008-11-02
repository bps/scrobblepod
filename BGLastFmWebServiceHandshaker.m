//
//  BGLastFmWebServiceHandshaker.m
//  ApiHubTester
//
//  Created by Ben Gummer on 17/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGLastFmWebServiceHandshaker.h"
#import "BGLastFmWebServiceParameterList.h"
#import "BGLastFmWebServiceCaller.h"
#import "BGLastFmWebServiceResponse.h"
#import "HubStrings.h"
#import "HubNotifications.h"
#import "Defines.h"

@interface BGLastFmWebServiceHandshaker (Private)
-(NSString *)sessionKeyFromToken:(NSString *)theToken;
@end

@implementation BGLastFmWebServiceHandshaker (Private)

-(NSString *)sessionKeyFromToken:(NSString *)theToken {
	NSLog(@"SESSION FROM TOKEN %@",theToken);
	if (theToken) {
		BGLastFmWebServiceParameterList *sessionParams = [[BGLastFmWebServiceParameterList alloc] initWithMethod:@"auth.getSession" andSessionKey:nil];
			[sessionParams setParameter:theToken forKey:@"token"];

			BGLastFmWebServiceCaller *sessionCaller = [[BGLastFmWebServiceCaller alloc] init];
				BGLastFmWebServiceResponse *response = [sessionCaller callWithParameters:sessionParams usingPostMethod:NO];
			[sessionCaller release];
		[sessionParams release];
		
		NSLog(@"%@",response.responseDocument);
		
		if (response.wasOK) {
			NSString *session = [response stringValueForXPath:@"/lfm/session/key"];
			NSString *username = [response stringValueForXPath:@"/lfm/session/name"];
			if (session && username) {
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				[defaults setObject:session forKey:BGWebServiceSessionKey];
				[defaults setObject:username forKey:BGPrefUsername];
				[[NSNotificationCenter defaultCenter] postNotificationName:APIHUB_WebServiceAuthorizationCompleted object:nil];
				return session;
			}
		} else {
			NSLog(@"Unable to fetch Session Key: response.translatedCode=%d",response.translatedCode);
		}

	}
	
	return nil;
}

@end

#pragma mark NORMAL

@implementation BGLastFmWebServiceHandshaker

-(id)init {
	self = [super init];
	return self;
}

-(void)openAuthorizationSite {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/api/auth?api_key=%@",API_KEY]]];
}

+ (NSString *)fetchSessionKeyUsingToken:(NSString *)theToken {
	BGLastFmWebServiceHandshaker *obj = [[self alloc] init];
	NSString *sk = [obj sessionKeyFromToken:theToken];
	[obj release];
	
	return sk;
}

@end
