#import "BGRoundedInfoView.h"
#import "NSBezierPath+RoundedRect.h"
#import "BGScrobbleDecisionManager.h"
#import "Defines.h"

#pragma mark Fixed Values

#define LeftPadding 38//18+30
#define RightPadding 30
#define LineWidth 0.5

#define BlueAmount 2
#define BlueSpeed 0.01

#define ScrollAmount 1
#define ScrollSpeed 0.05

#define blueLimit_On 90.0
#define blueLimit_Off 22.0

#define FadeSpeed 0.05

#define BLUE_STILL 0
#define BLUE_SHRINKING 1
#define BLUE_GROWING 2

#define drawHeight 18.0
#define shineHeight 10.0

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
		
		self.hoveredIcon = -1;
		self.pressedIcon = -1;
		
		currentScrollOffset = 0.0;

		// Create Objects Needed Later On
		[self createTextAttributesDictionary];
		gradientFill = [[CTGradient unifiedNormalGradient] retain];
		[self setStringValue:@"BGRoundedView: Please set string"];
		[self createIconSet];		
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decisionChangedNotificationReceived:) name:BGScrobbleDecisionChangedNotification object:nil];
	}
	return self;
}

- (BOOL)acceptsFirstResponder { return YES; }

-(void)dealloc {
	[self setStringValue:nil];
	[gradientFill release];
	[attributesDictionary release];
	[backgroundImage release];
	[blueTimer release];
	[fadeIconTimer release];
	[statusChangeTimer release];
	[iconSet release];
	[scrollTimer invalidate];
	[super dealloc];
}

-(void)decisionChangedNotificationReceived:(NSNotification *)notification {
	[self generateStatusImage];
	if ([self window]) {
		[self setNeedsDisplay:YES];
	}
}

-(void)createIconSet {
	iconSet = [[NSMutableArray alloc] initWithCapacity:4];
	
	NSImage *heartIcon;
	NSImage *banIcon;
	NSImage *recIcon;
	NSImage *tagIcon;

	heartIcon = [[NSImage imageNamed:@"Love"] copy];
	[self addIconFromImage:heartIcon withSelector:@"loveSong:" andDescription:@"Love this song"];
	[heartIcon release];

	banIcon = [[NSImage imageNamed:@"Ban"] copy];
	[self addIconFromImage:banIcon withSelector:@"banSong:" andDescription:@"Ban this song"];		
	[banIcon release];

	recIcon = [[NSImage imageNamed:@"Rec"] copy];
	[self addIconFromImage:recIcon withSelector:@"recommendSong:" andDescription:@"Share this song"];		
	[recIcon release];

	tagIcon = [[NSImage imageNamed:@"Tag"] copy];
	[self addIconFromImage:tagIcon withSelector:@"tagSong:" andDescription:@"Tag this song"];		
	[tagIcon release];
}

#pragma mark Last.fm Icons

-(void)addIconFromImage:(NSImage *)theImage withSelector:(NSString *)action andDescription:(NSString *)aDescription {
		NSDictionary *newDictionary = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects:theImage,action,aDescription,nil]
																  forKeys: [NSArray arrayWithObjects:@"image",@"action",@"description",nil] ];
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
	if (clickPoint.y >= 0 && clickPoint.y <= 20) {
		float lastDrawPoint = drawingBounds.origin.x + drawingBounds.size.width - blueLimit_On+7.0;
		int i;
		for (i=0; i<iconSet.count; i++) {
			NSImage *currentIcon = [[iconSet objectAtIndex:i] objectForKey:@"image"];
			float imageWidth = currentIcon.size.width;
			if (clickPoint.x >= lastDrawPoint && clickPoint.x <= lastDrawPoint + imageWidth) return [[iconSet objectAtIndex:i] objectForKey:@"action"];
			lastDrawPoint += imageWidth + 4.0;
		}
	}
	return nil;
}

