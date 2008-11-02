//
//  NSString+Contains.m
//  ApiHubTester
//
//  Created by Ben Gummer on 19/07/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import "NSString+Contains.h"

@implementation NSString (BG_Contains)

-(BOOL)containsString:(NSString *)search {
	return ([self rangeOfString:search].location != NSNotFound);
}

@end
