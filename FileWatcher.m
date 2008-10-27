#import "FileWatcher.h"
#import "Defines.h"

#define POLL_INTERVAL 60.0

@implementation FileWatcher

-(id)init {
	self = [super init];
	if (self != nil) {
		self.lastModificationDate = [NSDate date];
		[self updateLocationFlag];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xmlLocationChanged:) name:BGXmlLocationChangedNotification object:nil];
	}
	return self;
}

-(void)dealloc {
	self.lastModificationDate = nil;
	[self stopWatchingXMLFile];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark General Methods

@synthesize xmlFileIsLocal;

-(void)xmlLocationChanged:(NSNotification *)notification {
	NSLog(@"XML Location Changed: %@",[self fullXmlPath]);
	[self stopWatchingXMLFile];
	[self updateLocationFlag];
	[self startWatchingXMLFile];
	[self postXMLChangeMessage];
}

-(NSString *)fullXmlPath {
	return [[[NSUserDefaults standardUserDefaults] stringForKey:BGPrefXmlLocation] stringByExpandingTildeInPath];
}

-(void)updateLocationFlag {
	BOOL removable;
	BOOL writable;
	BOOL unmountable;
	[[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:[self fullXmlPath] isRemovable:&removable isWritable:&writable isUnmountable:&unmountable description:NULL type:NULL];
	self.xmlFileIsLocal = (!removable && !unmountable);
	NSLog(@"The XML file is %@stored on the startup drive. Removable=%d Unmountable=%d",(self.xmlFileIsLocal ? @"" : @"not "),removable,unmountable);
}

-(void)postXMLChangeMessage {
	NSLog(@"Detected XML Change");
	[[NSNotificationCenter defaultCenter] postNotificationName:XMLChangedNotification object:nil];
}

-(void)startWatchingXMLFile {
	NSLog(@"Starting to watch XML file");
	if (self.xmlFileIsLocal) {
		NSLog(@"Starting watching using Event-Based method");
		[self applyForXmlChangeNotification];
	} else {
		NSLog(@"Starting watching using Poll-Based method");
		[self startPollTimer];
	}
}

-(void)stopWatchingXMLFile {
	NSLog(@"Stopping watch of XML file");
	if (self.xmlFileIsLocal) {
		[self stopEventBasedMonitoring];
	} else {
		[self stopPollTimer];
	}
}

#pragma mark Poll-Related Methods

@synthesize lastModificationDate;

-(void)startPollTimer {
	[self stopPollTimer];
	pollTimer = [[NSTimer scheduledTimerWithTimeInterval:POLL_INTERVAL target:self selector:@selector(pollXMLFile:) userInfo:nil repeats:YES] retain];
	NSLog(@"Starting XML poll timer");
}

-(void)stopPollTimer {
	if (pollTimer!=nil) [pollTimer invalidate];
	NSLog(@"Stopping XML poll timer");
}

-(void)pollXMLFile:(NSTimer *)timer {
	NSLog(@"Polling XML File... now!");
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[self fullXmlPath] traverseLink:YES];
	NSDate *newModDate = [fileAttributes objectForKey:NSFileModificationDate];
	if (newModDate) {
		if ([lastModificationDate laterDate:newModDate]==newModDate) {
			self.lastModificationDate = newModDate;
			[self postXMLChangeMessage];
		}
	} else {
		NSLog(@"Couldn't get XML file modification date");
	}
}

#pragma mark UKKQueue-Related Methods

-(void)applyForXmlChangeNotification {
	NSLog(@"Applying for KQueue Notification");
	[[UKKQueue sharedFileWatcher] setDelegate:self];
	[[UKKQueue sharedFileWatcher] addPathToQueue:[self fullXmlPath] notifyingAbout:UKKQueueNotifyAboutDelete];
}

-(void)stopEventBasedMonitoring {
	NSLog(@"Deregistering from KQueue Notification");
	[[UKKQueue sharedFileWatcher] removePathFromQueue:[self fullXmlPath]];
}

-(void)watcher:(id<UKFileWatcher>)watcher receivedNotification:(NSString *)notification forPath:(NSString *)path {
	NSLog(@"Got KQueue Notification");
	[self postXMLChangeMessage];
	[self stopEventBasedMonitoring];
	[self applyForXmlChangeNotification];
}

@end