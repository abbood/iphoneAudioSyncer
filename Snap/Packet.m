//
//  Packet.m
//  Snap
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Packet.h"
#import "NSData+SnapAdditions.h"
#import "PacketSignInResponse.h"
#import "PacketMusic.h"
#import "PacketServerReady.h"
#import "PacketAudioBuffer.h"
#import "PacketClientPrimed.h"
#import "PacketPlayMusicNow.h"
#import "PacketRecieved.h"
#import "PacketRingBufferGettingFull.h"

const size_t PACKET_HEADER_SIZE = 10;
const size_t AUDIO_BUFFER_PACKET_HEADER_SIZE = 36; //63

const size_t AUDIO_BUFFER_NUMBER_OF_CHANNELS_OFFSET = 10;
const size_t AUDIO_BUFFER_DATA_BYTE_SIZE_OFFSET = 12;


// to keep in accordance with GKSession data limit (which is 1000, leave out some for header and meta data info)
// see http://developer.apple.com/library/ios/#DOCUMENTATION/NetworkingInternet/Conceptual/GameKit_Guide/GameKitConcepts/GameKitConcepts.html
const size_t MAX_PACKET_SIZE = 1500; 
const size_t MAX_PACKET_DESCRIPTIONS_SIZE = 300;
const size_t AUDIO_STREAM_PACK_DESC_SIZE = 12; // = sizeof(AudioStreamPacketDescription) - 4 b/c 
                                               // we are using UInt32 for mStartOffset rather than SInt64
                                               // reason: did not want to get into custom implementations of 
                                               // htonl-like function for 64 bits integers in C
                                               // http://stackoverflow.com/questions/3022552/is-there-any-standard-htonl-like-function-for-64-bits-integers-in-c

//#define MAX_PACKET_SIZE 900


@implementation Packet

@synthesize packetType = _packetType;
@synthesize bodyData = _bodyData;
@synthesize sendReliably = _sendReliably;

+ (id)packetWithType:(PacketType)packetType
{
	return [[[self class] alloc] initWithType:packetType];
}

+ (id)packetWithData:(NSData *)data
{
	if ([data length] < PACKET_HEADER_SIZE)
	{
		NSLog(@"Error: Packet too small");
		return nil;
	}
    
	if ([data rw_int32AtOffset:0] != 'SNAP')
	{
		NSLog(@"Error: Packet has invalid header");
		return nil;
	}
    
	PacketType packetType = [data rw_int16AtOffset:8]; 
    
    
	Packet *packet;
        
	switch (packetType)
	{
		case PacketTypeSignInRequest:
        case PacketTypeClientReady:
        case PacketTypeRingBufferGettingClear:
        case PacketTypeServerQuit:
		case PacketTypeClientQuit:
        case PacketTypeEndOfSong:
			packet = [Packet packetWithType:packetType];
			break;
            
            
		case PacketTypeSignInResponse:
			packet = [PacketSignInResponse packetWithData:data];
			break;
            
        case PacketTypeAudioBuffer:
            packet = [PacketAudioBuffer packetWithData:data];
    		break;
            
        case PacketTypeServerReady:
			packet = [PacketServerReady packetWithData:data];
			break;
            
        case PacketTypeReceived:
            packet = [PacketRecieved packetWithData:data];
            break;
            
        case PacketTypeClientPrimed:
            packet = [PacketClientPrimed packetWithData:data];
            break;
            
        case PacketTypePlayMusicNow:
            packet = [PacketPlayMusicNow packetWithData:data];
            break;
        
        case PacketTypeRingBufferGettingFull:
            packet = [PacketRingBufferGettingFull packetWithData:data];
            break;
            
            
		default:
			NSLog(@"Error: Packet has invalid type");
			return nil;
	}
    
	return packet;
}

- (id)initWithType:(PacketType)packetType
{
	if ((self = [super init]))
	{
		self.packetType = packetType;
        self.sendReliably = YES;
	}
	return self;
}

- (NSData *)data
{
	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:100];
    
	[data rw_appendInt32:'SNAP'];   // 0x534E4150
	[data rw_appendInt32:0];
	[data rw_appendInt16:self.packetType];
    
    [self addPayloadToData:data];
    
	return data;
}


- (void)addPayloadToData:(NSMutableData *)data
{
	// base class does nothing
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@, type=%d", [super description], self.packetType];
}

@end
