//
//  BGTrackCollector.h
//  ScrobblePod
//
//  Created by Ben on 13/01/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BGTrackCollector : NSObject {

}
-(NSMutableArray *)collectTracksFromXMLFile:(NSString *)xmlPath withCutoffDate:(NSDate *)cutoffDate includingPodcasts:(BOOL)includePodcasts includingVideo:(BOOL)includeVideo ignoringComment:(NSString *)ignoreString ignoringGenre:(NSString *)genreString withMinimumDuration:(int)minimumDuration;
@end
