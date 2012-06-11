//
//  ZDate_utils.m
//
//  Created by Lukas Zeller on 2011/03/07.
//  Copyright (c) 2011 by Lukas Zeller. All rights reserved.
//

#include "ZDate_utils.h"


BOOL sameDate(NSDate *d1, NSDate *d2)
{
	if (d1==nil && d2==nil) return TRUE;
  if (d1==nil) return FALSE;
  if (d2==nil) return FALSE;
  return [d1 isEqualToDate:d2];
}


BOOL sameCalendarDay(NSDate *d1, NSDate *d2)
{
	if (d1==nil && d2==nil) return TRUE;
  if (d1==nil) return FALSE;
  if (d2==nil) return FALSE;
  return [d1 isSameCalendarDay:d2];
}



// date-only in context of UTC
NSDate *dateOnlyInUTC(NSDate *aDate)
{
  if (aDate==nil) return nil;
  NSDateComponents *comp = [[NSCalendar cachedUTCCalendar]
    components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
    fromDate:aDate
  ];
  return [[NSCalendar cachedUTCCalendar] dateFromComponents:comp];
} 



// make date-only in context of current calendar
NSDate *dateOnly(NSDate *aDate)
{
  if (aDate==nil) return nil;
  NSDateComponents *comp = [[NSCalendar cachedCalendar]
    components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
    fromDate:aDate
  ];
  return [[NSCalendar cachedCalendar] dateFromComponents:comp];
}


// make localtime 0:00 from UTC-context allday timestamp
NSDate *localDateOnlyFromUTC(NSDate *aUTCTime)
{
  if (aUTCTime==nil) return nil;
  NSDateComponents *comp = [[NSCalendar cachedUTCCalendar]
    components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
    fromDate:aUTCTime
  ];
  return [[NSCalendar cachedCalendar] dateFromComponents:comp];
}


// return the same time-of-day as NSDate represents in localtime, but in UTC
NSDate *sameTimeInUTC(NSDate *aLocalTime)
{
  if (aLocalTime==nil) return nil;
  NSDateComponents *comp = [[NSCalendar cachedCalendar]
    components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit
    fromDate:aLocalTime
  ];
  return [[NSCalendar cachedUTCCalendar] dateFromComponents:comp];
}


// return the same time-of-day as NSDate represents in UTC, but in localtime
NSDate *sameTimeInLocalTime(NSDate *aUTCTime)
{
  if (aUTCTime==nil) return nil;
  NSDateComponents *comp = [[NSCalendar cachedUTCCalendar]
    components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit
    fromDate:aUTCTime
  ];
  return [[NSCalendar cachedCalendar] dateFromComponents:comp];
}




// seconds since midnight in default time zone
NSTimeInterval secondsSinceMidnight(NSDate *aDate)
{
  if (aDate==nil) return 0;
  return [aDate timeIntervalSinceDate:dateOnly(aDate)];
  //return [aDate timeIntervalSinceReferenceDate] - [dateOnly(aDate) timeIntervalSinceReferenceDate];
}




@implementation NSDate (NSDate_ZDateUtils)

+ (NSDate *)dateOnly
{
  return [[self date] dateOnly];
}


- (NSDate *)dateOnly
{
  return dateOnly(self);
}

- (BOOL)isSameCalendarDay:(NSDate *)aOtherDay
{
  if (aOtherDay==nil) return NO;
  return [dateOnly(self) isEqualToDate:dateOnly(aOtherDay)];
}

@end




@implementation NSTimeZone (NSTimeZone_ZDateUtils)


static NSTimeZone *cachedTimeZone = nil;

+ (NSTimeZone *)cachedTimezone
{
  if (!cachedTimeZone) {
    cachedTimeZone = [[NSTimeZone defaultTimeZone] retain];
  }
  return cachedTimeZone;
}


+ (void)resetCachedTimezone
{
  NSTimeZone *t = cachedTimeZone;
  cachedTimeZone = nil;
  [t release];
}


+ (void)resetSystemTimeZoneAndCache
{
  [self resetSystemTimeZone];
  [self resetCachedTimezone];
  [NSDateFormatter resetCachedDateFormatter];
  [NSCalendar resetCachedCalendars];
}

@end



@implementation NSDateFormatter (NSDateFormatter_ZDateUtils)

#define CACHED_DATEFORMATTER_KEY @"ZDate_utils_cdf"

+ (NSDateFormatter *)cachedDateFormatter;
{
  NSMutableDictionary *td = [[NSThread currentThread] threadDictionary];
  NSDateFormatter *df = [td objectForKey:CACHED_DATEFORMATTER_KEY];
  if (!df) {
    df = [[NSDateFormatter alloc] init];
    [df setCalendar:[NSCalendar cachedCalendar]];
    [td setObject:df forKey:CACHED_DATEFORMATTER_KEY];
  }
  return df;
}


+ (void)resetCachedDateFormatter
{
  NSMutableDictionary *td = [[NSThread currentThread] threadDictionary];
  [td removeObjectForKey:CACHED_DATEFORMATTER_KEY];
}

@end



@implementation NSCalendar (NSCalendar_ZDateUtils)

#define CACHED_CALENDAR_KEY @"ZDate_utils_ccal"
#define CACHED_UTC_CALENDAR_KEY @"ZDate_utils_cUTCcal"

+ (NSCalendar *)cachedCalendar;
{
  NSMutableDictionary *td = [[NSThread currentThread] threadDictionary];
  NSCalendar *cal = [td objectForKey:CACHED_CALENDAR_KEY];
  if (!cal) {
    cal = [[NSCalendar currentCalendar] retain];
    [cal setTimeZone:[NSTimeZone cachedTimezone]];
    [td setObject:cal forKey:CACHED_CALENDAR_KEY];
  }
  return cal;
}


+ (NSCalendar *)cachedUTCCalendar
{
  NSMutableDictionary *td = [[NSThread currentThread] threadDictionary];
  NSCalendar *cal = [td objectForKey:CACHED_UTC_CALENDAR_KEY];
  if (!cal) {
    cal = [[NSCalendar currentCalendar] retain];
    [cal setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [td setObject:cal forKey:CACHED_UTC_CALENDAR_KEY];
  }
  return cal;  
}



+ (void)resetCachedCalendars;
{
  NSMutableDictionary *td = [[NSThread currentThread] threadDictionary];
  [td removeObjectForKey:CACHED_CALENDAR_KEY];
  [td removeObjectForKey:CACHED_UTC_CALENDAR_KEY];
}





@end





@implementation NSDateComponents (NSDateComponents_ZDateUtils)

+ (NSDateComponents *)dateComponents
{
  return [[[NSDateComponents alloc] init] autorelease];
}


+ (NSDateComponents *)dateComponentsWithDay:(NSInteger)aDay;
{
  NSDateComponents *dc = [self dateComponents];
  [dc setDay:aDay];
  return dc;
}


+ (NSDateComponents *)dateComponentsWithYear:(NSInteger)aYear month:(NSInteger)aMonth day:(NSInteger)aDay
{
  NSDateComponents *dc = [self dateComponents];
  [dc setDay:aDay];
  [dc setMonth:aMonth];
  [dc setYear:aYear];
  return dc;
}


@end


/* eof */
