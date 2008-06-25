//
//  BGPointWindow.m
//  PointWindow
//
//  Created by Ben Gummer on 22/04/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "BGPointWindow.h"

@implementation BGPointWindow

@synthesize shouldClose;

-(id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if (![super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag]) return nil;
	[self setBackgroundColor:[NSColor clearColor]];
	[self setOpaque:NO];
	[self setLevel:NSStatusWindowLevel+1];
	[self setHasShadow:YES];
	[self setDelegate:self];
	[self setShouldClose:YES];
	return self;
}

-(void)awakeFromNib {
	// Register for Fadeout end notifications
	CAAnimation *anim = [CABasicAnimation animation];
	[anim setDelegate:self];
	[self setAnimations:[NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag 
{
    if (self.alphaValue == 0.00) [self properClose]; //detect end of fade out and close the window
}

-(BOOL)canBecomeKeyWindow {
	return YES;
}

-(BOOL)canBecomeMainWindow {
	return YES;
}

-(void)windowDidResignKey:(NSNotification *)notification {
	if (self.shouldClose) [self close:self];
}

-(IBAction)close:(id)sender {
	if (self.isVisible) [self.animator setAlphaValue:0.0];
}

-(void)properClose {
	[super close];
}

-(void)positionAtMenuBarForHorizontalValue:(float)xVal andVerticalValue:(float)yVal {
	float windowWidth = [self.contentView frame].size.width;
	float screenWidth = [[NSScreen mainScreen] frame].size.width;
	float overflow = screenWidth - (xVal + windowWidth);
	if (overflow < 0.0) {
		overflow -= 20;
		xVal += overflow;
		float currentCenter = [[self contentView] triangleCenter];
		[self.contentView setTriangleCenter:currentCenter - overflow];
	}
	[self setFrameOrigin:NSMakePoint(xVal,yVal)];
	self.alphaValue = 1.0f;
}

@end
