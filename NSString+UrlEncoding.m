//
//  NSString+UrlEncoding.m
//  ScrobblePod
//
//  Created by Ben Gummer on 23/03/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "NSString+UrlEncoding.h"


@implementation NSString (UrlEncoding)

-(NSString *)urlEncodedString {
	return [self encodePercentEscapesPerRFC2396ButNot:@"" butAlso:@"()[]!@#$^*&?+-\"'.,;" withString:self];
}


- (NSString*)encodePercentEscapesPerRFC2396ButNot:(NSString*)butNot butAlso:(NSString*)butAlso withString:aString {
	return (NSString*)[(NSString*)CFURLCreateStringByAddingPercentEscapes (NULL, (CFStringRef)aString, (CFStringRef)butNot, (CFStringRef)butAlso, kCFStringEncodingUTF8) autorelease] ;
}

@end
