//
//  PacketMusic.m
//  Snap
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "PacketMusic.h"
#import "NSData+SnapAdditions.h"

@implementation PacketMusic

@synthesize musicData = _musicData;

+ (id)packetWithData:(NSData *)data
{
    
    size_t size = [data length];
    short * buffer = (short *)malloc(size);
    short* theBytes = [data bytes]; 
    short offset = PACKET_HEADER_SIZE/2;
    
    
    memcpy(buffer, (short *)(theBytes + offset), size - PACKET_HEADER_SIZE);
    
    NSData* musicData = [NSData dataWithBytes:buffer length:size - PACKET_HEADER_SIZE];
    free(buffer);

    
	return [[self class] packetWithMusicData:musicData];
}

+ (id)packetWithMusicData:(NSData *)musicData
{
	return [[[self class] alloc] initWithMusicData:musicData];
}

- (id)initWithMusicData:(NSData *)musicData
{
	if ((self = [super initWithType:PacketTypeMusic]))
	{
		self.musicData = musicData;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendString:self.musicData];
}



@end
