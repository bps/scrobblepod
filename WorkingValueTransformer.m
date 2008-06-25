//
//  WorkingValueTransformer.m
//  ValueTransformer
//
//  Created by gohara on 7/23/07.
//  http://gohara.wustl.edu
//
//  Copyright 2007 MacResearch.org. All rights reserved.
//

// Note: Changed to allow tranformation for many images. -BG

#import "WorkingValueTransformer.h"


@implementation WorkingValueTransformer

+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return YES; }
- (id)transformedValue:(id)value {
	
	NSString *imageName = [value stringValue];
	NSImage *theImage = [NSImage imageNamed:imageName];
	if (theImage!=nil) return theImage;
	
	return nil;
}


@end
