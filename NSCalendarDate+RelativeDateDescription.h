//
//  NSCalendarDate+RelativeDateDescription.h
//  ScrobblePod
//
//  Created by Ben Gummer on 20/04/07.
//  Copyright 2007 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSCalendarDate (RelativeDateDescription)
-(NSString *)relativeDateDescription;
-(BOOL)dateIsInLastTwoWeeks;
-(BOOL)dateIsInCurrentWeek;
-(BOOL)dateIsInToday;
@end
