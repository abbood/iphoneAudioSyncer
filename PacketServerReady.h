//
//  PacketServerReady.h
//  Snap
//
//  Created by Abdullah Bakhach on 8/15/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "Packet.h"

@interface PacketServerReady : Packet

@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, readwrite) AudioStreamBasicDescription asbd;

+ (id)packetWithPlayers:(NSMutableDictionary *)players
            audioFormat:(AudioStreamBasicDescription)format;

@end