//
//  BGLastFmWebServiceResponse.m
//  ApiHubTester
//
//  Created by Ben Gummer on 18/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGLastFmWebServiceResponse.h"

@implementation BGLastFmWebServiceResponse

@synthesize responseDocument;
@synthesize wasOK;
@synthesize lastFmCode;

-(id)initWithData:(NSData *)receivedData {
	self = [super init];
	if (self != nil) {
		self.wasOK = NO;
		self.lastFmCode = WS_RESP_GENERICFAILURE;
		if (receivedData) {
			self.lastFmCode = WS_RESP_NOFAILURE;
			self.responseDocument = [[NSXMLDocument alloc] initWithData:receivedData options:NSXMLDocumentTidyXML error:nil];
			[self determineStatus];
		} else NSLog(@"Init with 0-length data");
	}
	return self;
}

-(void)dealloc {
	self.responseDocument = nil;
	[super dealloc];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"Call Worked: %d; Error code: %d",self.wasOK,self.lastFmCode];
}

-(void)determineStatus {
	if (self.responseDocument != nil) {
		self.wasOK = [[self stringValueForXPath:@"/lfm/@status"] isEqualToString:@"ok"];
		NSLog(@"Status: %@",(self.wasOK ? @"OK" : @"FAILED"));
		
		if (!self.wasOK) {
			[self determineErrorCode];
		}
	}
}

-(void)determineErrorCode {
	if (self.responseDocument != nil) {
		self.lastFmCode = [[self stringValueForXPath:@"/lfm/error/@code"] intValue];
		if (self.lastFmCode>0) NSLog(@"Error Code: %d",self.lastFmCode);
	}
}

-(int)lastFmCode {
	if (!self.wasOK) {
		return lastFmCode;
	}
	return WS_RESP_NOFAILURE;
}

-(NSXMLNode *)nodeForXPath:(NSString *)xPath {
	NSXMLNode *tempNode = [[self.responseDocument nodesForXPath:xPath error:nil] lastObject];
	if (tempNode) return tempNode;
	return nil;
}

-(NSString *)stringValueForXPath:(NSString *)xPath {
	NSXMLNode *tempNode = [self nodeForXPath:xPath];
	if (tempNode) return [tempNode stringValue];
	return nil;
}

-(BOOL)failedDueToInvalidKey {
	return self.lastFmCode == WS_RESP_INVALIDSESSION;
}

@end
