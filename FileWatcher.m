#import "FileWatcher.h"
#import "Defines.h"

@implementation FileWatcher

static FileWatcher *sharedFileWatcher = nil;

+(FileWatcher *)sharedManager {
	@synchronized(self) {
		if (sharedFileWatcher == nil) {
			[[self alloc] init]; // assignment not done here
		}
	}
	return sharedFileWatcher;
}

+(id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedFileWatcher == nil) {
			sharedFileWatcher = [super allocWithZone:zone];
			return sharedFileWatcher;  // assignment and return on first allocation
		}
	}
	return nil; //on subsequent allocation attempts return nil
}
 
-(id)copyWithZone:(NSZone *)zone {
	return self;
}
 
-(id)retain {
	return self;
}
 
-(unsigned)retainCount {
	return UINT_MAX;  //denotes an object that cannot be released
}
 
-(void)release {
    //do nothing
}
 
-(id)autorelease {
	return self;
}

-(id)init {
	self = [super init];
	if (self != nil) {
		
	}
	return self;
}

-(void)dealloc {
	[super dealloc];
}

@end