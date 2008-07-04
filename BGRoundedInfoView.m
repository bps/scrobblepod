#import "BGRoundedInfoView.h"
#import "NSBezierPath+RoundedRect.h"
#import "BGScrobbleDecisionManager.h"

#pragma mark Fixed Values

#define LeftPadding 18
#define RightPadding 30
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
@synthesize currentBlueAction;
@synthesize currentLoveHateIconOpacity;
@synthesize blueIsClosed;

@synthesize scrobblingEnabled;
@synthesize scrobblingAuto;

#pragma mark Initialisation Methods

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Assign initial values
		[self calculateDrawingBounds];
		self.isResizingBlue = NO;
		self.active = NO;
		self.currentBlueAction = BLUE_GROWING;
		self.currentLoveHateIconOpacity = 10;
		self.blueIsClosed = YES;

		self.scrobblingEnabled = NO;
		self.scrobblingAuto = YES;

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
	[blueTimer release];
	[fadeIconTimer release];
	[statusChangeTimer release];
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

#pragma mark Event Tracking

-(void)mouseDown:(NSEvent *)theEvent {
	NSPoint loc = [theEvent locationInWindow];
	loc.x -= [self frame].origin.x;
	loc.y -= [self frame].origin.y;

	if (loc.x > drawingBounds.origin.x && loc.x < drawingBounds.origin.x+15) {
		[self closeBlueMenu];
		BGScrobbleDecisionManager *decisionMaker = [BGScrobbleDecisionManager sharedManager];
		BOOL oldAutomaticScrobblingDecision = [decisionMaker shouldScrobbleAuto];
		if (decisionMaker.isDecisionMadeAutomtically) { //Changing from auto to manual
			decisionMaker.isDecisionMadeAutomtically = NO;
			decisionMaker.usersManualChoice = !oldAutomaticScrobblingDecision;
			[self setTemporaryHoverStringValue:(decisionMaker.usersManualChoice ? @"Scrobbling is now ON" : @"Scrobbling is now OFF")];
		} else {
			// If you want to see the logic that thse 2 lines replace, email me. Basically, they replace
			// an inefficient series of "if" selectors, saving 10-15 lines of code.
			decisionMaker.usersManualChoice = !decisionMaker.usersManualChoice;
			decisionMaker.isDecisionMadeAutomtically = oldAutomaticScrobblingDecision ^ decisionMaker.usersManualChoice; //XOR
			[self setTemporaryHoverStringValue:(decisionMaker.isDecisionMadeAutomtically ? @"Scrobbling is set automatically" : (decisionMaker.usersManualChoice ? @"Scrobbling is now ON" : @"Scrobbling is now OFF"))];
		}
		[self generateStatusImage];
		[self generateBackgroundImage];
		[self setNeedsDisplay:YES];
	} else if (self.active) {
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

#pragma mark Status Change Timer

-(void)startStatusChangeTimer {
	[self stopStatusChangeTimer];
	statusChangeTimer = [[NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(revertFromHoverToStringValue:) userInfo:nil repeats:NO] retain];
	[[NSRunLoop currentRunLoop] addTimer:statusChangeTimer forMode:NSEventTrackingRunLoopMode];
}

-(void)stopStatusChangeTimer {
	if (statusChangeTimer!=nil) {
		[statusChangeTimer invalidate];
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
	float textDrawWidth = (self.active ? currentBlueOffset-drawingBounds.origin.x : drawingBounds.size.width);
	NSImage *wholeStringImage = [self stringImage];
	NSImage *cutImage = [[NSImage alloc] initWithSize:NSMakeSize(textDrawWidth,[wholeStringImage size].height)];
	[cutImage lockFocus];
		[wholeStringImage compositeToPoint:NSMakePoint(22,0) operation:1.0];
	[cutImage unlockFocus];
	
	[self lockFocus];
		[[self backgroundImage] compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
		[cutImage compositeToPoint:NSMakePoint(drawingBounds.origin.x,(drawingBounds.size.height/2)-([cutImage size].height/2)+1) operation:NSCompositeSourceOver];

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

		NSImage *blueImage;
		blueImage = [[NSImage alloc] initWithSize:NSMakeSize(currentBlueWidth,blueHeight)];
		[blueImage lockFocus];
			[[NSColor colorWithCalibratedRed:(131.0/255.0) green:(175.0/255.0) blue:(234.0/255.0) alpha:1.0] set];
			[NSBezierPath fillRect:NSMakeRect(0,1,currentBlueWidth,blueHeight)];
		[blueImage unlockFocus];
		
		[backgroundImage lockFocus];
			// Draw Background, Blue, Shine
			[gradientFill fillBezierPath:roundedPath angle:90];
			if (self.active) [blueImage drawAtPoint:NSMakePoint(currentBlueOffset,0) fromRect:NSZeroRect operation:NSCompositeSourceAtop fraction:0.9];
			[self.statusImage drawAtPoint:NSMakePoint(LeftPadding,0) fromRect:NSZeroRect operation:NSCompositeSourceAtop fraction:0.4];
			[shineImage drawAtPoint:NSMakePoint(0,selfSize.height/2) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.4];
			
			// Stroke Entire Capsule
			[[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] set];
			[roundedPath setLineWidth:LineWidth];
			[roundedPath stroke];
			
			// Draw 1px vertical blue divider
			if (self.active) {
				[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
				NSBezierPath *onePixelVericalLine = [NSBezierPath bezierPathWithRect:NSMakeRect(currentBlueOffset, 1,1,drawingBounds.size.height-1)];
				[onePixelVericalLine fill];
			}

			[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
			NSBezierPath *onePixelVericalLineTwo = [NSBezierPath bezierPathWithRect:NSMakeRect(LeftPadding+15, 1,1,drawingBounds.size.height-1)];
			[onePixelVericalLineTwo fill];

		[backgroundImage unlockFocus];
		
		[shineImage release];
		[blueImage release];
}

@synthesize stringImage;
@synthesize statusImage;

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

-(NSImage *)statusImage {
	if (!statusImage) [self generateStatusImage];
	return statusImage;
}

-(void)generateStatusImage {
	NSImage *tempImage = [[NSImage alloc] initWithSize:NSMakeSize(15,drawingBounds.size.height)];
	
	BGScrobbleDecisionManager *decisionMaker = [BGScrobbleDecisionManager sharedManager];
	NSColor *statusColor;
	statusColor = ( [decisionMaker shouldScrobble] ? [NSColor greenColor] : [NSColor redColor] );

	[tempImage lockFocus];
		[statusColor set];
		[NSBezierPath fillRect:NSMakeRect(0,1,15,drawingBounds.size.height)];
		if (decisionMaker.isDecisionMadeAutomtically) {
			float yellowOffset = 0.0;
			float yellowWidth = 15.0;
			float yellowHeight = 7.0;
			[[NSColor yellowColor] set];
			[NSBezierPath fillRect:NSMakeRect(yellowOffset,drawingBounds.size.height-yellowHeight,yellowWidth,yellowHeight)];
//			[[NSColor darkGrayColor] set];
//			[NSBezierPath fillRect:NSMakeRect(0,drawingBounds.size.height-yellowHeight-1,yellowWidth,1)];
		}
	[tempImage unlockFocus];
	
	self.statusImage = tempImage;
	[tempImage release];
}

#pragma mark View Being Shown

-(void)viewDidMoveToWindow {
	[self resetBlueToOffState];
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
		[self generateStringImage];
		[self setNeedsDisplay:YES];
	}
}

-(void)setStringValue:(NSString *)aString isActive:(BOOL)aBool {
	[self setActive:aBool];
	self.stringValue = aString;
	self.properStringValue = aString;
}

@synthesize active;
-(void)setActive:(BOOL)aBool {
	active = aBool;
	// If not active, hide blue section
}

@synthesize properStringValue;

-(void)setTemporaryHoverStringValue:(NSString *)aString {
//	NSString *originalValue = [[self.stringValue copy] autorelease];
//	NSTimer *revertTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(revertFromHoverToStringValue:) userInfo:nil repeats:NO];
//	[[NSRunLoop currentRunLoop] addTimer:revertTimer forMode:NSEventTrackingRunLoopMode];
	[self startStatusChangeTimer];
	self.stringValue = aString;
}

-(void)revertFromHoverToStringValue:(NSTimer*)theTimer {
	self.stringValue = self.properStringValue;
}
@end
