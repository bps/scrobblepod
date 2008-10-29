//
//  iPodWatcher.m
//  ScrobblePod
//
//  Created by Ben Gummer on 21/04/07.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "iPodWatcher.h"
#import "Defines.h"

#import "MobileDeviceSupport.h" // MobileDeviceSupport class taken from iScrobbler source

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

-(void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	[super dealloc];
}

-(id)init {
	self = [super init];
	if (self != nil) {
		[self applyForiPodNotifications];
		[self applyForMobileDeviceNotifications];
	}
	return self;
}

#pragma mark iPhone Methods

-(void)amdsDidConnect:(NSNotification*)note {
	NSLog(@"Mobile Device Connected: %@", [[note userInfo] objectForKey:@"product"]);
	[self updateLastSyncDateWithNotification:YES];
}

-(void)amdsDidFail:(NSNotification*)note {
    NSLog(@"iPhone Detection Initialization error occured");
}

-(void)applyForMobileDeviceNotifications {
	char *path = "/System/Library/PrivateFrameworks/MobileDevice.framework/MobileDevice";
	int err;
	if (0 != (err = IntializeMobileDeviceSupport(path, NULL))) {
		NSLog(@"iPhone Detection Initialization error occured");
	} else {		
		NSLog(@"iPhone/iPod Touch Detection Enabled");
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(amdsDidConnect:) name:@"org.bergstrand.amds.connect" object:nil];		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(amdsDidFail:) name:@"org.bergstrand.amds.intializeDidFail" object:nil];
	}
}

#pragma mark iPod Methods

-(void)applyForiPodNotifications {
	NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notificationCenter addObserver:self selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
}

-(void)volumeDidMount:(NSNotification *)notification { 
	NSString *mountedDevicePath = [[notification userInfo] objectForKey:@"NSDevicePath"];
	if ([self isPodAtPath:mountedDevicePath]) {
		NSLog(@"MOUNTED iPod: %@",mountedDevicePath);
		[self updateLastSyncDateWithNotification:YES];
	}
}

-(BOOL)isPodAtPath:(NSString *)testPath {
	return (testPath!=nil && ([[NSFileManager defaultManager] fileExistsAtPath:[testPath stringByAppendingPathComponent:@"iPod_Control"]] || [[NSFileManager defaultManager] fileExistsAtPath:[testPath stringByAppendingPathComponent:@"iTunes_Control"]] || [[NSFileManager defaultManager] fileExistsAtPath:[testPath stringByAppendingPathComponent:@"var/root/Media/iTunes_Control"]]));
}

-(void)volumeDidUnmount:(NSNotification *)notification { 

}

#pragma mark Management Methods

-(void)updateLastSyncDateWithNotification:(BOOL)shouldNotify {
	[self setLastSynched:[NSDate date]];
	if (shouldNotify) [[NSNotificationCenter defaultCenter] postNotificationName:BGNotificationPodMounted object:nil];
}

-(void)setLastSynched:(NSDate *)aDate {
	[[NSUserDefaults standardUserDefaults] setObject:aDate forKey:BGLastSyncDate];
}

-(BOOL)iPodDisconnectedSinceDate:(NSDate *)testDate {
	NSDate *lastDate = [[NSUserDefaults standardUserDefaults] objectForKey:BGLastSyncDate];
	if (lastDate) return ([lastDate compare:testDate]==NSOrderedDescending);
	return NO;
}

@end