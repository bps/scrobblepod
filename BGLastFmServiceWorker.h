//
//  BGLastFmServiceWorker.h
//  ScrobblePod
//
//  Created by Ben Gummer on 29/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BGLastFmRadioHandshakeResponse.h"
#import "BGLastFmSong.h"

@interface BGLastFmServiceWorker : NSObject {
	NSString *title;
	NSString *artist;
	NSString *album;
	NSString *username;
	NSString *password;
}

-(id)init;

@property (copy) NSString *title;
@property (copy) NSString *artist;
@property (copy) NSString *album;
@property (copy) NSString *username;
@property (copy) NSString *password;

#pragma mark General
-(void)performApiRequestWithXml:(NSString *)theXML;

#pragma mark Love/Ban
-(void)submitTasteCommand:(NSString *)tasteCommand;

#pragma mark Tagging
-(NSString *)methodNameForTagType:(int)tagType;
-(NSArray *)tagsForSong:(BGLastFmSong *)aSong forType:(int)aType;
-(NSString *)tagExtensionForType:(int)tagType;
-(void)tagWithType:(int)tagType forTags:(NSArray *)tagArray;

#pragma mark Recommendations
-(NSArray *)friendsForUser:(NSString *)aUsername;
-(NSString *)methodNameForRecommendationType:(int)recommendationType;
-(void)recommendWithType:(int)recommendType forFriendUsernames:(NSArray *)friendsArray;
-(NSString *)recommendTypeStringFromType:(int)recommendationType;

-(NSData *)dataFromUrl:(NSURL *)theURL;
-(void)acquireCredentials;

-(BGLastFmRadioHandshakeResponse *)performRadioHandshake;

@end
