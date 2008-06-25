//
//  BGAudioScrobblerXmlRpcParameter.m
//  ScrobblePod
//
//  Created by Ben Gummer on 24/04/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGAudioScrobblerXmlRpcParameter.h"


@implementation BGAudioScrobblerXmlRpcParameter

@synthesize parameter;

-(id)initWithParameter:(id)aParam {
	self = [super init];
	if (self != nil) {
		self.parameter = aParam;
	}
	return self;
}

-(void)dealloc
{
	self.parameter = nil;
	[super dealloc];
}


-(NSString *)xmlDescription {
	if ([[parameter className] isEqualToString:@"NSCFString"]) {
		return [NSString stringWithFormat:@"<param><value><string>%@</string></value></param>",parameter];
	} else if ([[parameter className] isEqualToString:@"NSCFArray"]) {
		NSMutableString *outputString = [NSMutableString stringWithCapacity:200];
		[outputString appendString:@"<param><value><array><data>"];
		int i;
		for (i = 0; i < [parameter count]; i++) {
			[outputString appendFormat:@"<value><string>%@</string></value>",[parameter objectAtIndex:i]];
		}
		[outputString appendString:@"</data></array></value></param>"];
		return outputString;
	}
	
	// Otherwise
	NSLog(@"BGAudioScrobblerXmlRpcParameter: Unexpected Parameter Type: %@",[parameter className]);
	return @"ERROR";
}

@end
