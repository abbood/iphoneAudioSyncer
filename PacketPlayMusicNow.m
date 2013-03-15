//
//  PacketPlayMusicNow.m
//  Snap
//
//  Created by Abdullah Bakhach on 10/4/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "PacketPlayMusicNow.h"
#import "NSData+SnapAdditions.h"

@implementation PacketPlayMusicNow

@synthesize delayTime = _delayTime;

+ (id)packetWithData:(NSData *)data
{
    double delayTime;
    size_t offset = PACKET_HEADER_SIZE;
    delayTime = [[NSData dataWithBytes:(void *)([data bytes] + offset) length:sizeof(double)] rw_double64];
    
    return [[self class] packetWithDelayTime:delayTime];
}


+ (id)packetWithDelayTime:(double) delayTime
{
	return [[[self class] alloc] initWithDelayTime:delayTime

            ];        
}

- (id)initWithDelayTime:(double)delayTime
{
	if ((self = [super initWithType:PacketTypePlayMusicNow]))
	{
		self.delayTime = delayTime;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendDouble64:self.delayTime];    
}

@end
