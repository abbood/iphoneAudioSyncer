//
//  PacketRingBufferGettingFull.m
//  Snap
//
//  Created by Abdullah Bakhach on 10/11/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "PacketRingBufferGettingFull.h"
#import "NSData+SnapAdditions.h"

@implementation PacketRingBufferGettingFull

@synthesize batchNumber = _batchNumber;

+ (id)packetWithData:(NSData *)data
{
    UInt32 batchNumber;
    batchNumber = [data rw_int32AtOffset:PACKET_HEADER_SIZE];
    return [[self class] packetWithBatchNumber:batchNumber];    
}

+ (id)packetWithBatchNumber:(UInt32)batchNumber 
{
	return [[[self class] alloc] initWithBatchNumber:batchNumber];
}

- (id)initWithBatchNumber:(UInt32)batchNumber
{
	if ((self = [super initWithType:PacketTypeRingBufferGettingFull]))
	{
		self.batchNumber = batchNumber;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendInt32:self.batchNumber];
}


@end
