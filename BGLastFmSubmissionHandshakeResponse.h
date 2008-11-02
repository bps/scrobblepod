//
//  BGLastFmSubmissionHandshakeResponse.h
//  ApiHubTester
//
//  Created by Ben Gummer on 19/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SUB_RESP_UNCHECKED 0
#define SUB_RESP_OK 1
#define SUB_RESP_FAILED 2
#define SUB_RESP_BANNED 3
#define SUB_RESP_BADAUTH 4
#define SUB_RESP_BADTIME 5
#define SUB_RESP_REALLYFAILED 6

@interface BGLastFmSubmissionHandshakeResponse : NSObject {
	NSArray *responseLines;
	int statusCode;
	BOOL wasOK;
}

@property (retain) NSArray *responseLines;
@property (assign) int statusCode;
@property (assign) BOOL wasOK;

-(id)initWithData:(NSData *)providedData;
-(void)dealloc;
-(void)determineStatus;
-(void)determineError;

@property (readonly) NSString *sessionKey;
@property (readonly) NSString *postURL;
@property (readonly) NSString *nowPlayingURL;

@end
