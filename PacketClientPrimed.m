//
//  PacketClientPrimed.m
//  Snap
//
//  Created by Abdullah Bakhach on 10/3/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "PacketClientPrimed.h"
#import "NSData+SnapAdditions.h"
#import "AudioStreamer.h"

@implementation PacketClientPrimed

@synthesize profiler = _profiler;

+ (id)packetWithData:(NSData *)data
{   
    size_t offset = PACKET_HEADER_SIZE;
        
    NSMutableArray *profiler = [NSMutableArray arrayWithCapacity:kNumAQBufs];    
    for (int t = 0; t < kNumAQBufs; ++t)
	{
        [profiler insertObject:[NSNumber numberWithDouble:
                                [[NSData dataWithBytes:(void *)([data bytes] + offset) length:sizeof(double)] rw_double64]]
                      atIndex:t];
        offset +=sizeof(double);
    }
    return [[self class] packetWithProfiler:profiler];
 
}

+ (id)packetWithProfiler:(NSMutableArray *)profiler 
{
	return [[[self class] alloc] initWithProfiler:profiler];
}

- (id)initWithProfiler:(NSMutableArray *)profiler
{
	if ((self = [super initWithType:PacketTypeClientPrimed]))
	{
		self.profiler = profiler;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [self.profiler enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [data rw_appendDouble64:[obj doubleValue]];         
    }];
}

@end
