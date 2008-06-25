//
//  GrowlHub.h
//  ScrobblePod
//
//  Created by Ben Gummer on 22/05/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>

@interface GrowlHub : NSObject <GrowlApplicationBridgeDelegate> {

}

+(GrowlHub *)sharedManager;
+(id)allocWithZone:(NSZone *)zone;
-(id)copyWithZone:(NSZone *)zone;
-(id)retain;
- (unsigned)retainCount;
-(void)release;
-(id)autorelease;

-(id)init;

-(NSDictionary *)registrationDictionaryForGrowl;
-(void)postGrowlNotificationWithName:(NSString *)postName andTitle:(NSString *)postTitle andDescription:(NSString *)postDescription andImage:(NSData *)postImage andIdentifier:(NSString *)postIdentifier;

@end
