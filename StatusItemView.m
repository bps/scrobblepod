//
//  StatusItemView.m
//  Statz
//
//  Created by Dave MacLachlan on 2007/11/30.
//  Copyright 2007 Google Inc. All rights reserved.
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License.  You may obtain a copy
// of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations under
// the License.
//

#import <Carbon/Carbon.h>
#import "StatusItemView.h"

@implementation StatusItemView

-(id)initWithStatusItem:(NSStatusItem *)item {
	NSRect frame = NSMakeRect(0, 0, [item length], 21);
	if ((self = [super initWithFrame:frame])) {
		statusItem = item;
	}
	return self;
}

- (void)dealloc {
	[image release];
	[alternateImage release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
	[statusItem drawStatusBarBackgroundInRect:rect withHighlight:selected];
	NSImage *imageToUse = nil;
	if (selected && alternateImage) {
		imageToUse = alternateImage;
	} else {
		imageToUse = image;
	}
	NSSize imageSize = [imageToUse size];
	NSRect imageRect = NSMakeRect(0, 0, imageSize.width, imageSize.height);
	[imageToUse drawAtPoint:NSMakePoint(5,3) fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0f];
}

- (void)mouseDown:(NSEvent *)theEvent {
	[self setSelected:YES];
	[target performSelector:action withObject:self];
}

-(void)setSelected:(BOOL)aBool {
	if (selected != aBool) {
		selected = aBool;
		[self setNeedsDisplay:YES];
	}
}

-(void)setImage:(NSImage *)anImage {
	if (image != nil) [image release];
	image = [anImage retain];
	[self setNeedsDisplay:YES];
}

@synthesize image;
@synthesize alternateImage;
@synthesize target;
@synthesize action;
    
@end