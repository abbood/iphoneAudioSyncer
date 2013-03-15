//
//  ConcurrentOp.h
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

#include "AudioStreamer.h"
#include "AudioItem.h"
#include "AudioFile.h"


@class AudioStreamer;




@interface ConcurrentOp : NSOperation
{
    size_t bytesFilled;	
    NSData *audioItemLocalCopy;
    NSString * audioFileURL;
    
    UInt32 bufferByteSize;
    UInt32 numPacketsToRead;
    AudioFileID audioFileID;
    AudioFile *audioFile;
    SInt64 inStartingPacket;

}
@property (assign) BOOL failInSetup;
@property (readwrite) BOOL isSongChanged;


@property (nonatomic, strong) NSString * audioFileURL;
@property (readwrite) AudioFileID audioFileID;

@property (nonatomic, strong) AudioFile *audioFile;

@property (nonatomic, strong) AudioStreamer * streamer;


@property (nonatomic, strong) NSThread *thread;			// only exposed to demonstrate that users of this can message it on its own thread.
@property (nonatomic, strong) NSMutableData *webData;	// when the operation is over, fetch the data - no contention


- (void)setStreamer:(AudioStreamer *)audioStreamer;
+ (void)postNotification:(NSNotification *)aNotification;

//- (void)wakeUp;				// should be run on the operation's thread - could create a convenience method that does this then hide thread
- (void)finish;				// should be run on the operation's thread - could create a convenience method that does this then hide thread
- (void)runConnection;		// convenience method - messages using proper thread
- (void)cancel;				// subclassed convenience method

@end
