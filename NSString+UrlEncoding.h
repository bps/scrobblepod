//
//  NSString+UrlEncoding.h
//  ScrobblePod
//
//  Created by Ben Gummer on 23/03/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (UrlEncoding)

-(NSString *)urlEncodedString;
- (NSString*)encodePercentEscapesPerRFC2396ButNot:(NSString*)butNot butAlso:(NSString*)butAlso withString:aString;

@end
