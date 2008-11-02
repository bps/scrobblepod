//
//  BGLastFmSubmissionHandshakeResponse.m
//  ApiHubTester
//
//  Created by Ben Gummer on 19/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGLastFmSubmissionHandshakeResponse.h"
#import "NSString+Contains.h"

@implementation BGLastFmSubmissionHandshakeResponse

@synthesize responseLines;
@synthesize statusCode;
@synthesize wasOK;

-(id)initWithData:(NSData *)providedData {
	self = [super init];
	if (self != nil) {
		self.wasOK = NO;
		self.statusCode = SUB_RESP_UNCHECKED;
		NSString *providedString = [[NSString alloc] initWithData:providedData encoding:NSUTF8StringEncoding];
			NSArray *split = [providedString componentsSeparatedByString:@"\n"];
			if (split) self.responseLines = split;
		[providedString release];
		[self determineStatus];
		[self determineError];
	}
	return self;
}

-(void)dealloc {
	self.responseLines = nil;
	[super dealloc];
}

-(void)determineStatus {
	if (responseLines != nil) {
		if ([[responseLines objectAtIndex:0] containsString:@"OK"]) {
			wasOK = YES;
			self.statusCode = SUB_RESP_OK;
		} else {
			wasOK = NO;
			self.statusCode = SUB_RESP_FAILED;
		}
	}
}

-(void)determineError {
	if (responseLines && self.statusCode==SUB_RESP_FAILED) {
		NSString *firstLine = [responseLines objectAtIndex:0];
		if ([firstLine containsString:@"BANNED"]) {
			self.statusCode = SUB_RESP_BANNED;
		} else if ([firstLine containsString:@"BADAUTH"]) {
			self.statusCode = SUB_RESP_BADAUTH;
		} else if ([firstLine containsString:@"BADTIME"]) {
			self.statusCode = SUB_RESP_BADTIME;
		} else if ([firstLine containsString:@"FAILED"]) {
			self.statusCode = SUB_RESP_REALLYFAILED;
		}
	}
}

-(NSString *)sessionKey {
	if (responseLines && self.wasOK) {
		return [[responseLines objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	return nil;
}

-(NSString *)nowPlayingURL {
	if (responseLines && self.wasOK) {
		return [[responseLines objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	return nil;
}

-(NSString *)postURL {
	if (responseLines && self.wasOK) {
		return [[responseLines objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	return nil;
}

@end
