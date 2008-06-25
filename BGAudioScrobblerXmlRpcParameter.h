//
//  BGAudioScrobblerXmlRpcParameter.h
//  ScrobblePod
//
//  Created by Ben Gummer on 24/04/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BGAudioScrobblerXmlRpcParameter : NSObject {
	id parameter;
}

@property (retain) id parameter;

-(id)initWithParameter:(id)aParam;
-(void)dealloc;
-(NSString *)xmlDescription;

@end
