//
//  ClientProfiler.h
//  Snap
//
//  Created by Abdullah Bakhach on 10/9/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClientProfiler : NSObject

@property (nonatomic, strong) NSMutableDictionary *packetReceivedSchedule;
@property (nonatomic, assign) UInt32 avgLatency;

@end
