//
//  BGLastFmSubmissionHandshaker.h
//  ApiHubTester
//
//  Created by Ben Gummer on 17/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BGLastFmSubmissionHandshakeResponse.h"

@interface BGLastFmSubmissionHandshaker : NSObject {

}

-(BGLastFmSubmissionHandshakeResponse *)performSubmissionHandshakeForUser:(NSString *)username withWebServiceSessionKey:(NSString *)wsSessionKey;

@end
