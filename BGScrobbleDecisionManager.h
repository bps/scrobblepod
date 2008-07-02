//
//  BGScrobbleDecisionManager.h
//  ScrobblePod
//
//  Created by Ben Gummer on 15/05/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>

@interface BGScrobbleDecisionManager : NSObject {
	BOOL cachedOverallDecision;
	BOOL isDecisionMadeAutomtically;
	BOOL usersManualChoice;
	BOOL firstRefresh;
	NSTimer *refreshTimer;
}

@property (assign) BOOL cachedOverallDecision;
@property (assign) BOOL isDecisionMadeAutomtically;
@property (assign) BOOL usersManualChoice;

+(BGScrobbleDecisionManager *)sharedManager;
+(id)allocWithZone:(NSZone *)zone;
-(id)copyWithZone:(NSZone *)zone;
-(id)retain;
-(unsigned)retainCount;
-(void)release;
-(id)autorelease;

-(id)init;

#pragma mark Decision Making

-(BOOL)shouldScrobble;
-(BOOL)shouldScrobbleAuto;

#pragma mark Refreshing Cache
-(void)refreshDecisionAndNotifyIfChanged:(BOOL)notify;

#pragma mark Timer

-(void)startRefreshTimer;
-(void)refreshFromTimer:(NSTimer *)fromTimer;
-(void)stopRefreshTimer;
-(void)resetRefreshTimer; 

@end
