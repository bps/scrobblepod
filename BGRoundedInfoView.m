	#import "BGRoundedInfoView.h"
#import "NSBezierPath+RoundedRect.h"

#pragma mark Fixed Values

#define LeftPadding 34
#define RightPadding 30
#define ScrollAmount 0.5
#define ScrollSpeed 0.01
#define ScrollSpacing 20
#define LineWidth 0.5

#define BlueAmount 2
#define BlueSpeed 0.01

#define blueLimit_On 90.0
#define blueLimit_Off 22.0

#define FadeSpeed 0.05

#define BLUE_STILL 0
#define BLUE_SHRINKING 1
#define BLUE_GROWING 2

@implementation BGRoundedInfoView

@synthesize isResizingBlue;
@synthesize scrollOffset;
@synthesize currentBlueAction;
@synthesize currentLoveHateIconOpacity;
@synthesize blueIsClosed;

#pragma mark Initialisation Methods

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Assign initial values
		[self calculateDrawingBounds];
		self.scrollOffset = 0.0;		
		self.isResizingBlue = NO;
		self.active = NO;
		self.currentBlueAction = BLUE_GROWING;
		self.currentLoveHateIconOpacity = 10;
		self.blueIsClosed = YES;

		// Create Objects Needed Later On
		[self createTextAttributesDictionary];
		gradientFill = [[CTGradient unifiedNormalGradient] retain];
		[self setStringValue:@"BGRoundedView: Please set string"];
		[self createIconSet];		
	}
	return self;
}

-(void)dealloc {
	[self setStringValue:nil];
	[gradientFill release];
	[attributesDictionary release];
	[backgroundImage release];
	[scrollTimer release];
	[blueTimer release];
	[fadeIconTimer release];
	[iconSet release];
	[super dealloc];
}

-(void)createIconSet {
	iconSet = [[NSMutableArray alloc] initWithCapacity:4];
	
	NSImage *heartIcon;
	NSImage *banIcon;
	NSImage *recIcon;
	NSImage *tagIcon;

	heartIcon = [[NSImage imageNamed:@"Love"] copy];
	[self addIconFromImage:heartIcon withSelector:@"loveSong:"];
	[heartIcon release];

	banIcon = [[NSImage imageNamed:@"Ban"] copy];
	[self addIconFromImage:banIcon withSelector:@"banSong:"];		
	[banIcon release];

	recIcon = [[NSImage imageNamed:@"Rec"] copy];
	[self addIconFromImage:recIcon withSelector:@"recommendSong:"];		
	[recIcon release];

	tagIcon = [[NSImage imageNamed:@"Tag"] copy];
	[self addIconFromImage:tagIcon withSelector:@"tagSong:"];		
	[tagIcon release];
}

#pragma mark Last.fm Icons

-(void)addIconFromImage:(NSImage *)theImage withSelector:(NSString *)action {
		NSDictionary *newDictionary = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects:theImage,action,nil]
																  forKeys: [NSArray arrayWithObjects:@"image",@"action",nil] ];
		[iconSet addObject:newDictionary];
}

-(void)createTextAttributesDictionary {
		NSShadow *myShadow;
		myShadow = [[NSShadow alloc] init];
		[myShadow setShadowColor:[NSColor whiteColor]];
		[myShadow setShadowBlurRadius:0.0];
		[myShadow setShadowOffset:NSMakeSize(0,-1)];
		
		currentBlueOffset = drawingBounds.origin.x + drawingBounds.size.width - blueLimit_Off;
		
		attributesDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont fontWithName:@"Helvetica Neue" size:11],myShadow,[NSColor blackColor],nil]
																								forKeys:[NSArray arrayWithObjects:NSFontAttributeName,NSShadowAttributeName,NSForegroundColorAttributeName,nil]];

		[myShadow release];			
		[attributesDictionary retain];
}

-(NSString *)selectorNameForClickOffset:(NSPoint)clickPoint {
	float lastDrawPoint = drawingBounds.origin.x + drawingBounds.size.width - blueLimit_On+7.0;
	int i;
	for (i=0; i<iconSet.count; i++) {
		NSImage *currentIcon = [[iconSet objectAtIndex:i] objectForKey:@"image"];
		float imageWidth = currentIcon.size.width;
		if (clickPoint.x >= lastDrawPoint && clickPoint.x <= lastDrawPoint + imageWidth) return [[iconSet objectAtIndex:i] objectForKey:@"action"];
		lastDrawPoint += imageWidth + 4.0;
	}
	return nil;
}

-(void)mouseEntered:(NSEvent *)theEvent {
	NSLog(@"MOUSE_IN");

}

