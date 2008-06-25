//
//  WhitePopUpButton.m
//  White Circle Buttons
//
//  Created by John Devor on 12/21/06.
//

#import "WhitePopUpButton.h"

#define VERTICAL_OFFSET 3.0

@implementation WhitePopUpButton

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self setButtonType:NSMomentaryChangeButton];
		[self setBordered:NO];
	}
	return self;
}

- (BOOL)isFlipped
{
	return NO;
}

- (void)drawRect:(NSRect)rect
{
	NSSize imageSize = [[NSImage imageNamed:@"CircleButton"] size];
	id currentTitle = [[self selectedItem] title];
	
	[[NSImage imageNamed:@"CircleButton"] compositeToPoint:NSMakePoint(0, VERTICAL_OFFSET) 
												  fromRect:NSMakeRect(0, 0, imageSize.width / 2.0, imageSize.height)
												 operation:NSCompositeSourceOver];
	
	
	[[NSImage imageNamed:@"CircleButton"] drawInRect:NSMakeRect(imageSize.width / 2.0, VERTICAL_OFFSET, rect.size.width - imageSize.width, imageSize.height)
											fromRect:NSMakeRect(imageSize.width / 2.0 - 0.25, 0, 0.5, imageSize.height) 
										   operation:NSCompositeSourceOver
											fraction:1.0];
	
	
	[[NSImage imageNamed:@"CircleButton"] compositeToPoint:NSMakePoint(rect.size.width - imageSize.width / 2.0, VERTICAL_OFFSET)
												  fromRect:NSMakeRect(imageSize.width / 2.0, 0, imageSize.width / 2.0, imageSize.height)
												 operation:NSCompositeSourceOver];
	
	
	[currentTitle drawAtPoint:NSMakePoint(11, 5)
			   withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSForegroundColorAttributeName, [NSFont systemFontOfSize:11], NSFontAttributeName, NULL]];
	
	[[NSImage imageNamed:@"PopupArrows"] compositeToPoint:NSMakePoint(rect.size.width - 12, 7)
												operation:NSCompositeSourceOver];
}
	
@end
