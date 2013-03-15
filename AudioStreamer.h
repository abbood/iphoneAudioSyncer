//
//  AudioStreamer.h
//  StreamingAudioPlayer
//
//  Created by Matt Gallagher on 27/09/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

			
#import <UIKit/UIKit.h>

#include <pthread.h>
#include <AudioToolbox/AudioToolbox.h>

#include "AudioPool.h"
#include "Packet.h"
#include "ConcurrentOp.h"
#include "Game.h"


#define LOG_QUEUED_BUFFERS 1

#define kPlaybackFileLocation	CFSTR("ipod-library://item/item.m4a?id=1053020204400037178")


#define kNumAQBufs 24			// Number of audio queue buffers we allocate. (Formerly 16)
// Needs to be big enough to keep audio pipeline
// busy (non-zero number of queued buffers) but
// not so big that audio takes too long to begin
// (kNumAQBufs * kAQBufSize of data must be
// loaded before playback will start).
// Set LOG_QUEUED_BUFFERS to 1 to log how many
// buffers are queued at any time -- if it drops
// to zero too often, this value may need to
// increase. Min 3, typical 8-24.
// we chose 32784 b/c that's the size of packets we're getting 
#define kAQDefaultBufSize 2048	// Number of bytes in each audio queue buffer
// Needs to be big enough to hold a packet of
// audio from the audio file. If number is too
// large, queuing of audio before playback starts
// will take too long.
// Highly compressed files can use smaller
// numbers (512 or less). 2048 should hold all
// but the largest packets. A buffer size error
// will occur if this number is too small.

#define kAQMaxPacketDescs 6	// Number of packet descriptions in our array (formerly 512)

#define networkTimeOutTime 5
bool interruptedOnPlayback;

typedef enum
	{
		AS_INITIALIZED = 0,
		AS_STARTING_FILE_THREAD,
		AS_WAITING_FOR_DATA,
		AS_WAITING_FOR_QUEUE_TO_START,
        AS_READY_TO_PLAY,
		AS_PLAYING,
		AS_BUFFERING,
		AS_STOPPING,
		AS_STOPPED,
		AS_PAUSED
	} AudioStreamerState;

typedef enum
	{
		AS_NO_STOP = 0,
		AS_STOPPING_EOF,
		AS_STOPPING_USER_ACTION,
		AS_STOPPING_ERROR,
		AS_STOPPING_TEMPORARILY
	} AudioStreamerStopReason;

typedef enum
	{
		AS_NO_ERROR = 0,
		AS_NETWORK_CONNECTION_FAILED,
		AS_FILE_STREAM_GET_PROPERTY_FAILED,
		AS_FILE_STREAM_SEEK_FAILED,
		AS_FILE_STREAM_PARSE_BYTES_FAILED,
		AS_FILE_STREAM_OPEN_FAILED,
		AS_FILE_STREAM_CLOSE_FAILED,
		AS_AUDIO_DATA_NOT_FOUND,
		AS_AUDIO_QUEUE_CREATION_FAILED,
		AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED,
		AS_AUDIO_QUEUE_ENQUEUE_FAILED,
		AS_AUDIO_QUEUE_ADD_LISTENER_FAILED,
		AS_AUDIO_QUEUE_REMOVE_LISTENER_FAILED,
		AS_AUDIO_QUEUE_START_FAILED,
		AS_AUDIO_QUEUE_PAUSE_FAILED,
		AS_AUDIO_QUEUE_BUFFER_MISMATCH,
		AS_AUDIO_QUEUE_DISPOSE_FAILED,
		AS_AUDIO_QUEUE_STOP_FAILED,
		AS_AUDIO_QUEUE_FLUSH_FAILED,
		AS_AUDIO_STREAMER_FAILED,
		AS_GET_AUDIO_TIME_FAILED,
		AS_AUDIO_BUFFER_TOO_SMALL,
        ABSD_SETUP_FAILED
	} AudioStreamerErrorCode;



extern NSString * const ASStatusChangedNotification;

@class Game;

@interface AudioStreamer : NSObject
{
    @public
        NSURL *url;
    
        CFURLRef cfURL;
        
        //
        // Special threading consideration:
        //	The audioQueue property should only ever be accessed inside a
        //	synchronized(self) block and only *after* checking that ![self isFinishing]
        //
        AudioQueueRef audioQueue;
        AudioFileStreamID audioFileStream;	// the audio file stream parser
        AudioStreamBasicDescription asbd;	// description of the audio
        
        AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];		// audio queue buffers
        AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];	// packet descriptions for enqueuing audio
        UInt32 fillBufferIndex;	// the index of the audioQueueBuffer that is being filled
        size_t bytesFilled;				// how many bytes have been filled
        size_t byteOffset;  
        size_t packetsFilled;			// how many packets have been filled
        bool inuse[kNumAQBufs];			// flags to indicate that a buffer is still in use
        NSInteger buffersUsed;
    

        UInt64 audioDataByteCount;  // Used when the actual number of audio bytes in
        // the file is known (more accurate than assuming
        // the whole file is audio)
    
    	NSInteger fileLength;		// Length of the file in bytes
        
        AudioStreamerState state;
        double delayTime;
        AudioStreamerStopReason stopReason;
        AudioStreamerErrorCode errorCode;
        OSStatus err;
        
        bool discontinuous;			// flag to indicate middle of the stream
        
        pthread_mutex_t queueBuffersMutex;			// a mutex to protect the inuse flags
        pthread_cond_t queueBufferReadyCondition;	// a condition varable for handling the inuse flags
        
        CFReadStreamRef stream;
        NSNotificationCenter *notificationCenter;
        
        NSUInteger dataOffset;
        UInt32 bitRate;
        
        bool seekNeeded;
        double seekTime;
        double sampleRate;
        double lastProgress;
        int numBuffersToEnqueueLater;
    
        //from book
        Boolean isDone;
        SInt64 packetPosition;
        UInt32 numPacketsToRead;  
    
    	double packetDuration;		// sample rate times frames per packet
    	UInt32 packetBufferSize;


    
        Boolean isAudioItemSet;
        Boolean isStreamerSet;
    
    

    
        NSString * currentSong; // used to indicate which song we're currently sending data about/reading from
        bool isSongChanged;
    
        UInt32 totalBytesReceived;
        UInt32 totalBytesRead;
        UInt32 totalBytesHandeled;
    
        VirtualRingBuffer *ringBuffer;   //reference to a ring buffer
        UInt32 allBytesAvailable;
    
        Game * _game;
        Player *_localPlayerObj;
        NSTimer * ringBufferReaderTimer;
    
}



@property (nonatomic) AudioStreamerErrorCode errorCode;
@property (nonatomic, readwrite) OSStatus err;
@property (nonatomic, readwrite) AudioStreamerState state;
@property (nonatomic, readwrite) size_t bytesFilled;
@property (nonatomic, readwrite) size_t byteOffset;
@property (nonatomic, readonly) double progress;
@property (nonatomic, readwrite) UInt32 bitRate;
@property (nonatomic, readwrite) 	AudioFileStreamID audioFileStream;

@property (nonatomic, readwrite) pthread_mutex_t queueBuffersMutex;
@property (nonatomic, readwrite) pthread_cond_t queueBufferReadyCondition;

@property (nonatomic, readwrite) Boolean isDone;
@property (nonatomic, readwrite) SInt64 packetPosition;
@property (nonatomic, readwrite) UInt32 numPacketsToRead;

// we copy this to avoid an overrite by the ring buffer read thread
//@property (nonatomic, copy) NSData *ringBufferReadData;







- (id)initWithURL:(NSURL *)aURL;
- (id)initWithCFURL:(CFURLRef)aCFURL;
- (id)initWithRingBuffer:(VirtualRingBuffer *)ringBuff
          bufferByteSize:(UInt32)bufferByteSize
        numPacketsToRead:(UInt32)numPacketsToRead
                 gameObj:(Game *)game;
- (id)initStreamer;
- (void)start;
- (void)startInternal;
- (void)stop;
- (void)pause;
- (BOOL)isPlaying;
- (BOOL)isPaused;
- (BOOL)isWaiting;
- (BOOL)isIdle;
- (void)handleReadGKSessionData:(NSData *)data;
- (void)failWithErrorCode:(AudioStreamerErrorCode)anErrorCode;
- (void)handleAudioPackets:(const void *)inInputData
               numberBytes:(UInt32)inNumberBytes
             numberPackets:(UInt32)inNumberPackets
        packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions;

-(void)handleContainerPackets:(const void *)inInputData
                  numberBytes:(UInt32)inNumberBytes;


void ASPropertyListenerProc(	void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags);

void ASPacketsProc(				void *							inClientData,
                   UInt32							inNumberBytes,
                   UInt32							inNumberPackets,
                   const void *					inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions);


void MyAudioQueueOutputCallback(	void*					inClientData, 
                                AudioQueueRef			inAQ, 
                                AudioQueueBufferRef		inBuffer);

void MyAudioQueueOutputCallback2(	void*					inClientData, 
                                AudioQueueRef			inAQ, 
                                AudioQueueBufferRef		inBuffer);


void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

@end






