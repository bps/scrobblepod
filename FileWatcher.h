//
//  FileWatcher.h
//  ScrobblePod
//
//  Created by Ben Gummer on 31/08/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FileWatcher : NSObject {

}

+(FileWatcher *)sharedManager;
+(id)allocWithZone:(NSZone *)zone;
-(id)copyWithZone:(NSZone *)zone;
-(id)retain;
-(unsigned)retainCount;
-(void)release;
-(id)autorelease;

- (id)init;


@end