-(void)mouseExited:(NSEvent *)theEvent {
	NSLog(@"MOUSE_OUT");

}

-(void)mouseMoved: (NSEvent *)theEvent {
NSLog(@"mouseMoved working");
}

#pragma mark Event Tracking

-(void)mouseDown:(NSEvent *)theEvent {
	if (self.active) {
		NSPoint loc = [theEvent locationInWindow];
		loc.x -= [self frame].origin.x;
		loc.y -= [self frame].origin.y;
			
		float startAreaRight = drawingBounds.origin.x+drawingBounds.size.width;
		float startAreaLeft  = startAreaRight - blueLimit_Off;
			
		if (loc.x < startAreaRight && loc.x > startAreaLeft) {
			if (self.currentBlueAction==BLUE_STILL) self.currentLoveHateIconOpacity = (self.blueIsClosed ? 0 : 10);
			(self.blueIsClosed ? [self openBlueMenu] : [self closeBlueMenu]);
		} else {
			NSString *selectorName = [self selectorNameForClickOffset:loc];
			if (selectorName) {
				SEL methodSelector = NSSelectorFromString(selectorName);
				if ([appController respondsToSelector:methodSelector]) [appController performSelector:methodSelector withObject:self];
			}
		
		}
	}
}

-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

-(BOOL)acceptsFirstReponder {
	return YES;
}

#pragma mark Scroll Timer

-(void)startScrollTimer {
	if (!scrollTimer) self.scrollOffset = 0.0;
	[self stopScrollTimer];
	if ([self shouldScroll]) {
		scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:ScrollSpeed target:self selector:@selector(incrementScroll:) userInfo:nil repeats:YES] retain];
		[[NSRunLoop currentRunLoop] addTimer:scrollTimer forMode:NSEventTrackingRunLoopMode];
	}
}

-(void)stopScrollTimer {
	if (scrollTimer!=nil) [scrollTimer invalidate];
	[self setNeedsDisplay:YES];
}

-(void)incrementScroll:(NSTimer *)timer {
	self.scrollOffset -= ScrollAmount;
	if (currentBlueOffset>drawingBounds.origin.x+20) {
	}
	if (self.scrollOffset < [[self stringImage] size].width*-1) self.scrollOffset = ScrollSpacing;
	if (!isResizingBlue) [self setNeedsDisplay:YES];
}

#pragma mark Blue Timer

-(void)resetBlueToOffState {
	self.currentBlueAction = BLUE_STILL;
	self.blueIsClosed = YES;
	[self stopBlueTimer];
	[self stopFadeTimer];
	self.currentLoveHateIconOpacity = 0;
	currentBlueOffset = (drawingBounds.origin.x + drawingBounds.size.width) - blueLimit_Off;
	if (self.window) [self generateBackgroundImage];
	[self setNeedsDisplay:YES];
}

-(void)startBlueTimer {
	if (!isResizingBlue && self.currentBlueAction > BLUE_STILL) {
		[self stopBlueTimer];
		self.isResizingBlue = YES;
		blueTimer = [[NSTimer scheduledTimerWithTimeInterval:BlueSpeed target:self selector:@selector(incrementBlue:) userInfo:nil repeats:YES] retain];
		[[NSRunLoop currentRunLoop] addTimer:blueTimer forMode:NSEventTrackingRunLoopMode];
	}
}

-(void)stopBlueTimer {
	if (blueTimer!=nil) {
		[blueTimer invalidate];
		self.isResizingBlue = NO;
	}
}

-(void)incrementBlue:(NSTimer *)timer {

	if ( (self.currentBlueAction==BLUE_SHRINKING && [self currentBlueWidth]<=blueLimit_Off) || (self.currentBlueAction==BLUE_GROWING && [self currentBlueWidth]>=blueLimit_On) ) {
		[self stopBlueTimer];
		
		// Once drawing finishes, make sure it is on the exact (correct) value
		if (self.currentBlueAction==BLUE_SHRINKING) {
			[self resetBlueToOffState];
			[self startScrollTimer];
		} else if (self.currentBlueAction==BLUE_GROWING) {
			currentBlueOffset = drawingBounds.origin.x + drawingBounds.size.width - blueLimit_On;
			self.blueIsClosed = NO;
		}
		
		self.currentBlueAction = BLUE_STILL;
		
	} else {
		currentBlueOffset += BlueAmount * ( (self.currentBlueAction==BLUE_SHRINKING) ? 1 : -1);
	}
	
	[self generateBackgroundImage];
	[self setNeedsDisplay:YES];
}

#pragma mark Fade Timer

