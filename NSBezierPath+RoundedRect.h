//
//  NSBezierPath+RoundedRect.h
//  BGRoundedInfoView
//
//  Created by Ben Gummer on 9/02/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSBezierPath(RoundedRectangle)

/**
	Returns a closed bezier path describing a rectangle with curved corners
	The corner radius will be trimmed to not exceed half of the lesser rectangle dimension.
*/
+ (NSBezierPath*)bezierPathWithRoundRectInRect:(NSRect)aRect radius:(float)radius;

@end
