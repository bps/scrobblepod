#import "PreferencesController.h"
#import "SFHFKeychainUtils.h"
#import "Defines.h"
#import "iPodWatcher.h"
#import <Security/Security.h>
#import <QuartzCore/CoreAnimation.h>
#import "UKLoginItemRegistry.h"
#import "BGLastFMPasswordChecker.h"

#define maxItems 10 // Cutoff for history items

@implementation PreferencesController

#pragma mark WindowController Methods

- (id) init {
	self = [super initWithWindowNibName:@"Preferences"];
	if (self != nil) {
	}
	return self;
}

- (void)windowDidLoad {
//	[self.window setLevel:NSModalPanelWindowLevel]; // Disabled since 0.51 preview 3
	[self.window center];
	[self.window setShowsToolbarButton:NO];
	
	NSImageCell *theCell = [[NSImageCell alloc] init];
		[historyIconTableColumn setDataCell:theCell];
	[theCell release];
	
	[startAtLogin setState:([UKLoginItemRegistry indexForLoginItemWithPath:[[NSBundle mainBundle] bundlePath]]+1)];
	
	self.window.contentView = generalPrefsView;
//	[self setPreferencesView:generalPrefsView];
	
	SecKeychainItemRef itemRef;
	NSString *currentPassword = [SFHFKeychainUtils getWebPasswordForUser: [[NSUserDefaults standardUserDefaults] valueForKey:BGPrefUserKey] URL: [NSURL URLWithString:@"http://www.last.fm/"] domain:@"Last.FM Login"  itemReference: &itemRef];
	if (currentPassword!=nil) {
		[lastFmPass setStringValue:currentPassword];
	}
}

- (NSString *)windowNibName {
	return @"Preferences";
}

- (IBAction)showWindow:(id)sender {
	[self.window setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
	if (![self.window isVisible]) {
		[prefToolbar setVisible:NO];
		[self changeView:generalPrefsToolbarItem];
	}
	[super showWindow:self];
	[NSApp activateIgnoringOtherApps:YES];
	[prefToolbar setVisible:YES];
}

#pragma mark Toolbar

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    return YES;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	
	NSMutableArray *theArray = [NSMutableArray new];
	NSToolbarItem *currentItem;
	for (currentItem in [toolbar items]) {
		[theArray addObject:currentItem.itemIdentifier];
	}
	[theArray autorelease];
	return theArray;
}

#pragma mark Changing Views

-(IBAction)changeView:(NSToolbarItem *)sender {
	[prefToolbar setSelectedItemIdentifier:sender.itemIdentifier];
	if ([sender tag]==1) {
		[self setPreferencesView:generalPrefsView];
	} else if ([sender tag]==3) {
		[self setPreferencesView:lastfmPrefsView];
	} else if ([sender tag]==4) {
		[self setPreferencesView:exclusionsView];
	} else if ([sender tag]==6) {
		[self setPreferencesView:historyView];
	}
}

-(void)setPreferencesView:(NSView *)inputView {
	if (self.window.contentView != inputView) {
		NSRect windowRect = self.window.frame;
		
		float newHeight = inputView.frame.size.height;		
		int difference = newHeight - [self.window.contentView frame].size.height;
		windowRect.origin.y -= difference;
		windowRect.size.height += difference;
		
		difference = inputView.frame.size.width - [self.window.contentView frame].size.width;
		windowRect.origin.x -= difference/2;
		windowRect.size.width += difference;

		[inputView setHidden:YES];
		[self.window.contentView setHidden:YES];
		[self.window setContentView:inputView];
		[self.window setFrame:windowRect display:YES animate:YES];
		[inputView setHidden: NO];
	}
}

#pragma mark Pane:General Methods

