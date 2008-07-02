//
//  BGScrobbleDecisionManager.m
//  ScrobblePod
//
//  Created by Ben Gummer on 15/05/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGScrobbleDecisionManager.h"
#import "Defines.h"
#import "iPodWatcher.h"
#import "GrowlHub.h"

@implementation BGScrobbleDecisionManager

static BGScrobbleDecisionManager *sharedDecisionManager = nil;

+(BGScrobbleDecisionManager *)sharedManager {
	@synchronized(self) {
		if (sharedDecisionManager == nil) {
			[[self alloc] init]; // assignment not done here
		}
	}
	return sharedDecisionManager;
}

+(id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedDecisionManager == nil) {
			sharedDecisionManager = [super allocWithZone:zone];
			return sharedDecisionManager;  // assignment and return on first allocation
		}
	}
	return nil; //on subsequent allocation attempts return nil
}

-(id)copyWithZone:(NSZone *)zone {
	return self;
}

-(id)retain {
	return self;
}

- (unsigned)retainCount {
	return UINT_MAX;  //denotes an object that cannot be released
}
 
-(void)release {
	//do nothing
}
 
-(id)autorelease {
	return self;
}

-(id)init {
	self = [super init];
	if (self != nil) {
		firstRefresh = YES;
		self.isDecisionMadeAutomtically = YES;
		self.usersManualChoice = NO;
		[self shouldScrobble];
		[self startRefreshTimer];
	}
	return self;
}

- (void) dealloc
{
	[self stopRefreshTimer];
	[super dealloc];
}


#pragma mark Decision Making

-(BOOL)shouldScrobble {
	self.cachedOverallDecision = (self.isDecisionMadeAutomtically ? [self shouldScrobbleAuto] : self.usersManualChoice );
	return self.cachedOverallDecision;
}

-(BOOL)shouldScrobbleAuto {
	BOOL shouldScrobbleAuto = YES;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:BGPrefUsePodFreshnessInterval]) {
		NSDate *testDate = [[NSDate alloc] initWithTimeIntervalSinceNow: ([[NSUserDefaults standardUserDefaults] integerForKey:BGPrefPodFreshnessInterval]*-3600) ];
		shouldScrobbleAuto = [[iPodWatcher sharedManager] iPodDisconnectedSinceDate:testDate];
		[testDate release];
	}
	
	self.cachedOverallDecision = shouldScrobbleAuto;
	return self.cachedOverallDecision;
}

#pragma mark Refreshing Cache

@synthesize cachedOverallDecision;
@synthesize isDecisionMadeAutomtically;
@synthesize usersManualChoice;

-(void)refreshDecisionAndNotifyIfChanged:(BOOL)notify {
	BOOL oldDecision = self.cachedOverallDecision;
	BOOL newDecision = [self shouldScrobble];
	if (notify && (firstRefresh || oldDecision != newDecision)) {
	
		NSString *descriptionString;
		if (newDecision == YES) {
			// if user enables the 3-hour (default) time limit, then work out how long there is left until scrobbling is disabled
			if ([[NSUserDefaults standardUserDefaults] boolForKey:BGPrefUsePodFreshnessInterval]) {
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				NSDate *lastSyncDate = [defaults objectForKey:BGLastSyncDate];
				NSCalendarDate *lastSyncCalDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:[lastSyncDate timeIntervalSinceReferenceDate]];
				int minutesToAdd = (int)([[defaults stringForKey:BGPrefPodFreshnessInterval] floatValue]*60.0);
				NSCalendarDate *cutoffDate = [lastSyncCalDate dateByAddingYears:0 months:0 days:0 hours:0 minutes:minutesToAdd seconds:0];
				NSString *dateDescription = [cutoffDate descriptionWithCalendarFormat:@"%I:%M%p"];
				descriptionString = [NSString stringWithFormat:@"Tracks played in iTunes will be scrobbled until %@",dateDescription];
			} else { // decision is yes, and is always on. we will always scrobble tracks.
				descriptionString = @"Tracks played in iTunes will be scrobbled when they are played";
			}
		} else { // decision is no, so we will not scrobble anything until an iPod is connect
			descriptionString = @"Tracks played in iTunes will not be scrobbled until an iPod is connected";
		}
		[[GrowlHub sharedManager] postGrowlNotificationWithName:SP_Growl_DecisionChanged
													   andTitle:(newDecision ? @"Scrobbling Enabled" : @"Scrobbling Disabled")
											     andDescription:descriptionString
													   andImage:nil
												  andIdentifier:SP_Growl_DecisionChanged];


	}
	self.cachedOverallDecision = newDecision;
	firstRefresh = NO;
}

#pragma mark Timer

-(void)startRefreshTimer {
	[self stopRefreshTimer];
	float hoursEntered = [[[NSUserDefaults standardUserDefaults] stringForKey:BGPrefPodFreshnessInterval] floatValue];
	int secondsCalculated = (int)(hoursEntered*3600.0);
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:secondsCalculated target:self selector:@selector(refreshFromTimer:) userInfo:nil repeats:YES];
}

-(void)refreshFromTimer:(NSTimer *)fromTimer {
	[self refreshDecisionAndNotifyIfChanged:YES];
}

-(void)stopRefreshTimer {
	if (refreshTimer) [refreshTimer invalidate];
}

-(void)resetRefreshTimer {
	[self startRefreshTimer];
}

@end
