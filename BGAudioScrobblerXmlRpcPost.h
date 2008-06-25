//
//  BGAudioScrobblerXmlRpcPost.h
//  ScrobblePod
//
//  Created by Ben Gummer on 24/04/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BGAudioScrobblerXmlRpcPost : NSObject {
	NSString *methodName;
	NSMutableArray *postParameters;
}

@property (copy) NSString *methodName;
-(NSString *)challengeFromPassword:(NSString *)aPass andTimestamp:(NSString *)aTime;
-(NSArray *)postParameters;
-(void)addPostParameter:(id)theParameter;
-(void)addAuthParametersWithUsername:(NSString *)aUsername andPassword:(NSString *)aPassword;
-(NSString *)xmlDescription;
-(NSString *)timestamp;

@end
