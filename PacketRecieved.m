//
//  PacketRecieved.m
//  Snap
//
//  Created by Abdullah Bakhach on 10/9/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "PacketRecieved.h"
#import "NSData+SnapAdditions.h"

@implementation PacketRecieved

@synthesize packetNumber = _packetNumber;

+ (id)packetWithData:(NSData *)data
{
    UInt32 packetNumber = [[NSData dataWithBytes:(void *)([data bytes]+PACKET_HEADER_SIZE) 
                                          length:sizeof(UInt32)] rw_int32AtOffset:0];
    return [[self class] packetWithNumber:packetNumber];    
}

+ (id)packetWithNumber:(UInt32)packetNumber
{
    return [[[self class] alloc] initWithNumber:packetNumber];
}

- (id)initWithNumber:(UInt32)packetNumber
{
    if ((self = [super initWithType:PacketTypeReceived]))
    {
        self.packetNumber = packetNumber;
    }
    return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{    
    [data rw_appendInt32:self.packetNumber];        
}

@end
