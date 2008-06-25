//
//  RoundPointView.h
//  PointWindow
//
//  Created by Ben Gummer on 22/04/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RoundPointView : NSView {
	float triangleCenter;
	float triangleHeight;
	float triangleWidth;
	float cornerRadius;
}

@property (assign) float triangleCenter;
@property (assign) float triangleHeight;
@property (assign) float triangleWidth;
@property (assign) float cornerRadius;

@end
