//
//  BGLastFmScrobbler.h
//  LastFmProtocolTester
//
//  Created by Ben Gummer on 8/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BGLastFmScrobbleResponse.h"


@interface BGLastFmScrobbler : NSObject {

}

-(BGLastFmScrobbleResponse *)performScrobbleWithSongs:(NSArray *)songList andSessionKey:(NSString *)theSessionKey toURL:(NSURL *)postURL;

@end