-(IBAction)startChooseXML:(id)sender {
	NSOpenPanel * panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:NO];

	[panel beginSheetForDirectory:[@"~/Music/iTunes/" stringByExpandingTildeInPath]
		file:@"iTunes Music Library.xml"
		types:[NSArray arrayWithObject:@"xml"]
		modalForWindow:self.window
		modalDelegate:self
		didEndSelector:@selector(filePanelDidEnd: returnCode: contextInfo:)
		contextInfo:nil];
}

- (void)filePanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[panel orderOut:nil];
	if (returnCode == NSOKButton) [[NSUserDefaults standardUserDefaults] setObject:[panel filename] forKey:BGPrefXmlLocation];
}

-(IBAction)setLoginStart:(id)sender {
	if ([sender state]==NSOnState) {
		[UKLoginItemRegistry addLoginItemWithPath:[[NSBundle mainBundle] bundlePath] hideIt:NO];
	} else {
		[UKLoginItemRegistry removeLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
	}
}

-(IBAction)updateAutoDecision:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:BGNotificationPodMounted object:nil];
}

#pragma mark Pane:LastFm Methods

-(IBAction)openLastFmWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.last.fm/join/"]];
}

-(IBAction)checkEnteredCredentials:(id)sender {
	[checkCredentialsButton setEnabled:NO];
	[NSThread detachNewThreadSelector:@selector(checkCredentialsOnSeparateThread) toTarget:self withObject:nil];
}

-(void)checkCredentialsOnSeparateThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	BGLastFMPasswordChecker *passChecker = [[BGLastFMPasswordChecker alloc] init];
	[passCheckStatusDisplay setStringValue:@"Checking login details..."];
	[passCheckIndicator startAnimation:self];
	if ([passChecker checkCredentialsWithUsername:[lastFmUser stringValue] andPassword:[lastFmPass stringValue]]) {			
		[passCheckStatusDisplay setStringValue:@"Login successful"];
		[SFHFKeychainUtils addWebPassword:[lastFmPass stringValue] forUser:[lastFmUser stringValue] URL: [[NSURL alloc] initWithString:@"http://www.last.fm/"] domain:@"Last.FM Login"];

		// Post login changed notification so that cached handshake key is reset
		[[NSNotificationCenter defaultCenter] postNotificationName:BGLoginChangedNotification object:nil];
	} else {
		NSBeep();
		[passCheckStatusDisplay setStringValue:@"Login incorrect"];
	}
	[passChecker release];
	[passCheckIndicator stopAnimation:self];

	[checkCredentialsButton setEnabled:YES];

	[pool release];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
	if ([aNotification object]==lastFmUser) { // fill in password field from keychain
		SecKeychainItemRef itemRef;
		NSString *currentPassword = [SFHFKeychainUtils getWebPasswordForUser: lastFmUser.stringValue URL: [NSURL URLWithString:@"http://www.last.fm/"] domain:@"Last.FM Login"  itemReference: &itemRef];
		if (currentPassword!=nil) {
			[lastFmPass setStringValue:currentPassword];
		}
	}
}

#pragma mark Pane:History Methods

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return NO;
}

-(void)addHistoryWithSuccess:(BOOL)wasSuccess andDate:(NSDate *)aDate andDescription:(NSString *)aDescription {
	NSDictionary *theDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:wasSuccess],@"success",aDate,@"date",aDescription,@"comment",nil];
	NSMutableArray *newArray;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	newArray = [[defaults arrayForKey:@"ActivityHistory"] mutableCopy];
	if (!newArray) newArray = [NSMutableArray new];
	[newArray insertObject:theDict atIndex:0];
	
	int numberOfItems = newArray.count;
	if (numberOfItems>maxItems && maxItems<numberOfItems) {
		NSRange removeRange = NSMakeRange(maxItems,numberOfItems-maxItems);
		[newArray removeObjectsAtIndexes: [NSIndexSet indexSetWithIndexesInRange:removeRange] ];
	}
	
	[defaults setObject:newArray forKey:@"ActivityHistory"];
	[newArray release];
}

@end