-(NSString *)descriptionForClickOffset:(NSPoint)clickPoint {
	if (clickPoint.y >= 0 && clickPoint.y <= 20) {
		float lastDrawPoint = drawingBounds.origin.x + drawingBounds.size.width - blueLimit_On+7.0;
		int i;
		for (i=0; i<iconSet.count; i++) {
			NSImage *currentIcon = [[iconSet objectAtIndex:i] objectForKey:@"image"];
			float imageWidth = currentIcon.size.width;
			if (clickPoint.x >= lastDrawPoint && clickPoint.x <= lastDrawPoint + imageWidth) {
				return [[iconSet objectAtIndex:i] objectForKey:@"description"];
			}
			lastDrawPoint += imageWidth + 4.0;
		}
	}
	return nil;
}

-(int)indexForClickOffset:(NSPoint)clickPoint {
	if (clickPoint.y >= 0 && clickPoint.y <= 20) {
		float lastDrawPoint = drawingBounds.origin.x + drawingBounds.size.width - blueLimit_On+7.0;
		int i;
		for (i=0; i<iconSet.count; i++) {
			NSImage *currentIcon = [[iconSet objectAtIndex:i] objectForKey:@"image"];
			float imageWidth = currentIcon.size.width;
			if (clickPoint.x >= lastDrawPoint && clickPoint.x <= lastDrawPoint + imageWidth) return i;
			lastDrawPoint += imageWidth + 4.0;
		}
	}
	return -1;
}

@synthesize hoveredIcon;

#pragma mark Event Tracking

@synthesize pressedIcon;

-(void)mouseDown:(NSEvent *)theEvent {
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	if (loc.x > 15 && loc.x < 40) {
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
				self.pressedIcon = [self indexForClickOffset:loc];
				self.hoveredIcon = self.pressedIcon;
				[self setNeedsDisplay:YES];
				SEL methodSelector = NSSelectorFromString(selectorName);
				if ([appController respondsToSelector:methodSelector]) {
					[appController performSelector:methodSelector withObject:self];
					[[NSRunLoop currentRunLoop] addTimer:[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(resetPressedIcon:) userInfo:nil repeats:NO] forMode:NSEventTrackingRunLoopMode];
				}
			}
		
		}
	}
}

-(void)resetPressedIcon:(NSTimer *)theTimer {
	self.pressedIcon = -1;
	[self setNeedsDisplay:YES];
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
	self.hoveredIcon = -1;
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
			[[self window] setAcceptsMouseMovedEvents:NO];
		} else if (self.currentBlueAction==BLUE_GROWING) {
			currentBlueOffset = drawingBounds.origin.x + drawingBounds.size.width - blueLimit_On;
			self.blueIsClosed = NO;
			[[self window] setAcceptsMouseMovedEvents:YES];
		}
		
		self.currentBlueAction = BLUE_STILL;
		
	} else {
		currentBlueOffset += BlueAmount * ( (self.currentBlueAction==BLUE_SHRINKING) ? 1 : -1);
	}
	
	[self generateBackgroundImage];
	[self setNeedsDisplay:YES];
}

-(void)mouseMoved:(NSEvent *)theEvent {
	NSPoint thePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSString *theString = [self descriptionForClickOffset:thePoint];
	self.hoveredIcon = [self indexForClickOffset:thePoint];
	if (theString) [self setTemporaryHoverStringValue:theString];
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
	statusChangeTimer = [[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(revertFromHoverToStringValue:) userInfo:nil repeats:NO] retain];
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
	tempBounds.size.height = drawHeight;
	
	tempBounds.size.width -= LineWidth*2;
	
	tempBounds.size.height -= 2;//2px padding
	
	tempBounds.origin.y = 5;
	tempBounds.origin.x += LineWidth / 2;
	tempBounds.origin.x -= 2;
	
	drawingBounds = tempBounds;
}

#pragma mark Drawing

