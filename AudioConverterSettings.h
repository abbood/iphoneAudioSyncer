//
//  AudioConverterSettings.h
//  Snap
//
//  Created by Abdullah Bakhach on 9/1/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMedia/CoreMedia.h>

typedef enum
{
    INITIALIZED = 0,
    STARTING_FILE_THREAD,
    WAITING_FOR_DATA,
    FILLING
} AVAssetReaderState;

@interface AudioConverterSettings : NSObject
{
    @public
        AudioStreamBasicDescription inputFormat;
        AudioStreamBasicDescription outputFormat;

        AudioFileID inputFile;
        AudioFileID outputFile;

        UInt64 inputfilePacketIndex;
        UInt64 inputFilePacketCount;
        UInt32 inputFilePacketMaxSize;

        AudioStreamPacketDescription * outputFilePacketDescriptions;

        void * sourceBuffer;

        AVAssetReaderState readerState;
        id gameObj;
    
    
        pthread_mutex_t readerBuffersMutex;			// a mutex to protect the inuse flags
        pthread_cond_t readerBufferReadyCondition;	// a condition varable for handling the inuse flags
}

@property (readwrite) AudioStreamBasicDescription inputFormat;
@property (readwrite) AudioStreamBasicDescription outputFormat;
@property (readwrite) AudioFileID inputFile;
@property (readwrite) AudioFileID outputFile;
@property (readwrite) UInt64 inputfilePacketIndex;
@property (readwrite) UInt64 inputFilePacketCount;
@property (readwrite) UInt32 inputFilePacketMaxSize;

@property (readwrite) pthread_mutex_t readerBuffersMutex;
@property (readwrite) pthread_cond_t readerBufferReadyCondition;


@property (readwrite) AudioStreamPacketDescription * outputFilePacketDescriptions;

@property (readwrite) void * sourceBuffer;

@property (readwrite) AVAssetReaderState readerState;
@property (readwrite) id gameObj;


+(id) initWithGame: (id) game;
+(id) initialize;

@end
