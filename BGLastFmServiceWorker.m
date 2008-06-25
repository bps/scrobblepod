//
//  BGLastFmServiceWorker.m
//  ScrobblePod
//
//  Created by Ben Gummer on 29/07/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import "BGLastFmServiceWorker.h"
#import "Defines.h"
#import "CocoaCryptoHashing.h"
#import "iTunes.h"
#import "SFHFKeychainUtils.h"
#import "BGAudioScrobblerXmlRpcPost.h"
#import "NSString+UrlEncoding.h"

#define PLAYER_CODE @"Shell.FM"

@implementation BGLastFmServiceWorker

- (id)init {
	self = [super init];
	if (self != nil) {
	
		iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
		
		if ([iTunes isRunning] && [iTunes playerState]==iTunesEPlSPlaying) {

			iTunesTrack *currentTrack = [iTunes currentTrack];
			self.title = currentTrack.name;
			self.artist = currentTrack.artist;	
			self.album = currentTrack.album;	
		} else {
			self.title = @"";
			self.artist = @"";
			self.album = @"";
		}
	}
	return self;
}

-(void)acquireCredentials {
	SecKeychainItemRef itemRef;
	NSString *currentUsername = [[NSUserDefaults standardUserDefaults] valueForKey:BGPrefUserKey];
	NSString *currentPassword = [SFHFKeychainUtils getWebPasswordForUser:currentUsername  URL:[NSURL URLWithString:@"http://www.last.fm/"] domain:@"Last.FM Login" itemReference:&itemRef];

	self.username = currentUsername;
	self.password = currentPassword;
}

- (void) dealloc {
	[title release];
	[artist release];
	[album release];
	[username release];
	[password release];
	[super dealloc];
}


@synthesize title;
@synthesize artist;
@synthesize album;
@synthesize username;
@synthesize password;

////

-(void)submitTasteCommand:(NSString *)tasteCommand {
	if (self.title.length>0 && self.artist.length>0) {
		BGAudioScrobblerXmlRpcPost *tastePost = [[BGAudioScrobblerXmlRpcPost alloc] init];
		[tastePost setMethodName:tasteCommand];
		[tastePost addAuthParametersWithUsername:username andPassword:password];
		[tastePost addPostParameter:artist];
		[tastePost addPostParameter:title];

		NSString *postXML = [tastePost xmlDescription];
		[self performApiRequestWithXml:postXML];
	}
}

-(NSArray *)tagsForSong:(BGLastFmSong *)aSong forType:(int)aType {
//	NSString *baseUrl = [[self performRadioHandshake] baseURL];
	NSString *baseUrl = @"ws.audioscrobbler.com";
	NSString *tagUrl = [NSString stringWithFormat:@"http://%@/1.0/%@",baseUrl,[self tagExtensionForType:aType]];
	NSData *responseData = [self dataFromUrl:[NSURL URLWithString:tagUrl]];
	NSError *parseError = nil;
	NSMutableArray *tagsArray = [NSMutableArray array];
	if (responseData) {
		NSXMLDocument *tagDict = [[NSXMLDocument alloc] initWithData:responseData options:NSXMLDocumentTidyXML error:&parseError];
		NSArray *nameNodes = [tagDict nodesForXPath:@".//name" error:nil];
		NSXMLNode *currentNameNode;
		for (currentNameNode in nameNodes) {
			[tagsArray addObject:[currentNameNode stringValue]];
		}
	
		[tagDict release];
	}
	
	return tagsArray;
}

-(void)tagWithType:(int)tagType forTags:(NSArray *)tagArray {
	if (self.title.length>0 && self.artist.length>0 && tagArray.count > 0) {
		BGAudioScrobblerXmlRpcPost *tastePost = [[BGAudioScrobblerXmlRpcPost alloc] init];
		[tastePost setMethodName:[self methodNameForTagType:tagType]];
		[tastePost addAuthParametersWithUsername:username andPassword:password];
		[tastePost addPostParameter:artist];
		if (tagType == BGOperationType_Song) {
			[tastePost addPostParameter:title];
		} else if (tagType == BGOperationType_Album) {
			[tastePost addPostParameter:album];
		}
		[tastePost addPostParameter:tagArray];
		[tastePost addPostParameter:@"set"];

		NSString *postXML = [tastePost xmlDescription];
		[self performApiRequestWithXml:postXML];
	}
}

-(void)recommendWithType:(int)recommendType forFriendUsernames:(NSArray *)friendsArray {
	if (self.title.length>0 && self.artist.length>0 && friendsArray.count > 0) {
		BGAudioScrobblerXmlRpcPost *tastePost = [[BGAudioScrobblerXmlRpcPost alloc] init];
		[tastePost setMethodName:@"recommendItem"];
		[tastePost addAuthParametersWithUsername:username andPassword:password];
		[tastePost addPostParameter:artist];
		if (recommendType == BGOperationType_Song) {
			[tastePost addPostParameter:title];
		} else if (recommendType == BGOperationType_Album) {
			[tastePost addPostParameter:album];
		} else {
			[tastePost addPostParameter:@""];
		}
		[tastePost addPostParameter:[self recommendTypeStringFromType:recommendType]];
		[tastePost addPostParameter:[friendsArray lastObject]];
		[tastePost addPostParameter:@"Check out this song. It's really good."];
		[tastePost addPostParameter:@"en"];

		NSString *postXML = [tastePost xmlDescription];
		NSLog(@"%@",postXML);
		[self performApiRequestWithXml:postXML];
	}
}

