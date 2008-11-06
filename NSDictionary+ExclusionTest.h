//
//  NSDictionary+ExclusionTest.h
//  ScrobblePod
//
//  Created by Ben Gummer on 22/05/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDictionary (ExclusionTest)

-(BOOL)passesExclusionTestWithCutoffDate:(NSDate *)cutoffDate includingPodcasts:(BOOL)includingPodcasts includingVideo:(BOOL)includeVideo ignoringComment:(NSString *)ignoreString ignoringGenre:(NSString *)genreString withMinimumDuration:(int)minimumDuration;

@end
