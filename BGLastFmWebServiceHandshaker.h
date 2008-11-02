//
//  BGLastFmWebServiceHandshaker.h
//  ApiHubTester
//
//  Created by Ben Gummer on 17/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BGLastFmWebServiceHandshaker : NSObject {

}


-(void)openAuthorizationSite;
+(NSString *)fetchSessionKeyUsingToken:(NSString *)theToken;

@end