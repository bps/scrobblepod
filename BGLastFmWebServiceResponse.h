//
//  BGLastFmWebServiceResponse.h
//  ApiHubTester
//
//  Created by Ben Gummer on 18/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define WS_RESP_NOFAILURE 0;
#define WS_RESP_GENERICFAILURE 1;
#define WS_RESP_INVALIDSERVICE 2;
#define WS_RESP_INVALIDMETHOD 3;
#define WS_RESP_AUTHFAILED 4;
#define WS_RESP_INVALIDFORMAT 5;
#define WS_RESP_INVALIDPARAMETERS 6;
#define WS_RESP_INVALIDRESOURCE 7;
#define WS_RESP_INVALIDSESSION 9; //need to re-authorize
#define WS_RESP_INVALIDAPIKEY 10;
#define WS_RESP_SERVICEOFFLINE 11;
#define WS_RESP_SUBSCRIBERSONLY 12;
#define WS_RESP_INVALIDTOKEN 14;
#define WS_RESP_TOKENEXPIRED 15;

@interface BGLastFmWebServiceResponse : NSObject {
	NSXMLDocument *responseDocument;
	int lastFmCode;
	BOOL wasOK;
}

@property (retain) NSXMLDocument *responseDocument;
@property (assign) BOOL wasOK;
@property (assign) int lastFmCode;
@property (readonly) BOOL failedDueToInvalidKey;

-(id)initWithData:(NSData *)receivedData;
-(void)dealloc;
-(NSString *)description;
-(void)determineStatus;
-(NSXMLNode *)nodeForXPath:(NSString *)xPath;
-(NSString *)stringValueForXPath:(NSString *)xPath;
-(void)determineErrorCode;

@end
