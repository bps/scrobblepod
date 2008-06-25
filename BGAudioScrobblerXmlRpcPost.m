//
//  BGAudioScrobblerXmlRpcPost.m
//  ScrobblePod
//
//  Created by Ben Gummer on 24/04/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGAudioScrobblerXmlRpcPost.h"
#import "BGAudioScrobblerXmlRpcParameter.h"
#import "CocoaCryptoHashing.h"

@implementation BGAudioScrobblerXmlRpcPost

@synthesize methodName;

- (id) init
{
	self = [super init];
	if (self != nil) {
		postParameters = [NSMutableArray new];
	}
	return self;
}

- (void) dealloc
{
	[postParameters release];
	[super dealloc];
}

-(void)addPostParameter:(id)theParameter {
	BGAudioScrobblerXmlRpcParameter *postParameter = [[BGAudioScrobblerXmlRpcParameter alloc] initWithParameter:theParameter];
		[postParameters addObject:postParameter];
	[postParameter release];
}

-(NSArray *)postParameters {
	return postParameters;
}

-(NSString *)challengeFromPassword:(NSString *)aPass andTimestamp:(NSString *)aTime {
	return [[NSString stringWithFormat:@"%@%@",[aPass md5HexHash],aTime] md5HexHash];
}

-(void)addAuthParametersWithUsername:(NSString *)aUsername andPassword:(NSString *)aPassword {

	NSString *timestamp = [self timestamp];
	NSString *challenge = [self challengeFromPassword:aPassword andTimestamp:timestamp];

	[self addPostParameter:aUsername];
	[self addPostParameter:timestamp];
	[self addPostParameter:challenge];
}

-(NSString *)timestamp {
	return [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]];
}

-(NSString *)xmlDescription {
	NSMutableString *xmlString = [NSMutableString stringWithCapacity:300];
	[xmlString appendFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><methodCall><methodName>%@</methodName><params>",methodName];
	int i;
	for (i = 0; i < postParameters.count; i++) {
		[xmlString appendString:[[postParameters objectAtIndex:i] xmlDescription]];
	}
	[xmlString appendString:@"</params></methodCall>"];
	return xmlString;
}

@end
