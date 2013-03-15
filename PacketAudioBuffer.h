//
//  PacketAudioBuffer.h
//  Snap
//
//  Created by Abdullah Bakhach on 8/28/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//
#import "Packet.h"
#import <Foundation/Foundation.h>

@interface PacketAudioBuffer : Packet

@property (nonatomic, strong) NSData * audioBufferData;
@property (nonatomic, strong) NSData * packetDescriptionsData;

@property (nonatomic) NSString * packetID;
@property (nonatomic, readwrite) UInt32 totalSize;
@property (nonatomic, readwrite) UInt32 packetNumber;
@property (nonatomic, readwrite) UInt32 packetSize;
@property (nonatomic, readwrite) UInt32 packetBytesFilled;
@property (nonatomic, readwrite) UInt32 packetDescriptionsBytesFilled;

+ (id)packetWithAudioBuffer:(NSData *)audioBufferData;

@end



