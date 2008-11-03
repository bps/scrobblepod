//
//  BGLastFmAuthenticationManager.m
//  ApiHubTester
//
//  Created by Ben Gummer on 18/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGLastFmAuthenticationManager.h"
#import "BGLastFmWebServiceHandshaker.h"
#import "BGLastFmSubmissionHandshaker.h"
#import "BGLastFmSubmissionHandshakeResponse.h"
#import "HubNotifications.h"
#import "HubStrings.h"
#import "Defines.h"

@implementation BGLastFmAuthenticationManager

@synthesize delegate;

-(id)initWithDelegate:(id)sender {
	self = [super init];
	if (self != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newSessionKeyAcquired) name:APIHUB_WebServiceAuthorizationProcessing object:nil];
		[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
		self.delegate = sender;
		if (self.webServiceSessionKey && self.webServiceSessionKey.length>0) [self fetchNewSubmissionSessionKeyUsingWebServiceSessionKey];
	}
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSString *newToken = [[url componentsSeparatedByString:@"token="] lastObject];
	
	if (newToken.length == 32) {
		if ([BGLastFmWebServiceHandshaker fetchSessionKeyUsingToken:newToken]) {
			[NSApp activateIgnoringOtherApps:YES];
			[self fetchNewSubmissionSessionKeyUsingWebServiceSessionKey];
		}
	} else {
		NSLog(@"Invalid Token Received: %@ (length is %d)",newToken,newToken.length);
	}
}

-(void)newSessionKeyAcquired {
	NSLog(@"Got Username:%@ and Session:%@",self.username,self.webServiceSessionKey);
	SEL theSelector = @selector(newWebServiceSessionKeyAcquired);
	if ([delegate respondsToSelector:theSelector]) [delegate performSelector:theSelector];
}

-(void)beginNewWebServiceSessionProcedure {
	BGLastFmWebServiceHandshaker *tokenFetcher = [[BGLastFmWebServiceHandshaker alloc] init];
	[tokenFetcher openAuthorizationSite];
	[tokenFetcher release];
}

-(void)fetchNewSubmissionSessionKeyUsingWebServiceSessionKey {
	NSString *wsSessionKey = self.webServiceSessionKey;
	if (wsSessionKey != nil) {
		BGLastFmSubmissionHandshaker *submissionFetcher = [[BGLastFmSubmissionHandshaker alloc] init];
		BGLastFmSubmissionHandshakeResponse *response = [submissionFetcher performSubmissionHandshakeForUser:self.username withWebServiceSessionKey:self.webServiceSessionKey];

		NSString *submissionSessionKey = response.sessionKey;
		if (submissionSessionKey != nil) {
			NSLog(@"Got Submission Key: %@",submissionSessionKey);
			[[NSUserDefaults standardUserDefaults] setObject:submissionSessionKey forKey:BGSubmissionSessionKey];
			[[NSUserDefaults standardUserDefaults] setObject:response.nowPlayingURL forKey:BGNowPlayingSubmissionURL];
			[[NSUserDefaults standardUserDefaults] setObject:response.postURL forKey:BGScrobblingSubmissionURL];
			SEL theSelector = @selector(newSubmissionSessionKeyAcquired);
			if ([delegate respondsToSelector:theSelector]) [delegate performSelector:theSelector];
		}
	}
}

-(NSString *)webServiceSessionKey {
	return [[NSUserDefaults standardUserDefaults] stringForKey:BGWebServiceSessionKey];
}

-(NSString *)submissionSessionKey {
	return [[NSUserDefaults standardUserDefaults] stringForKey:BGSubmissionSessionKey];
}

-(NSString *)username {
	return [[NSUserDefaults standardUserDefaults] stringForKey:BGPrefUsername];
}

-(NSString *)nowPlayingSubmissionURL {
	return [[NSUserDefaults standardUserDefaults] stringForKey:BGNowPlayingSubmissionURL];
}

-(NSString *)scrobbleSubmissionURL {
	return [[NSUserDefaults standardUserDefaults] stringForKey:BGScrobblingSubmissionURL];
}

@end
