//
//  BGLastFmHandshaker.h
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 8/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BGLastFmHandshakeResponse.h"

@interface BGLastFmHandshaker : NSObject {

}

-(BGLastFmHandshakeResponse *)performHandshakeWithUsername:(NSString *)theUsername usingApiSessionKey:(NSString *)apiSessionKey;

@end
