//
//  BGLastFmWebServiceParameterList.h
//  ApiHubTester
//
//  Created by Ben Gummer on 18/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BGLastFmWebServiceParameterList : NSObject {
	NSMutableDictionary *parameters;
}

-(id)initWithMethod:(NSString *)aMethod andSessionKey:(NSString *)aSk;
-(void)dealloc;

-(NSString *)parameterForKey:(NSString *)theKey;
-(void)setParameter:(NSString *)theParameter forKey:(NSString *)theKey;

-(NSString *)methodSignature;
-(NSString *)concatenatedParametersString;

-(void)resetSessionKeyValue;

@end
