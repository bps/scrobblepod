//
//  NSCalendarDate+RelativeDateDescription.m
//  ScrobblePod
//
//  Created by Ben Gummer on 20/04/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//
//
#import "NSCalendarDate+RelativeDateDescription.h"


@implementation NSCalendarDate (RelativeDateDescription)

-(NSString *)relativeDateDescription {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSMutableString *relativeDateDescription = [NSMutableString new];
	[relativeDateDescription appendString:[self descriptionWithCalendarFormat:@"%I:%M"]];
	if ([self dateIsInToday]) {
		if ([self hourOfDay]<12) {
			[relativeDateDescription appendString:@" this morning"];
		} else if ([self hourOfDay]>17) {
			[relativeDateDescription appendString:@" this evening"];
		} else {
			[relativeDateDescription appendString:@" this afternoon"];
		}
	} else if ([self dateIsInLastTwoWeeks]) {
		int weekMultiplier = 1;
		int weekAddition = 0;
		if ([self  dateIsInCurrentWeek]) {
			weekMultiplier = -1;
			weekAddition = -1;
		}
		if (((([self dayOfWeek]-[now dayOfWeek])*weekMultiplier)+weekAddition) >= 0) {
			[relativeDateDescription appendString:[self descriptionWithCalendarFormat:@" %p"]];
			[relativeDateDescription appendString:@" last"];
			[relativeDateDescription appendString:[self descriptionWithCalendarFormat:@" %A"]];
		} else {
			[relativeDateDescription appendString:[self descriptionWithCalendarFormat:@" %p"]];
			[relativeDateDescription appendString:@" on "];
			[relativeDateDescription appendString:[self descriptionWithCalendarFormat:@"%A %B %d"]];
		}
	} else {
		[relativeDateDescription appendString:[self descriptionWithCalendarFormat:@" %p"]];
		[relativeDateDescription appendString:@" on "];
		[relativeDateDescription appendString:[self descriptionWithCalendarFormat:@"%A %B %d"]];	
	}
	return relativeDateDescription;
}

-(BOOL)dateIsInToday {
	return ([[NSCalendarDate calendarDate] dayOfCommonEra]==[self dayOfCommonEra]);
}

-(BOOL)dateIsInCurrentWeek {
	NSCalendarDate *mondayOfThisWeek = [NSCalendarDate calendarDate];
	while ([mondayOfThisWeek dayOfWeek]!=1) {
		mondayOfThisWeek = [mondayOfThisWeek dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
	}
	return ([self dayOfCommonEra]>=[mondayOfThisWeek dayOfCommonEra] && [self dayOfCommonEra]<=[[NSCalendarDate calendarDate] dayOfCommonEra]);
}

-(BOOL)dateIsInLastTwoWeeks {
	NSCalendarDate *mondayOfThisWeek = [NSCalendarDate calendarDate];
	while ([mondayOfThisWeek dayOfWeek]!=1) {
		mondayOfThisWeek = [mondayOfThisWeek dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
	}
	NSCalendarDate *mondayOfLastWeek = [mondayOfThisWeek dateByAddingYears:0 months:0 days:-7 hours:0 minutes:0 seconds:0];
	return ([self dayOfCommonEra]>=[mondayOfLastWeek dayOfCommonEra] && [self dayOfCommonEra]<=[[NSCalendarDate calendarDate] dayOfCommonEra]);
}

@end
