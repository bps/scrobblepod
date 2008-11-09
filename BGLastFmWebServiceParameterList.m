//
//  BGLastFmWebServiceParameterList.m
//  ApiHubTester
//
//  Created by Ben Gummer on 18/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGLastFmWebServiceParameterList.h"
#import "HubStrings.h"
#import "CocoaCryptoHashing.h"

@implementation BGLastFmWebServiceParameterList

-(id)initWithMethod:(NSString *)aMethod andSessionKey:(NSString *)aSk {
	self = [super init];
	if (self != nil) {
		parameters = [[NSMutableDictionary dictionary] retain];
		[self setParameter:API_KEY forKey:@"api_key"];
		[self setParameter:aMethod forKey:@"method"];
		if (aSk!=nil) [self setParameter:aSk forKey:@"sk"];
	}
	return self;
}

-(void)dealloc {
	[parameters release];
	[super dealloc];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"Parameters for %@:\n%@",[self parameterForKey:@"method"],parameters];
}

-(void)setParameter:(NSString *)theParameter forKey:(NSString *)theKey {
	[parameters setValue:theParameter forKey:theKey];
}

-(NSString *)parameterForKey:(NSString *)theKey {
	return [parameters objectForKey:theKey];
}

-(NSString *)methodSignature {
	[self resetSessionKeyValue];

	NSMutableString *stringSoup = [[NSMutableString alloc] init];
	
	NSArray *sortedParameterKeys = [[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	NSString *key;
	for (key in sortedParameterKeys) {
		[stringSoup appendString:key];
		[stringSoup appendString:[parameters valueForKey:key]];
	}
	[stringSoup appendString:API_SECRET];

	NSString *methodSignatureHash = [stringSoup md5HexHash];
	
	[stringSoup release];
	return methodSignatureHash;
}

-(NSString *)concatenatedParametersString {
	[self resetSessionKeyValue];

	NSMutableArray *parameterPairs = [[NSMutableArray alloc] initWithCapacity:parameters.count];
	NSString *key;
	for (key in parameters) {
		[parameterPairs addObject:[NSString stringWithFormat:@"%@=%@",key,[parameters valueForKey:key]]];
	}
	
	NSString *finalJoinedString = [parameterPairs componentsJoinedByString:@"&"];
	[parameterPairs release];
	
	return finalJoinedString;
}

-(void)resetSessionKeyValue {
	[self setParameter:[[NSUserDefaults standardUserDefaults] stringForKey:BGWebServiceSessionKey] forKey:@"sk"];
}

@end
