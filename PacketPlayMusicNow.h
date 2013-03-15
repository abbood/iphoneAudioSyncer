//
//  PlayMusicNow.h
//  Snap
//
//  Created by Abdullah Bakhach on 10/4/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Packet.h"

@interface PacketPlayMusicNow : Packet

@property (nonatomic, assign) double delayTime;

+ (id)packetWithDelayTime:(double) delayTime;
@end
