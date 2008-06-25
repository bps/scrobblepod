//
//  BGTimelineGap.m
//  MultiPlayTest
//
//  Created by Ben Gummer on 11/06/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGTimelineGap.h"


@implementation BGTimelineGap

@synthesize startTime;
@synthesize endTime;
@synthesize duration;

-(int)duration {
	return self.endTime - self.startTime;
}

@end
