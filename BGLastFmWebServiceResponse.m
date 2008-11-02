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
@synthesize translatedCode;

-(id)initWithData:(NSData *)receivedData {
	self = [super init];
	if (self != nil) {
		self.wasOK = NO;
		self.lastFmCode = WS_RESP_GENERICFAILURE;
		if (receivedData) {
			self.lastFmCode = WS_RESP_NOFAILURE;
			self.responseDocument = [[NSXMLDocument alloc] initWithData:receivedData options:NSXMLDocumentTidyXML error:nil];
			[self determineStatus];
		}
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
		self.translatedCode = [self constantErrorCodeFromResponseCode:self.lastFmCode];
		NSLog(@"Error Code: %d",self.translatedCode);
	}
}

-(int)lastFmCode {
	if (!self.wasOK) {
		return lastFmCode;
	}
	return WS_RESP_NOFAILURE;
}


-(int)translatedCode {
	if (!self.wasOK) {
		return translatedCode;
	}
	return WS_RESP_NOFAILURE;
}

-(int)constantErrorCodeFromResponseCode:(int)responseCode {
	int returnCode;
	switch (responseCode) {
		case 2:
			returnCode = WS_RESP_INVALIDSERVICE;
			break;
		case 3:
			returnCode = WS_RESP_INVALIDMETHOD;
			break;
		case 4:
			returnCode = WS_RESP_AUTHFAILED;
			break;
		case 5:
			returnCode = WS_RESP_INVALIDFORMAT;
			break;
		case 6:
			returnCode = WS_RESP_INVALIDPARAMETERS;
			break;
		case 7:
			returnCode = WS_RESP_INVALIDRESOURCE;
			break;
		case 9:
			returnCode = WS_RESP_INVALIDSESSION;
			break;
		case 10:
			returnCode = WS_RESP_INVALIDAPIKEY;
			break;
		case 11:
			returnCode = WS_RESP_SERVICEOFFLINE;
			break;
		case 12:
			returnCode = WS_RESP_SUBSCRIBERSONLY;
			break;
		case 14:
			returnCode = WS_RESP_INVALIDTOKEN;
			break;
		case 15:
			returnCode = WS_RESP_TOKENEXPIRED;
			break;
		default:
			returnCode = WS_RESP_GENERICFAILURE;
			break;
	}
	return returnCode;
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

@end
