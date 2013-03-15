//
//  PacketAudioBuffer.m
//  Snap
//
//  Created by Abdullah Bakhach on 8/28/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//
#import "PacketAudioBuffer.h"
#import "NSData+SnapAdditions.h"

@implementation PacketAudioBuffer

@synthesize audioBufferData = _audioBufferData;
@synthesize packetID = _packetID;
@synthesize packetNumber = _packetNumber;
@synthesize packetBytesFilled = _packetBytesFilled;
@synthesize packetDescriptionsBytesFilled =_packetDescriptionsBytesFilled;
@synthesize packetDescriptionsData = _packetDescriptionsData;
@synthesize totalSize = _totalSize;


+ (id)packetWithData:(NSData *)data
{

    int totalSize = [data length];
    int packetNumber = [data rw_int32AtOffset:4];

    
	return [[self class] packetWithAudioBuffer:data
                                     totalSize:totalSize
                                  packetNumber:packetNumber

            ];
}

+ (id)packetWithAudioBuffer:(NSData *)data 
                  totalSize:(UInt32)totalSize
               packetNumber:(UInt32)packetNumber
    {
	return [[[self class] alloc] initWithAudioBufferData:data
                                               totalSize:totalSize
                                            packetNumber:packetNumber
            ];
}

- (id)initWithAudioBufferData:(NSData *)data
                    totalSize:(UInt32)totalSize
               packetNumber:(UInt32)packetNumber
{
	if ((self = [super initWithType:PacketTypeAudioBuffer]))
	{
        
         
		self.audioBufferData = data;
        self.totalSize = totalSize;
        self.packetNumber = packetNumber;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendString:self.audioBufferData];
}



@end
