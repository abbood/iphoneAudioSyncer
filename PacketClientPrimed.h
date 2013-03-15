//
//  PacketClientPrimed.h
//  Snap
//
//  Created by Abdullah Bakhach on 10/3/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Packet.h"

@interface PacketClientPrimed : Packet

@property (nonatomic, strong) NSMutableArray *profiler;

+ (id)packetWithProfiler:(NSMutableArray *)profiler;



@end
