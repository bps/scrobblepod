//
//  iPodWatcher.m
//  ScrobblePod
//
//  Created by Ben Gummer on 21/04/07.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "iPodWatcher.h"
#import "Defines.h"

@implementation iPodWatcher

static iPodWatcher *sharedPodWatcher = nil;

+(iPodWatcher *)sharedManager {
	@synchronized(self) {
		if (sharedPodWatcher == nil) {
			[[self alloc] init]; // assignment not done here
		}
	}
	return sharedPodWatcher;
}

+(id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedPodWatcher == nil) {
			sharedPodWatcher = [super allocWithZone:zone];
			return sharedPodWatcher;  // assignment and return on first allocation
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
 
-(unsigned)retainCount {
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
		
		NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
		[notificationCenter addObserver:self selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];

	}
	return self;
}

-(void)volumeDidMount:(NSNotification *)notification { 
	NSString *mountedDevicePath = [[notification userInfo] objectForKey:@"NSDevicePath"];
	if ([self isPodAtPath:mountedDevicePath]) {
		NSLog(@"MOUNTED iPod: %@",mountedDevicePath);
		[self setLastSynched:[NSDate date]];
		[[NSNotificationCenter defaultCenter] postNotificationName:BGNotificationPodMounted object:nil];
	}
}

-(BOOL)isPodAtPath:(NSString *)testPath {
	return (testPath!=nil && [[NSFileManager defaultManager] fileExistsAtPath:[testPath stringByAppendingPathComponent:@"iPod_Control"]]);
}

-(void)volumeDidUnmount:(NSNotification *)notification { 

}

-(void)setLastSynched:(NSDate *)aDate {
	[[NSUserDefaults standardUserDefaults] setObject:aDate forKey:BGLastSyncDate];
}

-(void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	[super dealloc];
}

-(BOOL)iPodDisconnectedSinceDate:(NSDate *)testDate {
	NSDate *lastDate = [[NSUserDefaults standardUserDefaults] objectForKey:BGLastSyncDate];
	if (lastDate) return ([lastDate compare:testDate]==NSOrderedDescending);
	return NO;
}

@end