-(void)startFadeTimer {
	[self stopFadeTimer];
	fadeIconTimer = [[NSTimer scheduledTimerWithTimeInterval:FadeSpeed target:self selector:@selector(stepIconOpacity:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:fadeIconTimer forMode:NSEventTrackingRunLoopMode];
}

-(void)stopFadeTimer {
	if (fadeIconTimer!=nil) {
		[fadeIconTimer invalidate];
	}
}

-(void)stepIconOpacity:(NSTimer *)timer {
	if (self.currentBlueAction==BLUE_SHRINKING) {
		self.currentLoveHateIconOpacity -= 1;
		if (self.currentLoveHateIconOpacity <= 0) {
			self.currentLoveHateIconOpacity = 0;
			[self stopFadeTimer];
		}
	} else {
		self.currentLoveHateIconOpacity += 1;
		if (self.currentLoveHateIconOpacity >= 10) {
			self.currentLoveHateIconOpacity = 10;
			[self stopFadeTimer];
		}
	}
	
	if (!self.isResizingBlue) [self setNeedsDisplay:YES];
}

#pragma mark Convenience Blue Methods

-(float)currentBlueWidth {
	return (drawingBounds.origin.x + drawingBounds.size.width) - currentBlueOffset;
}

-(void)openBlueMenu {
	self.blueIsClosed = NO;
	[self startBlueTimerWithDirection:BLUE_GROWING];
}

-(void)closeBlueMenu {
	self.blueIsClosed = YES;
	[self startBlueTimerWithDirection:BLUE_SHRINKING];
}

-(void)startBlueTimerWithDirection:(int)direction {
//	if (!self.isResizingBlue) {
		self.currentBlueAction = direction;
		[self startBlueTimer];
		[self startFadeTimer];
//	}
}

#pragma mark Calculating Regions

-(void)calculateDrawingBounds {
	NSRect tempBounds = [self bounds];
	
	tempBounds.origin.x += LeftPadding;
	tempBounds.size.width -= RightPadding+LeftPadding;
	tempBounds.size.height = 20;
	
	tempBounds.size.width -= LineWidth*2;
	
	tempBounds.size.height -= 2;//2px padding
	
	tempBounds.origin.y = [self bounds].size.height - tempBounds.size.height - tempBounds.origin.y;
	
	tempBounds.origin.x += LineWidth / 2;
	tempBounds.origin.y -= 3*LineWidth;
	
	drawingBounds = tempBounds;
}

#pragma mark Drawing

- (void)drawRect:(NSRect)rect {
	float capWidth = 9.0;
	float textDrawWidth = currentBlueOffset-drawingBounds.origin.x-2;
	NSImage *wholeStringImage = [self stringImage];
	NSImage *cutImage = [[NSImage alloc] initWithSize:NSMakeSize(textDrawWidth,[wholeStringImage size].height)];
	[cutImage lockFocus];
		[wholeStringImage compositeToPoint:NSMakePoint(self.scrollOffset+capWidth,0) operation:1.0];
		if ([self shouldScroll]) {
			float scrollDiff = textDrawWidth - (self.scrollOffset+[wholeStringImage size].width);
			if (scrollDiff > ScrollSpacing) [wholeStringImage compositeToPoint:NSMakePoint(textDrawWidth - scrollDiff + ScrollSpacing + capWidth,0) operation:1.0];
		}
	[cutImage unlockFocus];
	
	[self lockFocus];
		[[self backgroundImage] compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
		[cutImage compositeToPoint:NSMakePoint(drawingBounds.origin.x+((24-(capWidth*2))/2),drawingBounds.origin.y+2) operation:NSCompositeSourceOver];

		if (self.active) {
			NSImage *arrowImage = (self.blueIsClosed ? [NSImage imageNamed:@"BlueArrow_Left"] : [NSImage imageNamed:@"BlueArrow_Right"]);
			[arrowImage compositeToPoint:NSMakePoint(drawingBounds.origin.x+drawingBounds.size.width-(blueLimit_Off/2)-(arrowImage.size.width/2),((drawingBounds.origin.y+drawingBounds.size.height)/2)-(arrowImage.size.height/2)) operation:NSCompositeSourceAtop];
		
			float lastDrawPoint = drawingBounds.origin.x + drawingBounds.size.width - blueLimit_On+7.0;
//			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
			float opacityValue = self.currentLoveHateIconOpacity/10.0;
			if (opacityValue>0.0) { // Fixes strange (but possibly useful) functionality where fraction:0.0 = fraction:1.0
				int i;
				for (i=0; i<iconSet.count; i++) {
					NSImage *currentIcon = [[iconSet objectAtIndex:i] objectForKey:@"image"];
					[currentIcon compositeToPoint:NSMakePoint(lastDrawPoint,3) operation:NSCompositeSourceOver fraction:opacityValue];
					lastDrawPoint += currentIcon.size.width + 4.0;
				}
			}
		}
	[self unlockFocus];
	[cutImage release];
}

- (BOOL)isFlipped {
	return NO;
}

#pragma mark Generating Cached Images

-(NSImage *)backgroundImage {
	if (!backgroundImage) [self generateBackgroundImage];
	return backgroundImage;
}

-(void)generateBackgroundImage {
		if (backgroundImage!=nil) [backgroundImage release];

		NSSize selfSize = [self bounds].size;
	
		backgroundImage = [[NSImage alloc] initWithSize:selfSize];
		
		NSBezierPath *roundedPath = [NSBezierPath bezierPathWithRoundRectInRect:drawingBounds radius:19.5];
		
		NSImage *shineImage = [[NSImage alloc] initWithSize:NSMakeSize(selfSize.width,selfSize.height/2)];
		
		[shineImage lockFocus];
			[[NSColor whiteColor] set];
			[NSBezierPath fillRect:NSMakeRect(0,0,selfSize.width,selfSize.height/2)];
		[shineImage unlockFocus];

		float blueHeight = selfSize.height-2;

		float currentBlueWidth;
		currentBlueWidth = (drawingBounds.origin.x + drawingBounds.size.width) - currentBlueOffset;

		NSImage *blueImage = [[NSImage alloc] initWithSize:NSMakeSize(currentBlueWidth,blueHeight)];
		[blueImage lockFocus];
			[[NSColor colorWithCalibratedRed:(131.0/255.0) green:(175.0/255.0) blue:(234.0/255.0) alpha:1.0] set];
			[NSBezierPath fillRect:NSMakeRect(0,1,currentBlueWidth,blueHeight)];
		[blueImage unlockFocus];
		
		[backgroundImage lockFocus];
			// Draw Background, Blue, Shine
			[gradientFill fillBezierPath:roundedPath angle:90];
			if (self.active) [blueImage drawAtPoint:NSMakePoint(currentBlueOffset,0) fromRect:NSZeroRect operation:NSCompositeSourceAtop fraction:0.9];
			[shineImage drawAtPoint:NSMakePoint(0,selfSize.height/2) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.4];
			
			// Stroke Entire Capsule
			[[NSColor darkGrayColor] set];
			[roundedPath setLineWidth:LineWidth];
			[roundedPath stroke];
			
			// Draw 1px vertical blue divider
			if (self.active) {
				[[NSColor lightGrayColor] set];			
				NSBezierPath *onePixelVericalLine = [NSBezierPath bezierPathWithRect:NSMakeRect(currentBlueOffset, 1,1,drawingBounds.size.height-1)];
				[onePixelVericalLine fill];
			}
		[backgroundImage unlockFocus];
		
		[shineImage release];
		[blueImage release];
}

@synthesize stringImage;

-(NSImage *)stringImage {
	if (!stringImage) [self generateStringImage];
	return stringImage;
}

-(void)generateStringImage {
	NSAttributedString *drawString = [[NSAttributedString alloc] initWithString:self.stringValue attributes:attributesDictionary];
	NSImage *tempImage = [[NSImage alloc] initWithSize:[drawString size]];
	
	[tempImage lockFocus];
		[drawString drawAtPoint:NSZeroPoint];
	[tempImage unlockFocus];
	
	self.stringImage = tempImage;
	[tempImage release];
	[drawString release];
}

#pragma mark Decision To Scroll

-(void)viewDidMoveToWindow {
	[self resetBlueToOffState];
	[self startScrollTimer];
}

-(BOOL)shouldScroll {
	return (self.window && [stringImage size].width > currentBlueOffset - drawingBounds.origin.x - 5);
}

#pragma mark String Value

-(NSString *)stringValue {
	return stringValue;
}

-(void)setStringValue:(NSString *)aString {
	if (aString) {
		if (stringValue) {
			[stringValue release];
			stringValue = nil;
		}
		stringValue = [aString copy];
		self.scrollOffset = 0.0;
		[self generateStringImage];
		[self setNeedsDisplay:YES];
	}
}

-(void)setStringValue:(NSString *)aString isActive:(BOOL)aBool {
	[self setStringValue:aString];
	[self setActive:aBool];
	[self setNeedsDisplay:YES];
}

@synthesize active;
-(void)setActive:(BOOL)aBool {
	active = aBool;
	// If not active, hide blue section
}
@end
