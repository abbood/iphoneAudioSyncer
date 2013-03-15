//
//  Player.m
//  Snap
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Player.h"

@implementation Player

@synthesize position = _position;
@synthesize name = _name;
@synthesize peerID = _peerID;
@synthesize isServer = _isServer;

@synthesize receivedResponse = _receivedResponse;
@synthesize isPrimed = _isPrimed;
@synthesize packetProfiler = _packetProfiler;
@synthesize packetDelayAvg = _packetDelayAvg;
@synthesize packetDelayMax = _packetDelayMax;

- (void)dealloc
{
#ifdef DEBUG
	NSLog(@"dealloc %@", self);
#endif
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ peerID = %@, name = %@, position = %d", [super description], self.peerID, self.name, self.position];
}

@end
