#import "FileWatcher.h"
#import "Defines.h"

#define POLL_INTERVAL 60.0

@implementation FileWatcher

-(id)init {
	self = [super init];
	if (self != nil) {
		self.lastModificationDate = [NSDate date];
		[self updateLocationFlag];
	}
	return self;
}

-(void)dealloc {
	self.lastModificationDate = nil;
	[self stopWatchingXMLFile];
	[super dealloc];
}

#pragma mark General Methods

@synthesize xmlFileIsLocal;

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
	if (self.xmlFileIsLocal) {
		NSLog(@"Starting watching using Event-Based method");
		[self applyForXmlChangeNotification];
	} else {
		NSLog(@"Starting watching using Poll-Based method");
		[self startPollTimer];
	}
}

-(void)stopWatchingXMLFile {
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
}

-(void)stopPollTimer {
	if (pollTimer!=nil) [pollTimer invalidate];
}

-(void)pollXMLFile:(NSTimer *)timer {
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[self fullXmlPath] traverseLink:YES];
	NSDate *newModDate = [fileAttributes objectForKey:NSFileModificationDate];
	if (newModDate) {
		if ([lastModificationDate laterDate:newModDate]==newModDate) {
			self.lastModificationDate = newModDate;
			[self postXMLChangeMessage];
		}
	} else {
		(@"Couldn't get XML file modification date");
	}
}

#pragma mark UKKQueue-Related Methods

-(void)applyForXmlChangeNotification {
	[[UKKQueue sharedFileWatcher] setDelegate:self];
	[[UKKQueue sharedFileWatcher] addPathToQueue:[self fullXmlPath] notifyingAbout:UKKQueueNotifyAboutDelete];
}

-(void)stopEventBasedMonitoring {
	[[UKKQueue sharedFileWatcher] removePathFromQueue:[self fullXmlPath]];
}

-(void)watcher:(id<UKFileWatcher>)watcher receivedNotification:(NSString *)notification forPath:(NSString *)path {
	[self postXMLChangeMessage];
	[self stopEventBasedMonitoring];
	[self applyForXmlChangeNotification];
}

@end