//
//  BGLastFmAuthenticationManager.h
//  ApiHubTester
//
//  Created by Ben Gummer on 18/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol AuthDelegate

-(void)newWebServiceSessionKeyAcquired;
-(void)newSubmissionSessionKeyAcquired;

@end


@interface BGLastFmAuthenticationManager : NSObject {
	id delegate;
}

@property (readonly) NSString *webServiceSessionKey;
@property (readonly) NSString *submissionSessionKey;
@property (readonly) NSString *username;
@property (readonly) NSString *nowPlayingSubmissionURL;
@property (readonly) NSString *scrobbleSubmissionURL;
@property (assign) id delegate;

-(id)initWithDelegate:(id)sender;
-(void)beginNewWebServiceSessionProcedure;
-(void)fetchNewSubmissionSessionKeyUsingWebServiceSessionKey;

@end
