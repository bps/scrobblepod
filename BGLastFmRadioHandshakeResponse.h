//
//  BGLastFmHandshakeResponse.h
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 8/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BGLastFmRadioHandshakeResponse : NSObject {
	NSArray *responseLines;
	NSMutableDictionary *responseComponents;
	int responseType;
}

-(id)initWithHandshakeResponseString:(NSString *)aString;
-(NSDictionary *)parseResponse;
-(NSString *)description;

-(NSString *)sessionKey;
-(BOOL)didFail;
-(int)responseType;
-(NSString *)failureReason;
-(NSString *)baseURL;

-(void)setDidFail:(BOOL)aBool;

@end
