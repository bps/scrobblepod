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
	BOOL cachedDecision;
	BOOL firstRefresh;
	NSTimer *refreshTimer;
	BOOL cachedAutoChoice;
	BOOL cachedUserChoice;
}

@property (assign) BOOL cachedDecision;

+(BGScrobbleDecisionManager *)sharedManager;
+(id)allocWithZone:(NSZone *)zone;
-(id)copyWithZone:(NSZone *)zone;
-(id)retain;
-(unsigned)retainCount;
-(void)release;
-(id)autorelease;

-(id)init;

#pragma mark Decision Making

-(BOOL)shouldScrobbleWhenUsingAutoDecide:(BOOL)usingAutoDecide withUserChosenStatus:(BOOL)userChosenStatus;
-(BOOL)shouldScrobbleAuto;

#pragma mark Refreshing Cache
-(void)refreshDecisionWithAutoDecide:(BOOL)usingAutoDecide userChosenStatus:(BOOL)userChosenStatus notifyingIfChanged:(BOOL)notify;

#pragma mark Timer

-(void)startRefreshTimer;
-(void)refreshFromTimer:(NSTimer *)fromTimer;
-(void)stopRefreshTimer;
-(void)resetRefreshTimer; 

@end
