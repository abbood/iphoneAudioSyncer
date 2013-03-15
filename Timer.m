//
//  Timer.m
//  Snap
//
//  Created by Abdullah Bakhach on 10/3/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Timer.h"

@implementation Timer

@synthesize referencePoint = _referencePoint;


+(double)getCurTime
{
    return (double)CFAbsoluteTimeGetCurrent();
}

+(double)getTimeDifference:(double)time1
                     time2:(double)time2
{    
    CFDateRef newDate = CFDateCreate(NULL, time2);
    CFDateRef oldDate = CFDateCreate(NULL, time1);
    
    CFTimeInterval difference = CFDateGetTimeIntervalSinceDate(newDate, oldDate);    
    
    //NSLog(@"this is time difference %f",fabs(difference));
    CFRelease(oldDate); CFRelease(newDate); 
    
    // fabs = absolute value
    return fabs(difference);    
}



#pragma mark - Helper functions

+(void)printCurTime
{    
    //NSLog(@"date: %lu", (double)([NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 100]));
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm:ss.SSS"];
    
    double curTime = [[self class] getCurTime];
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:curTime];
    
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    NSLog(@"formattedDateString: %@ actual date %f", formattedDateString, curTime);    
    
}

+(void)printTime:(double)absTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm:ss.SSS"];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:absTime];
    
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    NSLog(@"formattedDateString: %@ actual date %f", formattedDateString, absTime);                
}

-(void)setCurrentTimeAsReferencepoint
{
    _referencePoint = [[self class] getCurTime];
    [[self class] printTime:_referencePoint];  
}


-(void)setReferencePoint:(double)referencePoint
{
    _referencePoint = referencePoint;
    [[self class] printTime:_referencePoint];  
}

-(double)getTimeElapsedInMilliSec
{
 
    CFDateRef oldDate = CFDateCreate(NULL, _referencePoint);
    double curTime =  [[self class] getCurTime];
    CFDateRef newDate = CFDateCreate(NULL,curTime);
    
    CFTimeInterval difference = CFDateGetTimeIntervalSinceDate(newDate, oldDate);

    
    NSLog(@"this is time difference %f",difference);
    
    double difference2 = _referencePoint - curTime;
    NSLog(@"this is time difference in absolute terms between _referencePoint (%f) and curTime (%f) %f",_referencePoint, curTime, fabs(difference2));
    
    CFRelease(oldDate); CFRelease(newDate); 

    return difference;
}

-(double)getTimeElapsedinAbsTime
{
    double difference = _referencePoint - [[self class] getCurTime]; 
    NSLog(@"this is time difference in absolute terms %f",difference);
    return difference;
}

-(void)getAbsTimeInFuture
{
    double futureTime = _referencePoint + 10;
    CFDateRef futureDate = CFDateCreate(NULL, futureTime);
    CFDateRef oldDate = CFDateCreate(NULL, _referencePoint);
    
    CFTimeInterval difference = CFDateGetTimeIntervalSinceDate(futureDate, oldDate);
    
    NSLog(@"getAbsTimeInFuture: this is time difference %f",fabs(difference));
    
    double difference2 = _referencePoint - futureTime;
    NSLog(@"getAbsTimeInFuture: this is time difference in absolute terms between _referencePoint (%f) and futureTime (%f) %f",_referencePoint, futureTime, fabs(difference2));
    
    NSLog(@"getAbsTimeInFuture: this is what future time looks like in date terms");
    [[self class] printTime:futureTime];
    
    NSLog(@"getAbsTimeInFuture: this is what the curtime looks like in date terms");
    [[self class] printTime:_referencePoint];
    
    CFRelease(oldDate); CFRelease(futureDate); 
    
}

@end
