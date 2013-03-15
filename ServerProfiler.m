//
//  ServerProfiler.m
//  Snap
//
//  Created by Abdullah Bakhach on 10/9/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "ServerProfiler.h"
#import "AudioStreamer.h"
#import "ClientProfiler.h"

@implementation ServerProfiler

@synthesize clientProfilers = _clientProfilers;
@synthesize packetSentSchedule = _packetSentSchedule;

-(id)initWithClients:(UInt32)numClients
{
    self = [super init];
    if (self != nil) {
        _packetSentSchedule = [NSMutableArray arrayWithCapacity:kNumAQBufs];
        _clientProfilers = [NSMutableDictionary dictionaryWithCapacity:numClients];
    }
    return self;    
}

@end
