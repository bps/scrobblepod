//
//  BGPointWindow.h
//  PointWindow
//
//  Created by Ben Gummer on 22/04/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RoundPointView.h"
#import <QuartzCore/CoreAnimation.h>


@interface BGPointWindow : NSWindow {
	BOOL shouldClose;
	IBOutlet NSMenu *theMenu;
}

@property (assign) BOOL shouldClose;

-(id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;
-(void)positionAtMenuBarForHorizontalValue:(float)xVal andVerticalValue:(float)yVal;
-(IBAction)close:(id)sender;
-(void)properClose;

@end
