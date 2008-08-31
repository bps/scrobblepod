//
//  FileWatcher.h
//  ScrobblePod
//
//  Created by Ben Gummer on 31/08/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKKQueue.h"

@interface FileWatcher : NSObject {
	BOOL xmlFileIsLocal;
	NSTimer *pollTimer;
	NSDate *lastModificationDate;
}

@property (retain) NSDate *lastModificationDate;
@property (assign) BOOL xmlFileIsLocal;

- (id)init;

#pragma mark General Methods
-(NSString *)fullXmlPath;
-(void)updateLocationFlag;
-(void)postXMLChangeMessage;
-(void)startWatchingXMLFile;
-(void)stopWatchingXMLFile;

#pragma mark Poll-Related Methods
-(void)startPollTimer;
-(void)stopPollTimer;
-(void)pollXMLFile:(NSTimer *)timer;

#pragma mark UKKQueue-Related Methods
-(void)applyForXmlChangeNotification;
-(void)watcher:(id<UKFileWatcher>)watcher receivedNotification:(NSString *)notification forPath:(NSString *)path;//XML
-(void)stopEventBasedMonitoring;

@end