- (void)drawRect:(NSRect)rect {
	float textWidth = (self.active ? currentBlueOffset-drawingBounds.origin.x-2 : drawingBounds.size.width-2);

	NSImage *primaryStringImage = [self stringImageWithWidth:textWidth andOffset:currentScrollOffset-2];//autoreleased
	float currentPrimaryDrawPoint = drawingBounds.origin.x + 2.0;
	
	[self lockFocus];
		[[self backgroundImage] compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
		
		float yDrawPoint = (drawingBounds.size.height/2)-(primaryStringImage.size.height/2)+1;
		[primaryStringImage compositeToPoint:NSMakePoint(currentPrimaryDrawPoint, yDrawPoint) operation:NSCompositeSourceAtop];
		if ([self shouldScroll]) {
			NSImage *secondaryStringImage = [self stringImageWithWidth:textWidth andOffset:currentScrollOffset - stringImage.size.width - 20];//autoreleased
			[secondaryStringImage compositeToPoint:NSMakePoint(currentPrimaryDrawPoint, yDrawPoint) operation:NSCompositeSourceOver];
		}

		if (self.active) {
			NSImage *arrowImage = (self.blueIsClosed ? [NSImage imageNamed:@"BlueArrow_Left"] : [NSImage imageNamed:@"BlueArrow_Right"]);
			[arrowImage compositeToPoint:NSMakePoint(drawingBounds.origin.x+drawingBounds.size.width-(blueLimit_Off/2)-(arrowImage.size.width/2),(drawHeight/2)-(arrowImage.size.height/2)) operation:NSCompositeSourceAtop];
		
			float lastDrawPoint = drawingBounds.origin.x + drawingBounds.size.width - blueLimit_On+7.0;
//			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
			float opacityValue = self.currentLoveHateIconOpacity/10.0;
			if (opacityValue>0.0) { // Fixes strange (but possibly useful) functionality where fraction:0.0 = fraction:1.0
				int i;
				for (i=0; i<iconSet.count; i++) {
					NSImage *currentIcon;
					BOOL wasCopied = NO;
					if (self.hoveredIcon==i) {
						wasCopied = YES;
						currentIcon = [[[iconSet objectAtIndex:i] objectForKey:@"image"] copy];
						NSImage *overlayColor = [[NSImage alloc] initWithSize:currentIcon.size];
						[overlayColor lockFocus];
							[(self.pressedIcon == i ? [NSColor blackColor] : [NSColor whiteColor]) set];
							NSRectFill(NSMakeRect(0,0,currentIcon.size.width,currentIcon.size.height));
						[overlayColor unlockFocus];
						
						[currentIcon lockFocus];
							[overlayColor compositeToPoint:NSZeroPoint operation:NSCompositeSourceAtop fraction:0.3];
						[currentIcon unlockFocus];
						
						[overlayColor release];
					} else {
						currentIcon = [[iconSet objectAtIndex:i] objectForKey:@"image"];
					}
					
					[currentIcon compositeToPoint:NSMakePoint(lastDrawPoint,3) operation:NSCompositeSourceOver fraction:opacityValue];

					lastDrawPoint += currentIcon.size.width + 4.0;
					if (wasCopied) [currentIcon release];
				}
			}
		}
	[self unlockFocus];
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
		float drawWidth = self.bounds.size.width;
		backgroundImage = [[NSImage alloc] initWithSize:NSMakeSize(drawWidth, drawHeight)];
		
		NSRect roundedFrame;
		roundedFrame.origin.x = 37;
		roundedFrame.origin.y = 0;
		roundedFrame.origin.y += LineWidth;
		roundedFrame.size.height = drawHeight;
		roundedFrame.size.width = drawWidth-roundedFrame.origin.x-30;
		roundedFrame.size.height -= LineWidth*2;
		roundedFrame.size.width -= LineWidth*2;
		
		NSBezierPath *roundedPath = [NSBezierPath bezierPathWithRoundRectInRect:roundedFrame radius:drawHeight-0.5];
		
		NSImage *shineImage = [[NSImage alloc] initWithSize:NSMakeSize(drawWidth,shineHeight)];
		
		[shineImage lockFocus];
			[[NSColor whiteColor] set];
			[NSBezierPath fillRect:NSMakeRect(0,0,drawWidth,drawHeight)];
		[shineImage unlockFocus];

		float blueHeight = drawHeight-1;

		float currentBlueWidth;
		currentBlueWidth = (drawingBounds.origin.x + drawingBounds.size.width) - currentBlueOffset;

		NSImage *blueImage;
		blueImage = [[NSImage alloc] initWithSize:NSMakeSize(currentBlueWidth,blueHeight)];
		[blueImage lockFocus];
			[[NSColor colorWithCalibratedRed:(131.0/255.0) green:(175.0/255.0) blue:(234.0/255.0) alpha:1.0] set];
			[NSBezierPath fillRect:NSMakeRect(1,1,currentBlueWidth,blueHeight)];
		[blueImage unlockFocus];
		
		[backgroundImage lockFocus];
				
			// Draw Background, Blue, Shine
			[gradientFill fillBezierPath:roundedPath angle:90];
			if (self.active) [blueImage drawAtPoint:NSMakePoint(currentBlueOffset,0) fromRect:NSZeroRect operation:NSCompositeSourceAtop fraction:0.9];
			[self.statusImage drawAtPoint:NSMakePoint(19,(drawHeight/2) - (self.statusImage.size.height/2)) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
			[shineImage drawAtPoint:NSMakePoint(0,shineHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.4];
			
			// Stroke Entire Capsule
			[[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] set];
			[roundedPath setLineWidth:LineWidth];
			[roundedPath stroke];
			
			// Draw 1px vertical blue divider
			if (self.active) {
				[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
				NSBezierPath *onePixelVericalLine = [NSBezierPath bezierPathWithRect:NSMakeRect(currentBlueOffset, 1,1,drawHeight-2)];
				[onePixelVericalLine fill];
			}

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

-(NSImage *)stringImageWithWidth:(float)theWidth andOffset:(float)theOffset {
	if (!stringImage) [self generateStringImage];
	NSImage *returnImage = [[NSImage alloc] initWithSize:NSMakeSize(theWidth, stringImage.size.height)];
	[returnImage lockFocus];
		[stringImage compositeToPoint:NSMakePoint(0-theOffset+6, 0) operation:NSCompositeSourceOver];
	[returnImage unlockFocus];	
	return [returnImage autorelease];
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
	NSImage *tempImage;
	
	BGScrobbleDecisionManager *decisionMaker = [BGScrobbleDecisionManager sharedManager];
	if ([decisionMaker isDecisionMadeAutomtically]) {
		tempImage = [decisionMaker shouldScrobble] ? [NSImage imageNamed:@"auto1"] : [NSImage imageNamed:@"auto0"];
	} else {
		tempImage = [decisionMaker shouldScrobble] ? [NSImage imageNamed:@"1"] : [NSImage imageNamed:@"0"];
	}

	self.statusImage = tempImage;
}

#pragma mark View Being Shown

-(void)viewDidMoveToWindow {
	[self resetBlueToOffState];
	[self startScrolling];
}

#pragma mark Scrolling

-(void)startScrolling {
	currentScrollOffset = 0.0;
	[self stopScrolling];
	if ([self shouldScroll]) {
		scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:ScrollSpeed target:self selector:@selector(incrementScroll:) userInfo:nil repeats:YES] retain];
		[[NSRunLoop currentRunLoop] addTimer:scrollTimer forMode:NSEventTrackingRunLoopMode];
	}
	[self setNeedsDisplay:YES];
}

-(void)stopScrolling {
	if (scrollTimer!=nil) {
		[scrollTimer invalidate];
		[self setNeedsDisplay:YES];
	}
}

-(void)incrementScroll:(NSTimer *)timer {
	currentScrollOffset += ScrollAmount;
	if (drawingBounds.origin.x - currentScrollOffset + stringImage.size.width < 18) currentScrollOffset = 0.0;
	[self setNeedsDisplay:YES];
}

-(BOOL)shouldScroll {
	return (drawingBounds.size.width-44 < self.stringImage.size.width);
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
		[self startScrolling];
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
	[self startStatusChangeTimer];
	self.stringValue = aString;
}

-(void)revertFromHoverToStringValue:(NSTimer*)theTimer {
	self.stringValue = self.properStringValue;
}
@end
