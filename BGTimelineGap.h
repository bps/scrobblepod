//
//  BGTimelineGap.h
//  MultiPlayTest
//
//  Created by Ben Gummer on 11/06/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BGTimelineGap : NSObject {
	int startTime;
	int endTime;
}

@property (assign) int startTime;
@property (assign) int endTime;
@property (readonly) int duration;

@end
