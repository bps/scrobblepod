//
//  BGMultipleSongPlayManager.h
//  ScrobblePod
//
//  Created by Ben Gummer on 12/06/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BGLastFmSong.h"

@interface BGMultipleSongPlayManager : NSObject {

}

-(NSArray *)completeSongListForRecentTracks:(NSArray *)recentTracks sinceDate:(NSCalendarDate *)theDate;
-(NSString *)pathForCachedDatabase;
-(BOOL)cacheFileExists;

@end