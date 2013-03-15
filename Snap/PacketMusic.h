//
//  PacketMusic.h
//  Snap
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Packet.h"

@interface PacketMusic : Packet

@property (nonatomic, strong) NSData *musicData;

+ (id)packetWithMusicData:(NSData *)musicData;

@end
