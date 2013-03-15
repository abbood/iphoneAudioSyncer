//
//  Player.h
//  Snap
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "ServerProfiler.h"

typedef enum
{
	PlayerPositionBottom,  // the user
	PlayerPositionLeft,
	PlayerPositionTop,
	PlayerPositionRight
}
PlayerPosition;

@interface Player : NSObject

@property (nonatomic, assign) PlayerPosition position;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *peerID;
@property (nonatomic, assign) BOOL receivedResponse;
@property (nonatomic, assign) BOOL isPrimed;
@property (nonatomic, assign) BOOL isServer;

@property (nonatomic, assign) double packetDelayAvg;
@property (nonatomic, assign) double packetDelayMax;

@property (nonatomic, strong) ServerProfiler *packetProfiler;


@end
