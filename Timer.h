//
//  Timer.h
//  Snap
//
//  Created by Abdullah Bakhach on 10/3/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Timer : NSObject

+(double)getCurTime;
+(double)getTimeDifference:(double)time1
                     time2:(double)time2;

// helper functions
+(void)printCurTime;
+(void)printTime:(double)absTime;
-(void)setReferencePoint:(double)referencePoint;
-(void)setCurrentTimeAsReferencepoint;
-(double)getTimeElapsedInMilliSec;
-(double)getTimeElapsedinAbsTime;
-(void)getAbsTimeInFuture;

@property (nonatomic,assign) double referencePoint;



@end
