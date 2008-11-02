//
//  BGLastFmWebServiceCaller.h
//  ApiHubTester
//
//  Created by Ben Gummer on 18/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BGLastFmWebServiceParameterList.h"
#import "BGLastFmWebServiceResponse.h"

@interface BGLastFmWebServiceCaller : NSObject {

}

-(BGLastFmWebServiceResponse *)callWithParameters:(BGLastFmWebServiceParameterList *)theParameters usingPostMethod:(BOOL)postBool;

@end