-(NSString *)recommendTypeStringFromType:(int)recommendationType {

	NSString *methodName;
	switch (recommendationType) {
		case BGOperationType_Song:
			methodName = @"track";
			break;
		case BGOperationType_Artist:
			methodName = @"artist";
			break;
		case BGOperationType_Album:
			methodName = @"album";
			break;
		default:
			methodName = @"unknown_warning";
			break;
	}
	return methodName;

}

-(NSString *)methodNameForTagType:(int)tagType {
	NSString *methodName;
	switch (tagType) {
		case BGOperationType_Song:
			methodName = @"tagTrack";
			break;
		case BGOperationType_Artist:
			methodName = @"tagArtist";
			break;
		case BGOperationType_Album:
			methodName = @"tagAlbum";
			break;
		default:
			methodName = @"unknownTagType";
			break;
	}
	return methodName;
}

-(NSString *)methodNameForRecommendationType:(int)recommendationType {
	NSString *methodName;
	switch (recommendationType) {
		case BGOperationType_Song:
			methodName = @"recommendTrack";
			break;
		case BGOperationType_Artist:
			methodName = @"recommendArtist";
			break;
		case BGOperationType_Album:
			methodName = @"recommendAlbum";
			break;
		default:
			methodName = @"unknownRecType";
			break;
	}
	return methodName;
}

-(NSArray *)friendsForUser:(NSString *)aUsername {
	//http://ws.audioscrobbler.com/1.0/user/RJ/friends.txt

	NSString *baseUrl = @"ws.audioscrobbler.com";
	NSString *friendsUrl = [NSString stringWithFormat:@"http://%@/1.0/user/%@/friends.xml",baseUrl,aUsername];
	NSData *responseData = [self dataFromUrl:[NSURL URLWithString:friendsUrl]];
	NSError *parseError = nil;
	NSMutableArray *friendsArray = [NSMutableArray array];
	if (responseData) {
		NSXMLDocument *tagDict = [[NSXMLDocument alloc] initWithData:responseData options:NSXMLDocumentTidyXML error:&parseError];
		NSArray *nameNodes = [tagDict nodesForXPath:@".//@username" error:nil];
		NSXMLNode *currentNameNode;
		for (currentNameNode in nameNodes) {
			[friendsArray addObject:[currentNameNode stringValue]];
		}
		[tagDict release];
	}
	
	return friendsArray;


}

-(NSString *)tagExtensionForType:(int)tagType {
	NSString *encodedTitle = [title urlEncodedString];
	NSString *encodedArtist = [artist urlEncodedString];
	NSString *encodedAlbum = [album urlEncodedString];
	NSString *extensionPath;
	switch (tagType) {
		case BGOperationType_Song:
			extensionPath = [NSString stringWithFormat:@"track/%@/%@/toptags.xml",encodedArtist,encodedTitle];
			break;
		case BGOperationType_Artist:
			extensionPath = [NSString stringWithFormat:@"artist/%@/toptags.xml",encodedArtist];
			break;
		case BGOperationType_Album:
			extensionPath = [NSString stringWithFormat:@"album/%@/%@/toptags.xml",encodedArtist,encodedAlbum];
			break;
		default:
			extensionPath = @"UnknownExtension/unknown.xml";
			break;
	}
	return extensionPath;
}

-(BGLastFmRadioHandshakeResponse *)performRadioHandshake {
	NSURL *handshakeURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://ws.audioscrobbler.com/radio/handshake.php?version=1.0.0&platform=mac&username=%@&passwordmd5=%@&debug=0&partner=",username,password.md5HexHash]];
	
	NSMutableURLRequest *handshakeRequest = [[NSMutableURLRequest alloc] initWithURL:handshakeURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:25.0];
	[handshakeRequest setHTTPMethod:@"GET"];
	[handshakeRequest setTimeoutInterval:20.0];
		NSData *handshakeResponseData = [NSURLConnection sendSynchronousRequest:handshakeRequest returningResponse:nil error:nil];
	[handshakeRequest release];

	BGLastFmRadioHandshakeResponse *handshakeResponse;

	if (handshakeResponseData!=nil) {
		NSString *handshakeResponseString = [[NSString alloc] initWithData:handshakeResponseData encoding:NSUTF8StringEncoding];
			handshakeResponse = [[BGLastFmRadioHandshakeResponse alloc] initWithHandshakeResponseString:handshakeResponseString];
			[handshakeResponse autorelease];
		[handshakeResponseString release];
	}
	
	return handshakeResponse;

}

-(NSData *)dataFromUrl:(NSURL *)theURL {
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:theURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:25.0];
	[theRequest setHTTPMethod:@"GET"];
	NSData *theData = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:nil];
	[theRequest release];

	return theData;

}

-(void)performApiRequestWithXml:(NSString *)theXML {
	
	NSData *postData = [theXML dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:@"http://ws.audioscrobbler.com/1.0/rw/xmlrpc.php"]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setTimeoutInterval:20.0];// timeout scrobble posting after 20 seconds
	[request setHTTPBody:postData];
			
	NSError *postingError;
	NSData *scrobbleResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&postingError];
			
	if (scrobbleResponseData!=nil && postingError==nil) {
		NSString *apiResponseString = [[NSString alloc] initWithData:scrobbleResponseData encoding:NSUTF8StringEncoding];
			NSLog(@"API:%@",apiResponseString);
		[apiResponseString release];
	}

	[request release];
}

@end
