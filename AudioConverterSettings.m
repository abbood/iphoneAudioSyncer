//
//  AudioConverterSettings.m
//  Snap
//
//  Created by Abdullah Bakhach on 9/1/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "AudioConverterSettings.h"

@implementation AudioConverterSettings

@synthesize inputFormat;
@synthesize outputFormat;
@synthesize inputFile;
@synthesize outputFile;
@synthesize inputfilePacketIndex;
@synthesize inputFilePacketCount;
@synthesize inputFilePacketMaxSize;

@synthesize outputFilePacketDescriptions;

@synthesize sourceBuffer;

@synthesize readerState;
@synthesize gameObj;

@synthesize readerBuffersMutex;
@synthesize readerBufferReadyCondition;


+(id) initWithGame: (id) game
{
    AudioConverterSettings *obj = [[AudioConverterSettings alloc] init];
    obj.gameObj = game;
    return obj;
}

+(id) initialize
{
    AudioConverterSettings *obj = [[AudioConverterSettings alloc] init];
    return obj;
}

@end

