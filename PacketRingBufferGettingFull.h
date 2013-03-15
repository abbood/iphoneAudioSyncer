//
//  PacketRingBufferGettingFull.h
//  Snap
//
//  Created by Abdullah Bakhach on 10/11/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Packet.h"

@interface PacketRingBufferGettingFull : Packet

@property (nonatomic, assign) UInt32 batchNumber;

+ (id)packetWithBatchNumber:(UInt32)batchNumber;


@end
