//
//  ServerProfiler.h
//  Snap
//
//  Created by Abdullah Bakhach on 10/9/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServerProfiler : NSObject

@property (nonatomic, strong) NSMutableArray * packetSentSchedule;
@property (nonatomic, strong) NSMutableDictionary *clientProfilers;

-(id)initWithClients:(UInt32)numClients;

@end
