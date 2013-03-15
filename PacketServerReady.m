//
//  PacketServerReady.m
//  Snap
//
//  Created by Abdullah Bakhach on 8/15/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>
#include <AVFoundation/AVFoundation.h>
#include <CoreMedia/CoreMedia.h>

#import "PacketServerReady.h"
#import "NSData+SnapAdditions.h"
#import "Player.h"

@implementation PacketServerReady

@synthesize players = _players; 
@synthesize asbd;

+ (id)packetWithPlayers:(NSMutableDictionary *)players
            audioFormat:(AudioStreamBasicDescription)asbd
{
	return [[[self class] alloc] initWithPlayers:players
                                     audioFormat:asbd
            ];
}

- (id)initWithPlayers:(NSMutableDictionary *)players 
          audioFormat:(AudioStreamBasicDescription)format

{
	if ((self = [super initWithType:PacketTypeServerReady]))
	{
		self.players = players;
        self.asbd = format;

	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendInt8:[self.players count]];
    
	[self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop)
     {
         [data rw_appendString:player.peerID];
         [data rw_appendString:player.name];
         [data rw_appendInt8:player.position];
     }];
    
    
    // appending asbd to packet
    [data rw_appendInt32:(UInt32)asbd.mSampleRate];
    [data rw_appendInt32:asbd.mFormatID];
    [data rw_appendInt32:asbd.mFormatFlags];
    [data rw_appendInt32:asbd.mBytesPerPacket];
    [data rw_appendInt32:asbd.mFramesPerPacket];
    [data rw_appendInt32:asbd.mBytesPerFrame];
    [data rw_appendInt32:asbd.mChannelsPerFrame];
    [data rw_appendInt32:asbd.mBitsPerChannel];
    [data rw_appendInt32:asbd.mReserved];    
}

+ (id)packetWithData:(NSData *)data
{
	NSMutableDictionary *players = [NSMutableDictionary dictionaryWithCapacity:4];
    
	size_t offset = PACKET_HEADER_SIZE;
	size_t count;
    
	int numberOfPlayers = [data rw_int8AtOffset:offset];
	offset += 1;
    
	for (int t = 0; t < numberOfPlayers; ++t)
	{
		NSString *peerID = [data rw_stringAtOffset:offset bytesRead:&count];
		offset += count;
        
		NSString *name = [data rw_stringAtOffset:offset bytesRead:&count];
		offset += count;
        
		PlayerPosition position = [data rw_int8AtOffset:offset];
		offset += 1;
        
		Player *player = [[Player alloc] init];
		player.peerID = peerID;
		player.name = name;
		player.position = position;
		[players setObject:player forKey:player.peerID];
	}
        
    
    AudioStreamBasicDescription format = {0};
    format.mSampleRate = [[data subdataWithRange:NSMakeRange(offset, 4)] rw_int32AtOffset:0];
    offset+=sizeof(UInt32);            
    
    format.mFormatID = [[data subdataWithRange:NSMakeRange(offset, 4)] rw_int32AtOffset:0];
    offset+=sizeof(UInt32);
    
    format.mFormatFlags = [[data subdataWithRange:NSMakeRange(offset, 4)] rw_int32AtOffset:0];
    offset+=sizeof(UInt32);

    format.mBytesPerPacket = [[data subdataWithRange:NSMakeRange(offset, 4)] rw_int32AtOffset:0];
    offset+=sizeof(UInt32);
    
    format.mFramesPerPacket = [[data subdataWithRange:NSMakeRange(offset, 4)] rw_int32AtOffset:0];
    offset+=sizeof(UInt32);
    
    format.mBytesPerFrame = [[data subdataWithRange:NSMakeRange(offset, 4)] rw_int32AtOffset:0];
    offset+=sizeof(UInt32);        
    
    format.mChannelsPerFrame = [[data subdataWithRange:NSMakeRange(offset, 4)] rw_int32AtOffset:0];  
    offset+=sizeof(UInt32);
    
    format.mBitsPerChannel = [[data subdataWithRange:NSMakeRange(offset, 4)] rw_int32AtOffset:0];    
    offset+=sizeof(UInt32);
    
    format.mReserved = [[data subdataWithRange:NSMakeRange(offset, 4)] rw_int32AtOffset:0];              
    
	return [[self class] packetWithPlayers:players audioFormat:format];
}

-(void)assignMusicProperties:(MPMediaItemCollection*)userMediaItemCollection
{
    NSArray *items = [userMediaItemCollection items];    
    
    MPMediaItem *item = [items objectAtIndex:0];
    NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];       
    
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];        
    AVAssetTrack* track = [songAsset.tracks objectAtIndex:0];    
    
    asbd = [self getTrackNativeSettings:track];        
}


-(AudioStreamBasicDescription)getTrackNativeSettings:(AVAssetTrack *) track
{    
    CMFormatDescriptionRef formDesc = (__bridge CMFormatDescriptionRef)[[track formatDescriptions] objectAtIndex:0];
    const AudioStreamBasicDescription* asbdPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formDesc);
    //because this is a pointer and not a struct we need to move the data into a struct so we can use it
    AudioStreamBasicDescription format = {0};
    memcpy(&format, asbdPointer, sizeof(format));
    //asbd now contains a basic description for the track
    return format;    
}






@end