//
//  ZDate_utils.h
//
//  Created by Lukas Zeller on 2011/03/07.
//  Copyright (c) 2011 by Lukas Zeller. All rights reserved.
//

#import <Foundation/Foundation.h>

/// same date or both dates nil return YES, everything else NO
BOOL sameDate(NSDate *d1, NSDate *d2);
/// same calendar day or both dates nil return YES, everything else NO
BOOL sameCalendarDay(NSDate *d1, NSDate *d2);

// Date and time utilities
#define SecondsPerMin 60
#define SecondsPerHour (SecondsPerMin*60)
#define SecondsPerDay (SecondsPerHour*24)

NSDate *dateOnlyInUTC(NSDate *aDate);
NSDate *dateOnly(NSDate *aDate);
NSDate *localDateOnlyFromUTC(NSDate *aUTCTime);
NSDate *sameTimeInUTC(NSDate *aLocalTime);
NSDate *sameTimeInLocalTime(NSDate *aUTCTime);

//Obsolete%%%: NSTimeInterval secondsSinceMidnightWithOffset(NSDate *aDate, NSTimeInterval aOffs);
NSTimeInterval secondsSinceMidnight(NSDate *aDate);


@interface NSDate (NSDate_ZDateUtils)
+ (NSDate *)dateOnly;
- (NSDate *)dateOnly;
- (BOOL)isSameCalendarDay:(NSDate *)aOtherDay;
@end


@interface NSTimeZone (NSTimeZone_ZDateUtils)
+ (NSTimeZone *)cachedTimezone;
+ (void)resetCachedTimezone;
+ (void)resetSystemTimeZoneAndCache;
@end


@interface NSDateFormatter (NSDateFormatter_ZDateUtils)
+ (NSDateFormatter *)cachedDateFormatter;
+ (void)resetCachedDateFormatter;
@end


@interface NSCalendar (NSCalendar_ZDateUtils)
+ (NSCalendar *)cachedUTCCalendar;
+ (NSCalendar *)cachedCalendar;
+ (void)resetCachedCalendars;
@end


@interface NSDateComponents (NSDateComponents_ZDateUtils)
+ (NSDateComponents *)dateComponents;
+ (NSDateComponents *)dateComponentsWithDay:(NSInteger)aDay;
+ (NSDateComponents *)dateComponentsWithYear:(NSInteger)aYear month:(NSInteger)aMonth day:(NSInteger)aDay;
@end