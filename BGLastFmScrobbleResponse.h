//
//  BGLastFmScrobbleResponse.h
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 8/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BGLastFmScrobbleResponse : NSObject {

int responseType;
NSArray *responseLines;
NSDictionary *responseComponents;
NSCalendarDate *lastScrobbleDate;

}

-(id)initWithScrobbleResponseString:(NSString *)aString;
-(NSDictionary *)parseResponse;
-(NSString *)description;

-(void)setWasSuccessful:(BOOL)aBool;
-(BOOL)wasSuccessful;
-(int)responseType;
-(NSString *)failureReason;

-(NSCalendarDate *)lastScrobbleDate;
-(void)setLastScrobbleDate:(NSCalendarDate *)aDate;

@end
