//
//  NSDictionary+Exclusiontest.m
//  ScrobblePod
//
//  Created by Ben Gummer on 22/05/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "NSDictionary+ExclusionTest.h"


@implementation NSDictionary (ExclusionTest)

-(BOOL)passesExclusionTestWithCutoffDate:(NSDate *)cutoffDate includingPodcasts:(BOOL)includingPodcasts includingVideo:(BOOL)includeVideo ignoringComment:(NSString *)ignoreString withMinimumDuration:(int)minimumDuration {
	NSDate *playDate = [self objectForKey:@"Play Date UTC"];
	BOOL shouldIncludeTrack;
	shouldIncludeTrack = YES;
	if ([cutoffDate compare:playDate]==NSOrderedAscending) {
		if (!includingPodcasts && [[self objectForKey:@"Podcast"] boolValue]) shouldIncludeTrack = NO; // include podcasts? //(wantPodcastCheckbox.state==NSOffState)
		if (shouldIncludeTrack && !includeVideo && [[self objectForKey:@"Has Video"] boolValue]) shouldIncludeTrack = NO; // include video? //(wantVideoCheckbox.state==NSOffState)
		if (shouldIncludeTrack && (ignoreString!=nil) && ([[self objectForKey:@"Comments"] rangeOfString:ignoreString].length>0)) shouldIncludeTrack = NO; // ignore commented? //(ignoreCommentedCheckbox.state==NSOnState)
		if (shouldIncludeTrack && (minimumDuration > 0) && (minimumDuration > (int)[[self objectForKey:@"Total Time"] intValue]/1000)) shouldIncludeTrack = NO; // minimum track length? //(minimumDurationCheckbox.state==NSOnState)
	} else {
		shouldIncludeTrack = NO;
	}
	
	return shouldIncludeTrack;

}

@end
