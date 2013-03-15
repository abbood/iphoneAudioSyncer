//
//  PacketRecieved.h
//  Snap
//
//  Created by Abdullah Bakhach on 10/9/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Packet.h"

@interface PacketRecieved : Packet

@property (nonatomic, assign) UInt32 packetNumber;


+ (id)packetWithNumber:(UInt32) packetNumber;

@end
