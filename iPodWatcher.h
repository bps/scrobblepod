//
//  iPodWatcher.h
//  ScrobblePod
//
//  Created by Ben Gummer on 20/02/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface iPodWatcher : NSObject {

}

+(iPodWatcher *)sharedManager;
+(id)allocWithZone:(NSZone *)zone;
-(id)copyWithZone:(NSZone *)zone;
-(id)retain;
-(unsigned)retainCount;
-(void)release;
-(id)autorelease;

- (id)init;

-(void)applyForMobileDeviceNotifications;
-(void)amdsDidConnect:(NSNotification*)note;
-(void)amdsDidFail:(NSNotification*)note;

-(void)applyForiPodNotifications;
-(BOOL)isPodAtPath:(NSString *)testPath;

-(BOOL)iPodDisconnectedSinceDate:(NSDate *)testDate;
-(void)updateLastSyncDateWithNotification:(BOOL)shouldNotify;
-(void)setLastSynched:(NSDate *)aDate;

@end
