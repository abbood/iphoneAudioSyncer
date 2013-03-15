#import "AudioStreamer.h"
#ifdef TARGET_OS_IPHONE			
#import <CFNetwork/CFNetwork.h>
#endif

#import "NSData+SnapAdditions.h"
#import "PacketClientPrimed.h"

NSString * const ASStatusChangedNotification = @"ASStatusChangedNotification";

NSString * const AS_NO_ERROR_STRING = @"No error.";
NSString * const AS_FILE_STREAM_GET_PROPERTY_FAILED_STRING = @"File stream get property failed.";
NSString * const AS_FILE_STREAM_SEEK_FAILED_STRING = @"File stream seek failed.";
NSString * const AS_FILE_STREAM_PARSE_BYTES_FAILED_STRING = @"Parse bytes failed.";
NSString * const AS_FILE_STREAM_OPEN_FAILED_STRING = @"Open audio file stream failed.";
NSString * const AS_FILE_STREAM_CLOSE_FAILED_STRING = @"Close audio file stream failed.";
NSString * const AS_AUDIO_QUEUE_CREATION_FAILED_STRING = @"Audio queue creation failed.";
NSString * const AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED_STRING = @"Audio buffer allocation failed.";
NSString * const AS_AUDIO_QUEUE_ENQUEUE_FAILED_STRING = @"Queueing of audio buffer failed.";
NSString * const AS_AUDIO_QUEUE_ADD_LISTENER_FAILED_STRING = @"Audio queue add listener failed.";
NSString * const AS_AUDIO_QUEUE_REMOVE_LISTENER_FAILED_STRING = @"Audio queue remove listener failed.";
NSString * const AS_AUDIO_QUEUE_START_FAILED_STRING = @"Audio queue start failed.";
NSString * const AS_AUDIO_QUEUE_BUFFER_MISMATCH_STRING = @"Audio queue buffers don't match.";
NSString * const AS_AUDIO_QUEUE_DISPOSE_FAILED_STRING = @"Audio queue dispose failed.";
NSString * const AS_AUDIO_QUEUE_PAUSE_FAILED_STRING = @"Audio queue pause failed.";
NSString * const AS_AUDIO_QUEUE_STOP_FAILED_STRING = @"Audio queue stop failed.";
NSString * const AS_AUDIO_DATA_NOT_FOUND_STRING = @"No audio data found.";
NSString * const AS_AUDIO_QUEUE_FLUSH_FAILED_STRING = @"Audio queue flush failed.";
NSString * const AS_GET_AUDIO_TIME_FAILED_STRING = @"Audio queue get current time failed.";
NSString * const AS_AUDIO_STREAMER_FAILED_STRING = @"Audio playback failed";
NSString * const AS_NETWORK_CONNECTION_FAILED_STRING = @"Network connection failed";
NSString * const AS_AUDIO_BUFFER_TOO_SMALL_STRING = @"Audio packets are larger than kAQBufSize.";
NSString * const ABSD_SETUP_FAILED_STRING = @"could not set up ABSD format.";



@interface AudioStreamer ()



- (void)handlePropertyChangeForFileStream:(AudioFileStreamID)inAudioFileStream
	fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID
	ioFlags:(UInt32 *)ioFlags;
- (void)handleAudioPackets:(const void *)inInputData
	numberBytes:(UInt32)inNumberBytes
	numberPackets:(UInt32)inNumberPackets
	packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions;
- (void)handleBufferCompleteForQueue:(AudioQueueRef)inAQ
	buffer:(AudioQueueBufferRef)inBuffer;
- (void)handlePropertyChangeForQueue:(AudioQueueRef)inAQ
	propertyID:(AudioQueuePropertyID)inID;

#ifdef TARGET_OS_IPHONE
- (void)handleInterruptionChangeToState:(AudioQueuePropertyID)inInterruptionState;
void interruptionListenerCallback( void    *inUserData, UInt32    interruptionState ); 		
#endif

- (void)enqueueBuffer;
- (void)handleReadFromStream:(CFReadStreamRef)aStream
	eventType:(CFStreamEventType)eventType;

@end

#pragma mark Audio Callback Function Prototypes


void audioCallback( void *inUserData, AudioQueueRef inQueue, AudioQueueBufferRef inBuffer ); 
void MyAudioQueueOutputCallback(void* inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

OSStatus MyEnqueueBuffer(AudioStreamer* myData);

#ifdef TARGET_OS_IPHONE			
void MyAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState);
#endif



#pragma mark Audio Callback Function Implementations

//
// MyPropertyListenerProc
//
// Receives notification when the AudioFileStream has audio packets to be
// played. In response, this function creates the AudioQueue, getting it
// ready to begin playback (playback won't begin until audio packets are
// sent to the queue in MyEnqueueBuffer).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// kAudioQueueProperty_IsRunning listening added.
//


void audioCallback( void *inUserData, AudioQueueRef inQueue, AudioQueueBufferRef inBuffer ) {
	
	// //NSLog(@"audio callback");
	int numBuffersToEnqueueLater;
	AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];
    
    // fill it up
    inBuffer->mAudioDataByteSize = inBuffer->mAudioDataBytesCapacity;
    
  //getSoundSamples( (Uint8 *)inBuffer->mAudioData, (Uint8 *)inBuffer->mAudioDataByteSize );
    
 OSStatus    err = AudioQueueEnqueueBuffer( inQueue,
										   inBuffer,
										   0,
										   NULL );
    if( err ) {
        printf( "Error on AudioQueueEnqueueBuffer: %4s\n", (char*)&err );
        
        audioQueueBuffer[ numBuffersToEnqueueLater ] = inBuffer;
        numBuffersToEnqueueLater++;
	}
}

//
// ASPropertyListenerProc
//
// Receives notification when the AudioFileStream has audio packets to be
// played. In response, this function creates the AudioQueue, getting it
// ready to begin playback (playback won't begin until audio packets are
// sent to the queue in ASEnqueueBuffer).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// kAudioQueueProperty_IsRunning listening added.
//
void ASPropertyListenerProc(	void *							inClientData,
								AudioFileStreamID				inAudioFileStream,
								AudioFileStreamPropertyID		inPropertyID,
								UInt32 *						ioFlags)
{	
    
         //NSLog(@"STREAMER: ASPropertyListenerProc");
	// this is called by audio file stream when it finds property values
	AudioStreamer* streamer = (AudioStreamer *)inClientData;
    
    
	[streamer
		handlePropertyChangeForFileStream:inAudioFileStream
		fileStreamPropertyID:inPropertyID
		ioFlags:ioFlags];
}


//
// MyPacketsProc
//
// When the AudioStream has packets to be played, this function gets an
// idle audio buffer and copies the audio packets into it. The calls to
// MyEnqueueBuffer won't return until there are buffers available (or the
// playback has been stopped).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// CBR functionality added.
//
void ASPacketsProc(				void *							inClientData,
								UInt32							inNumberBytes,
								UInt32							inNumberPackets,
								const void *					inInputData,
								AudioStreamPacketDescription	*inPacketDescriptions)
{
    
     //NSLog(@"STREAMER: ASPacketsProc");
	// this is called by audio file stream when it finds packets of audio
	AudioStreamer* streamer = (AudioStreamer *)inClientData;
	[streamer
		handleAudioPackets:inInputData
		numberBytes:inNumberBytes
		numberPackets:inNumberPackets
		packetDescriptions:inPacketDescriptions];
}

//
// MyAudioQueueOutputCallback
//
// Called from the AudioQueue when playback of specific buffers completes. This
// function signals from the AudioQueue thread to the AudioStream thread that
// the buffer is idle and available for copying data.
//
// This function is unchanged from Apple's example in AudioFileStreamExample.
//
void MyAudioQueueOutputCallback(	void*					inClientData, 
									AudioQueueRef			inAQ, 
									AudioQueueBufferRef		inBuffer)
{
	// this is called by the audio queue when it has finished decoding our data. 
	// The buffer is now free to be reused.
	AudioStreamer* streamer = (AudioStreamer*)inClientData;
	[streamer handleBufferCompleteForQueue:inAQ buffer:inBuffer];
}

void MyAudioQueueOutputCallback2(	void*					inClientData, 
                                AudioQueueRef			inAQ, 
                                AudioQueueBufferRef		inCompleteAQBuffer)
{
	AudioStreamer* streamer = (AudioStreamer*)inClientData;
    if (streamer.isDone) return;
    
    
}

//
// MyAudioQueueIsRunningCallback
//
// Called from the AudioQueue when playback is started or stopped. This
// information is used to toggle the observable "isPlaying" property and
// set the "finished" flag.
//
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
	AudioStreamer* streamer = (AudioStreamer *)inUserData;
	[streamer handlePropertyChangeForQueue:inAQ propertyID:inID];
}

#ifdef TARGET_OS_IPHONE			
//
// MyAudioSessionInterruptionListener
//
// Invoked if the audio session is interrupted (like when the phone rings)
//
void MyAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	
	// //NSLog(@"Audio session interruption");
	
	AudioStreamer* streamer = (AudioStreamer *)inClientData;
	[streamer handleInterruptionChangeToState:inInterruptionState];
}


void interruptionListenerCallback (void *inUserData, UInt32 interruptionState) {
	
	// This callback, being outside the implementation block, needs a reference 
	//to the AudioPlayer object
	AudioStreamer *player = (AudioStreamer *)inUserData;
	
	if (interruptionState == kAudioSessionBeginInterruption) {
		// //NSLog(@"kAudioSessionBeginInterruption");
        //if ([player audioStreamer]) {
			// if currently playing, pause
			[player pause];
			interruptedOnPlayback = YES;
        //}
		
	}// else if ((interruptionState == kAudioSessionEndInterruption) && player.interruptedOnPlayback) {
		else if (interruptionState == kAudioSessionEndInterruption) {
			// //NSLog(@"kAudioSessionEndInterruption");
			  AudioSessionSetActive( true );

        // if the interruption was removed, and the app had been playing, resume playback
        [player start];
        interruptedOnPlayback = NO;
			//	player.state = AS_PAUSED;
	}
}

#endif

#pragma mark CFReadStream Callback Function Implementations

//
// ReadStreamCallBack
//
// This is the callback for the CFReadStream from the network connection. This
// is where all network data is passed to the AudioFileStream.
//
// Invoked when an error occurs, the stream ends or we have data to read.
//
void ASReadStreamCallBack
(
   CFReadStreamRef aStream,
   CFStreamEventType eventType,
   void* inClientInfo
)
{
	AudioStreamer* streamer = (AudioStreamer *)inClientInfo;
	[streamer handleReadFromStream:aStream eventType:eventType];
}

@implementation AudioStreamer

@synthesize errorCode;
@synthesize err;
@synthesize state;
@synthesize bytesFilled;
@synthesize byteOffset;
@synthesize bitRate;
@dynamic progress;
@synthesize audioFileStream;

@synthesize queueBuffersMutex;
@synthesize queueBufferReadyCondition;

@synthesize isDone;
@synthesize numPacketsToRead;
@synthesize packetPosition;






- (id)initStreamer
{
    
	self = [super init];
    //audioPool = [[AudioPool init] alloc];
    return self;
}


//
// initWithURL
//
// Init method for the object.
//
- (id)initWithURL:(NSURL *)aURL
{
	self = [super init];
	if (self != nil)
	{
		url = [aURL retain];
	}
	
	
	AudioSessionInitialize( NULL,
						   NULL,
						   interruptionListenerCallback,
						   self );
	  AudioSessionSetActive( true );
    
 	
	return self;
}


//
// initWithURL
//
// Init method for the object.
//
- (id)initWithCFURL:(CFURLRef)aCFURL
{
	self = [super init];
	if (self != nil)
	{
		cfURL = aCFURL;
	}
	
	
	AudioSessionInitialize( NULL,
						   NULL,
						   interruptionListenerCallback,
						   self );
    AudioSessionSetActive( true );
    
 	
	return self;
}

- (id)initWithRingBuffer:(VirtualRingBuffer *)ringBuff
          bufferByteSize:(UInt32)bufferByteSize
        numPacketsToRead:(UInt32)numPacketsToRead
                gameObj:(Game *)game    
{
	self = [super init];
	if (self != nil)
	{
		ringBuffer = ringBuff;
        packetBufferSize = bufferByteSize;    
        _game = game;
	}
	
    
	
	AudioSessionInitialize( NULL,
						   NULL,
						   interruptionListenerCallback,
						   self );
    AudioSessionSetActive( true );
    
 	
	return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[self stop];
	[notificationCenter release];
	[url release];
	[super dealloc];
}

//
// isFinishing
//
// returns YES if the audio has reached a stopping condition.
//
- (BOOL)isFinishing
{
	@synchronized (self)
	{
		if ((errorCode != AS_NO_ERROR && state != AS_INITIALIZED) ||
			((state == AS_STOPPING || state == AS_STOPPED) &&
				stopReason != AS_STOPPING_TEMPORARILY))
		{
			return YES;
		}
	}
	
	return NO;
}

//
// runLoopShouldExit
//
// returns YES if the run loop should exit.
//
- (BOOL)runLoopShouldExit
{
	@synchronized(self)
	{
		if (errorCode != AS_NO_ERROR ||
			(state == AS_STOPPED &&
             stopReason != AS_STOPPING_TEMPORARILY) || [self hasNetworkTimedOut])
            
		{
            [self printState:state];
          //  NSLog(@"CLIENT: runLOOP SHOULD EXIT!!");

            return YES;
		} else {
		//	NSLog(@"CLIENT: run loop shouldn't exit!!");
        }
	}
	
	return NO;
}

-(void)printState:(AudioStreamerState)state
{
    switch (state) {
        case AS_INITIALIZED:
            NSLog(@"AudioStreamerState: AS_INITIALIZED");
            break;
            
        case AS_STARTING_FILE_THREAD:
            NSLog(@"AudioStreamerState: AS_STARTING_FILE_THREAD");
            break;
            
        case AS_WAITING_FOR_DATA:
            NSLog(@"AudioStreamerState: AS_WAITING_FOR_DATA");
            break;
            
        case AS_WAITING_FOR_QUEUE_TO_START:
            NSLog(@"AudioStreamerState: AS_WAITING_FOR_QUEUE_TO_START");
            break;
            
        case AS_READY_TO_PLAY:
            NSLog(@"AudioStreamerState: AS_READY_TO_PLAY");
            break;
            
        case AS_PLAYING:
            NSLog(@"AudioStreamerState: AS_PLAYING");
            break;
            
        case AS_BUFFERING:
            NSLog(@"AudioStreamerState: AS_BUFFERING");
            break;

        case AS_STOPPING:
            NSLog(@"AudioStreamerState: AS_STOPPING");
            break;
            
        case AS_STOPPED:
            NSLog(@"AudioStreamerState: AS_STOPPED");
            break;
            
        case AS_PAUSED:
            NSLog(@"AudioStreamerState: AS_PAUSED");
            break;
            
        default:
            break;
    }
    
    
}

-(BOOL)hasNetworkTimedOut
{
    if (PacketTypeEndOfSong) {
        // if host reached end of song, then we don't worry about receiving any more packets
        return NO;
    }
    
    double curTime = [Timer getCurTime];
    double timeElapsedSinceLastPacket = [Timer getTimeDifference:_game->lastAudioPacketTimeStamp
                                                           time2:curTime];
    
    BOOL hasNetworkTimedOut = (timeElapsedSinceLastPacket > networkTimeOutTime);
    
    if (hasNetworkTimedOut) {
        NSLog(@"network timed out! b/c cur time is %f and last packet time is %f, differnece is %f",curTime, _game->lastAudioPacketTimeStamp,timeElapsedSinceLastPacket);
    } else {
        NSLog(@"network DID NOT timed out! b/c cur time is %f and last packet time is %f, differnece is %f",curTime, _game->lastAudioPacketTimeStamp,timeElapsedSinceLastPacket);
    }
    
    return (hasNetworkTimedOut);
}


//
// stringForErrorCode:
//
// Converts an error code to a string that can be localized or presented
// to the user.
//
// Parameters:
//    anErrorCode - the error code to convert
//
// returns the string representation of the error code
//
+ (NSString *)stringForErrorCode:(AudioStreamerErrorCode)anErrorCode
{
	switch (anErrorCode)
	{
		case AS_NO_ERROR:
			return AS_NO_ERROR_STRING;
		case AS_FILE_STREAM_GET_PROPERTY_FAILED:
			return AS_FILE_STREAM_GET_PROPERTY_FAILED_STRING;
		case AS_FILE_STREAM_SEEK_FAILED:
			return AS_FILE_STREAM_SEEK_FAILED_STRING;
		case AS_FILE_STREAM_PARSE_BYTES_FAILED:
			return AS_FILE_STREAM_PARSE_BYTES_FAILED_STRING;
		case AS_AUDIO_QUEUE_CREATION_FAILED:
			return AS_AUDIO_QUEUE_CREATION_FAILED_STRING;
		case AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED:
			return AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED_STRING;
		case AS_AUDIO_QUEUE_ENQUEUE_FAILED:
			return AS_AUDIO_QUEUE_ENQUEUE_FAILED_STRING;
		case AS_AUDIO_QUEUE_ADD_LISTENER_FAILED:
			return AS_AUDIO_QUEUE_ADD_LISTENER_FAILED_STRING;
		case AS_AUDIO_QUEUE_REMOVE_LISTENER_FAILED:
			return AS_AUDIO_QUEUE_REMOVE_LISTENER_FAILED_STRING;
		case AS_AUDIO_QUEUE_START_FAILED:
			return AS_AUDIO_QUEUE_START_FAILED_STRING;
		case AS_AUDIO_QUEUE_BUFFER_MISMATCH:
			return AS_AUDIO_QUEUE_BUFFER_MISMATCH_STRING;
		case AS_FILE_STREAM_OPEN_FAILED:
			return AS_FILE_STREAM_OPEN_FAILED_STRING;
		case AS_FILE_STREAM_CLOSE_FAILED:
			return AS_FILE_STREAM_CLOSE_FAILED_STRING;
		case AS_AUDIO_QUEUE_DISPOSE_FAILED:
			return AS_AUDIO_QUEUE_DISPOSE_FAILED_STRING;
		case AS_AUDIO_QUEUE_PAUSE_FAILED:
			return AS_AUDIO_QUEUE_DISPOSE_FAILED_STRING;
		case AS_AUDIO_QUEUE_FLUSH_FAILED:
			return AS_AUDIO_QUEUE_FLUSH_FAILED_STRING;
		case AS_AUDIO_DATA_NOT_FOUND:
			return AS_AUDIO_DATA_NOT_FOUND_STRING;
		case AS_GET_AUDIO_TIME_FAILED:
			return AS_GET_AUDIO_TIME_FAILED_STRING;
		case AS_NETWORK_CONNECTION_FAILED:
			return AS_NETWORK_CONNECTION_FAILED_STRING;
		case AS_AUDIO_QUEUE_STOP_FAILED:
			return AS_AUDIO_QUEUE_STOP_FAILED_STRING;
		case AS_AUDIO_STREAMER_FAILED:
			return AS_AUDIO_STREAMER_FAILED_STRING;
		case AS_AUDIO_BUFFER_TOO_SMALL:
			return AS_AUDIO_BUFFER_TOO_SMALL_STRING;
        case ABSD_SETUP_FAILED:
            return ABSD_SETUP_FAILED_STRING;
		default:
			return AS_AUDIO_STREAMER_FAILED_STRING;
	}
	
	return AS_AUDIO_STREAMER_FAILED_STRING;
}

//
// failWithErrorCode:
//
// Sets the playback state to failed and logs the error.
//
// Parameters:
//    anErrorCode - the error condition
//
- (void)failWithErrorCode:(AudioStreamerErrorCode)anErrorCode
{
	@synchronized(self)
	{
		if (errorCode != AS_NO_ERROR)
		{
			// Only set the error once.
			return;
		}
		
		errorCode = anErrorCode;

		if (err)
		{
			char *errChars = (char *)&err;
			 //NSLog(@"%@ err: %c%c%c%c %d\n",
				[AudioStreamer stringForErrorCode:anErrorCode],
				errChars[3], errChars[2], errChars[1], errChars[0],
				(int)err;
		}
		else
		{
			// //NSLog(@"%@", [AudioStreamer stringForErrorCode:anErrorCode]);
		}

		if (state == AS_PLAYING ||
			state == AS_PAUSED ||
			state == AS_BUFFERING)
		{
			self.state = AS_STOPPING;
			stopReason = AS_STOPPING_ERROR;
			AudioQueueStop(audioQueue, true);
		}

#ifdef TARGET_OS_IPHONE			
		UIAlertView *alert =
			[[[UIAlertView alloc]
				initWithTitle:NSLocalizedStringFromTable(@"Audio Error", @"Errors", nil)
				message:NSLocalizedStringFromTable([AudioStreamer stringForErrorCode:self.errorCode], @"Errors", nil)
				delegate:self
				cancelButtonTitle:@"OK"
				otherButtonTitles: nil]
			autorelease];
		[alert 
			performSelector:@selector(show)
			onThread:[NSThread mainThread]
			withObject:nil
			waitUntilDone:NO];
#else
		NSAlert *alert =
			[NSAlert
				alertWithMessageText:NSLocalizedString(@"Audio Error", @"")
				defaultButton:NSLocalizedString(@"OK", @"")
				alternateButton:nil
				otherButton:nil
				informativeTextWithFormat:[AudioStreamer stringForErrorCode:self.errorCode]];
		[alert
			performSelector:@selector(runModal)
			onThread:[NSThread mainThread]
			withObject:nil
			waitUntilDone:NO];
#endif
	}
}

//
// setState:
//
// Sets the state and sends a notification that the state has changed.
//
// This method
//
// Parameters:
//    anErrorCode - the error condition
//
- (void)setState:(AudioStreamerState)aStatus
{
	@synchronized(self)
	{
		if (state != aStatus)
		{
			state = aStatus;
			
			NSNotification *notification =
				[NSNotification
					notificationWithName:ASStatusChangedNotification
					object:self];
			[notificationCenter
				performSelector:@selector(postNotification:)
				onThread:[NSThread mainThread]
				withObject:notification
				waitUntilDone:NO];
		}
	}
}

//
// isPlaying
//
// returns YES if the audio currently playing.
//
- (BOOL)isPlaying
{
	if (state == AS_PLAYING)
	{
		return YES;
	}
	
	return NO;
}

//
// isPaused
//
// returns YES if the audio currently playing.
//
- (BOOL)isPaused
{
	if (state == AS_PAUSED)
	{
		return YES;
	}
	
	return NO;
}

//
// isWaiting
//
// returns YES if the AudioStreamer is waiting for a state transition of some
// kind.
//
- (BOOL)isWaiting
{
	@synchronized(self)
	{
		if ([self isFinishing] ||
			state == AS_STARTING_FILE_THREAD||
			state == AS_WAITING_FOR_DATA ||
			state == AS_WAITING_FOR_QUEUE_TO_START ||
			state == AS_BUFFERING)
		{
			return YES;
		}
	}
	
	return NO;
}

//
// isIdle
//
// returns YES if the AudioStream is in the AS_INITIALIZED state (i.e.
// isn't doing anything).
//
- (BOOL)isIdle
{
	if (state == AS_INITIALIZED)
	{
		return YES;
	}
	
	return NO;
}


-(BOOL)openBTWIFIFileStream
{
	@synchronized(self)
	{
		NSAssert(stream == nil && audioFileStream == nil,
                 @"audioFileStream already initialized");    
        
        // create an audio file stream parser
		err = AudioFileStreamOpen(self, ASPropertyListenerProc, ASPacketsProc, 
                                  0, &audioFileStream);
		if (err)
		{
			[self failWithErrorCode:AS_FILE_STREAM_OPEN_FAILED];
			return NO;
		}
 
    
    }
    
    
}


-(BOOL)openLocalFileStream
{
    @synchronized(self)
	{
        NSAssert(stream == nil && audioFileStream == nil,
                 @"audioFileStream already initialized");
        
        
        /*      // create an audio file stream parser
         err = AudioFileStreamOpen(self, ASPropertyListenerProc, ASPacketsProc, 
         kAudioFileMPEG4Type, &audioFileStream);
         if (err)
         {
         [self failWithErrorCode:AS_FILE_STREAM_OPEN_FAILED];
         return NO;
         }    
         */
        //
        // Create the GET request
        //
        // //NSLog(@"opening local file with URL %@",self->cfURL);
        stream = CFReadStreamCreateWithFile(NULL, self->cfURL);        
        
        //
        // Open the stream
        //
        if (!CFReadStreamOpen(stream))
        {
            CFRelease(stream);
            
            UIAlertView *alert =
            [[UIAlertView alloc]
             initWithTitle:NSLocalizedStringFromTable(@"File Error", @"Errors", nil)
             message:NSLocalizedStringFromTable(@"Unable to configure network read stream.", @"Errors", nil)
             delegate:self
             cancelButtonTitle:@"OK"
             otherButtonTitles: nil];
            [alert
             performSelector:@selector(show)
             onThread:[NSThread mainThread]
             withObject:nil
             waitUntilDone:YES];
            [alert release];
            
            return NO;
        }
        
        //
        // Set our callback function to receive the data
        //
        CFStreamClientContext context = {0, self, NULL, NULL, NULL};
        Boolean streamSupportsAsyncNot = CFReadStreamSetClient(
                                                               stream,
                                                               kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered | kCFStreamEventCanAcceptBytes | kCFStreamEventOpenCompleted | kCFStreamEventNone,
                                                               ASReadStreamCallBack,
                                                               &context);
        assert(streamSupportsAsyncNot == true);
        
        CFReadStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        
    }
    
    return YES;
}



/*
 * we read the audio data from the ring buffer as well as
 * the packet descriptions (VBR data).
 */

-(BOOL)readFromRingBuffer
{

    
    
    NSLog(@"READER: readFromRingBuffer, setting streamer state to AS_BUFFERING");
    state = AS_BUFFERING;
    
    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    ringBufferReaderTimer = [[NSTimer alloc] initWithFireDate:fireDate
                                                     interval:0.25
                                                       target:self
                                                     selector:@selector(readRingBufferDataBit)
                                                     userInfo:NULL
                                                      repeats:YES];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    NSLog(@"this is the runloops current mode %@",[runLoop currentMode]);
    [runLoop addTimer:ringBufferReaderTimer forMode:NSDefaultRunLoopMode];
    [ringBufferReaderTimer fire];
    NSLog(@"end of readFromRingBuffer");
    return YES;
}

-(void)readRingBufferDataBit
{
    if (state == AS_STOPPED) {
        [ringBufferReaderTimer invalidate];
        return;
    }
    
    void *readPointer;
    allBytesAvailable = [ringBuffer lengthAvailableToReadReturningPointer:&readPointer];
    
    if (allBytesAvailable == 0) {
        NSLog(@"READER: OOOOOPTS.. NOTHING TO READ YET.. EXIT THE READ FROM RING BUFFER");
        return;
    }    
    
    // we store all the bytes grabbed unto ringBufferReadData first, so that we can
    // purge the ring buffer the best we can
    NSData * ringBufferReadData = [NSData dataWithBytes:readPointer length:allBytesAvailable];
    // NSLog(@"READER: THESE ARE THE BYTES WE ARE ABOUT TO READ FROM RING BUFFER %lu ",allBytesAvailable);
    
    [ringBuffer didReadLength:allBytesAvailable];

    
    UInt32 ringBufferReadDataOffset = 0;
    while (ringBufferReadDataOffset < allBytesAvailable) {        
        
        NSData * packetData = [ringBufferReadData subdataWithRange:NSMakeRange(8 + ringBufferReadDataOffset, 2)];
        PacketType packetType = [packetData rw_int16AtOffset:0];
        packetData = [ringBufferReadData subdataWithRange:NSMakeRange(4 + ringBufferReadDataOffset, 4)];
        UInt32 packNumber = [packetData rw_int32AtOffset:0];
        int packetBytesFilled = [[ringBufferReadData subdataWithRange:NSMakeRange(12 + ringBufferReadDataOffset, 4)] rw_int32AtOffset:0];
        int packetDescriptionsBytesFilled = [[ringBufferReadData subdataWithRange:NSMakeRange(16 + ringBufferReadDataOffset, 4)] rw_int32AtOffset:0];
                
        
        int offset = AUDIO_BUFFER_PACKET_HEADER_SIZE + ringBufferReadDataOffset;
        NSData* audioBufferData = [NSData dataWithBytes:(char *)([ringBufferReadData bytes] + offset) length:packetBytesFilled];
        
        
        offset += packetBytesFilled ;
        NSData *packetDescriptionsData = [NSData dataWithBytes:(char *)([ringBufferReadData bytes] + offset) length:packetDescriptionsBytesFilled];
        
        UInt32 inNumberPackets = packetDescriptionsBytesFilled/AUDIO_STREAM_PACK_DESC_SIZE;
        AudioStreamPacketDescription *inPacketDescriptions;
        
        
        inPacketDescriptions = [self populatePacketDescriptionArray:packetDescriptionsData
                                            packetDescriptionNumber:inNumberPackets];
        
        
        if (inPacketDescriptions[0].mDataByteSize > 65536)
        {
            NSLog(@"packet description size is abnormally large.. soething is wrong");
        }
        
        
        [self handleAudioPackets:[audioBufferData bytes]
                     numberBytes:packetBytesFilled
                   numberPackets:inNumberPackets
              packetDescriptions:inPacketDescriptions];
                        
        ringBufferReadDataOffset += AUDIO_BUFFER_PACKET_HEADER_SIZE + packetBytesFilled + packetDescriptionsBytesFilled;
    }
 
}



-(AudioStreamPacketDescription *)populatePacketDescriptionArray:(NSData *)packetDescData
              packetDescriptionNumber:(UInt32)packetDescNumber
{

    AudioStreamPacketDescription *localPacketDescriptions = (AudioStreamPacketDescription *)
    malloc(sizeof(AudioStreamPacketDescription) * packetDescNumber);
    
    UInt32 offset = 0;
 
    for (int i=0; i < packetDescNumber; i++) {    
        
        localPacketDescriptions[i].mStartOffset = [packetDescData rw_int32AtOffset:offset];
        offset += sizeof(UInt32);        

        localPacketDescriptions[i].mVariableFramesInPacket = [packetDescData rw_int32AtOffset:offset];
        offset += sizeof(UInt32);

        localPacketDescriptions[i].mDataByteSize = [packetDescData rw_int32AtOffset:offset];                
        offset += sizeof(UInt32);

    }    

    return localPacketDescriptions;

}


//
// openFileStream
//
// Open the audioFileStream to parse data and the fileHandle as the data
// source.
//
- (BOOL)openFileStream
{
	@synchronized(self)
	{
		NSAssert(stream == nil && audioFileStream == nil,
			@"audioFileStream already initialized");
		
		//
		// Attempt to guess the file type from the URL. Reading the MIME type
		// from the CFReadStream would be a better approach since lots of
		// URL's don't have the right extension.
		//
		// If you have a fixed file-type, you may want to hardcode this.
		//
		AudioFileTypeID fileTypeHint = kAudioFileMP3Type;
		NSString *fileExtension = [[url path] pathExtension];
		if ([fileExtension isEqual:@"mp3"])
		{
			fileTypeHint = kAudioFileMP3Type;
		}
		else if ([fileExtension isEqual:@"wav"])
		{
			fileTypeHint = kAudioFileWAVEType;
		}
		else if ([fileExtension isEqual:@"aifc"])
		{
			fileTypeHint = kAudioFileAIFCType;
		}
		else if ([fileExtension isEqual:@"aiff"])
		{
			fileTypeHint = kAudioFileAIFFType;
		}
		else if ([fileExtension isEqual:@"m4a"])
		{
			fileTypeHint = kAudioFileM4AType;
		}
		else if ([fileExtension isEqual:@"mp4"])
		{
			fileTypeHint = kAudioFileMPEG4Type;
		}
		else if ([fileExtension isEqual:@"caf"])
		{
			fileTypeHint = kAudioFileCAFType;
		}
		else if ([fileExtension isEqual:@"aac"])
		{
			fileTypeHint = kAudioFileAAC_ADTSType;
		}

		// create an audio file stream parser
		err = AudioFileStreamOpen(self, ASPropertyListenerProc, ASPacketsProc, 
								fileTypeHint, &audioFileStream);
		if (err)
		{
			[self failWithErrorCode:AS_FILE_STREAM_OPEN_FAILED];
			return NO;
		}
		
		//
		// Create the GET request
		//
		CFHTTPMessageRef message= CFHTTPMessageCreateRequest(NULL, (CFStringRef)@"GET", (CFURLRef)url, kCFHTTPVersion1_1);
		stream = CFReadStreamCreateForHTTPRequest(NULL, message);
		CFRelease(message);
		
		//
		// Enable stream redirection
		//
		if (CFReadStreamSetProperty(
			stream,
			kCFStreamPropertyHTTPShouldAutoredirect,
			kCFBooleanTrue) == false)
		{
#ifdef TARGET_OS_IPHONE
			UIAlertView *alert =
				[[UIAlertView alloc]
					initWithTitle:NSLocalizedStringFromTable(@"File Error", @"Errors", nil)
					message:NSLocalizedStringFromTable(@"Unable to configure network read stream.", @"Errors", nil)
					delegate:self
					cancelButtonTitle:@"OK"
					otherButtonTitles: nil];
			[alert
				performSelector:@selector(show)
				onThread:[NSThread mainThread]
				withObject:nil
				waitUntilDone:YES];
			[alert release];
#else
		NSAlert *alert =
			[NSAlert
				alertWithMessageText:NSLocalizedStringFromTable(@"File Error", @"Errors", nil)
				defaultButton:NSLocalizedString(@"OK", @"")
				alternateButton:nil
				otherButton:nil
				informativeTextWithFormat:NSLocalizedStringFromTable(@"Unable to configure network read stream.", @"Errors", nil)];
		[alert
			performSelector:@selector(runModal)
			onThread:[NSThread mainThread]
			withObject:nil
			waitUntilDone:NO];
#endif
			return NO;
		}
		
		//
		// Handle SSL connections
		//
		if( [[url absoluteString] rangeOfString:@"https"].location != NSNotFound )
		{
			NSDictionary *sslSettings =
				[NSDictionary dictionaryWithObjectsAndKeys:
					(NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL, kCFStreamSSLLevel,
					[NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredCertificates,
					[NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredRoots,
					[NSNumber numberWithBool:YES], kCFStreamSSLAllowsAnyRoot,
					[NSNumber numberWithBool:NO], kCFStreamSSLValidatesCertificateChain,
					[NSNull null], kCFStreamSSLPeerName,
				nil];

			CFReadStreamSetProperty(stream, kCFStreamPropertySSLSettings, sslSettings);
		}
		
		//
		// Open the stream
		//
		if (!CFReadStreamOpen(stream))
		{
			CFRelease(stream);
#ifdef TARGET_OS_IPHONE
			UIAlertView *alert =
				[[UIAlertView alloc]
					initWithTitle:NSLocalizedStringFromTable(@"File Error", @"Errors", nil)
					message:NSLocalizedStringFromTable(@"Unable to configure network read stream.", @"Errors", nil)
					delegate:self
					cancelButtonTitle:@"OK"
					otherButtonTitles: nil];
			[alert
				performSelector:@selector(show)
				onThread:[NSThread mainThread]
				withObject:nil
				waitUntilDone:YES];
			[alert release];
#else
		NSAlert *alert =
			[NSAlert
				alertWithMessageText:NSLocalizedStringFromTable(@"File Error", @"Errors", nil)
				defaultButton:NSLocalizedString(@"OK", @"")
				alternateButton:nil
				otherButton:nil
				informativeTextWithFormat:NSLocalizedStringFromTable(@"Unable to configure network read stream.", @"Errors", nil)];
		[alert
			performSelector:@selector(runModal)
			onThread:[NSThread mainThread]
			withObject:nil
			waitUntilDone:NO];
#endif
			return NO;
		}
		
		//
		// Set our callback function to receive the data
		//
		CFStreamClientContext context = {0, self, NULL, NULL, NULL};
		CFReadStreamSetClient(
			stream,
			kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered,
			ASReadStreamCallBack,
			&context);
		CFReadStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	}
	
	return YES;
}



//
// startInternal
//
// This is the start method for the AudioStream thread. This thread is created
// because it will be blocked when there are no audio buffers idle (and ready
// to receive audio data).
//
// Activity in this thread:
//	- Creation and cleanup of all AudioFileStream and AudioQueue objects
//	- Receives data from the CFReadStream
//	- AudioFileStream processing
//	- Copying of data from AudioFileStream into audio buffers
//  - Stopping of the thread because of end-of-file
//	- Stopping due to error or failure
//
// Activity *not* in this thread:
//	- AudioQueue playback and notifications (happens in AudioQueue thread)
//  - Actual download of NSURLConnection data (NSURLConnection's thread)
//	- Creation of the AudioStreamer (other, likely "main" thread)
//	- Invocation of -start method (other, likely "main" thread)
//	- User/manual invocation of -stop (other, likely "main" thread)
//
// This method contains bits of the "main" function from Apple's example in
// AudioFileStreamExample.
//
- (void)startInternal
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	@synchronized(self)
	{
		if (state != AS_STARTING_FILE_THREAD)
		{
			if (state != AS_STOPPING &&
				state != AS_STOPPED)
			{
				// //NSLog(@"### Not starting audio thread. State code is: %ld", state);
			}
			self.state = AS_INITIALIZED;
			[pool release];
			return;
		}
		
	#ifdef TARGET_OS_IPHONE			
		//
		// Set the audio session category so that we continue to play if the
		// iPhone/iPod auto-locks.
		//
		AudioSessionInitialize (
			NULL,                          // 'NULL' to use the default (main) run loop
			NULL,                          // 'NULL' to use the default run loop mode
			MyAudioSessionInterruptionListener,  // a reference to your interruption callback
			self                       // data to pass to your interruption listener callback
		);
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
		AudioSessionSetProperty (
			kAudioSessionProperty_AudioCategory,
			sizeof (sessionCategory),
			&sessionCategory
		);			
		
	/*	AudioSessionInitialize( NULL,
							   NULL,
							   interruptionListenerCallback,
							   self );
	
		
		 UInt32 sessionCategory1 = kAudioSessionCategory_UserInterfaceSoundEffects;
		 AudioSessionSetProperty( kAudioSessionProperty_AudioCategory,
		 sizeof(sessionCategory1),
		 &sessionCategory1 );*/
		AudioSessionSetActive(true);

	#endif
	
		self.state = AS_WAITING_FOR_DATA;
		
		// initialize a mutex and condition so that we can block on buffers in use.
		pthread_mutex_init(&queueBuffersMutex, NULL);
		pthread_cond_init(&queueBufferReadyCondition, NULL);
		
         //NSLog(@"READER: about to call read from ring buffer");
		if (![self readFromRingBuffer])
		{
			goto cleanup;
		}
	}

	//
	// Process the run loop until playback is finished or failed.
	//
	BOOL isRunning = YES;
	do
	{
         //NSLog(@"READER: before run loop");
		isRunning = [[NSRunLoop currentRunLoop]
			runMode:NSDefaultRunLoopMode
			beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
		
         //NSLog(@"READER: after run loop");
        
		//
		// If there are no queued buffers, we need to check here since the
		// handleBufferCompleteForQueue:buffer: should not change the state
		// (may not enter the synchronized section).
		//
		if (buffersUsed == 0 && self.state == AS_PLAYING)
		{
			err = AudioQueuePause(audioQueue);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_PAUSE_FAILED];
				return;
			}
			self.state = AS_BUFFERING;
		}
	} while (isRunning && ![self runLoopShouldExit]);
	
cleanup:

	@synchronized(self)
	{
        NSLog(@"CLIENT: emptying ring buffer");
        
		//
		// Empty Audio Queue.. may be used later
		//
        if (_game->ringBuffer) {
            [_game->ringBuffer empty];
        }
        
        //
		// Dispose of the Audio Queue
		//
		if (audioQueue)
		{
			err = AudioQueueDispose(audioQueue, true);
			audioQueue = nil;
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_DISPOSE_FAILED];
			}
		}
        

        // reset reading state so that we can reinitailize reader
        // in the future if necessary
        _game->hasStartedReading = false;
        _game->_state = GameStateWaitingForSignIn;
        state = AS_STOPPED;

        NSLog(@"CLIENT will call quitgamewithreason");
        [_game quitGameWithReason:QuitReasonServerQuit];

		pthread_mutex_destroy(&queueBuffersMutex);
		pthread_cond_destroy(&queueBufferReadyCondition);

#ifdef TARGET_OS_IPHONE			
		AudioSessionSetActive(false);
#endif

		bytesFilled = 0;
		packetsFilled = 0;
		seekTime = 0;
		seekNeeded = NO;
		self.state = AS_INITIALIZED;
	}

	[pool release];
}






//
// start
//
// Calls startInternal in a new thread.
//
- (void)start
{
	
	 NSLog(@"streamer starting ---> setting state to AS_STARTING_FILE_THREAD");
	
	
	@synchronized (self)
	{
		if (state == AS_PAUSED)
		{
			// //NSLog(@"starting1");

			[self pause];
		}
		else if (state == AS_INITIALIZED)
		{
			// //NSLog(@"starting2");

		/*	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
				@"Playback can only be started from the main thread.");*/
			notificationCenter =
				[[NSNotificationCenter defaultCenter] retain];
			self.state = AS_STARTING_FILE_THREAD;
			[NSThread
				detachNewThreadSelector:@selector(startInternal)
				toTarget:self
				withObject:nil];
		}
	}
}

//
// progress
//
// returns the current playback progress. Will return zero if sampleRate has
// not yet been detected.
//
- (double)progress
{
	@synchronized(self)
	{
		if (sampleRate > 0 && ![self isFinishing])
		{
			if (state != AS_PLAYING && state != AS_PAUSED && state != AS_BUFFERING)
			{
				return lastProgress;
			}

			AudioTimeStamp queueTime;
			Boolean discontinuity;
			err = AudioQueueGetCurrentTime(audioQueue, NULL, &queueTime, &discontinuity);
			if (err)
			{
				[self failWithErrorCode:AS_GET_AUDIO_TIME_FAILED];
			}

			double progress = seekTime + queueTime.mSampleTime / sampleRate;
			if (progress < 0.0)
			{
				progress = 0.0;
			}
			
			lastProgress = progress;
			return progress;
		}
	}
	
	return lastProgress;
}

//
// pause
//
// A togglable pause function.
//
- (void)pause
{
	@synchronized(self)
	{
		if (state == AS_PLAYING)
		
		{
			
			err = AudioQueuePause(audioQueue);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_PAUSE_FAILED];
				return;
			}
			self.state = AS_PAUSED;
		}
		else if (state == AS_PAUSED)
		{
			// //NSLog(@"play again");
			err = AudioQueueStart(audioQueue, NULL);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
				return;
			}
			self.state = AS_PLAYING;
		}
	}
}

//
// shouldSeek
//
// Applies the logic to verify if seeking should occur.
//
// returns YES (seeking should occur) or NO (otherwise).
//
- (BOOL)shouldSeek
{
	@synchronized(self)
	{
		if (bitRate != 0 && bitRate != ~0 && seekNeeded &&
			(state == AS_PLAYING || state == AS_PAUSED || state == AS_BUFFERING))
		{
			return YES;
		}
	}
	return NO;
}

//
// stop
//
// This method can be called to stop downloading/playback before it completes.
// It is automatically called when an error occurs.
//
// If playback has not started before this method is called, it will toggle the
// "isPlaying" property so that it is guaranteed to transition to true and
// back to false 
//
- (void)stop
{
	@synchronized(self)
	{
		if (audioQueue &&
			(state == AS_PLAYING || state == AS_PAUSED ||
				state == AS_BUFFERING || state == AS_WAITING_FOR_QUEUE_TO_START))
		{
			self.state = AS_STOPPING;
			stopReason = AS_STOPPING_USER_ACTION;
			err = AudioQueueStop(audioQueue, true);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_STOP_FAILED];
				return;
			}
		}
		else if (state != AS_INITIALIZED)
		{
			self.state = AS_STOPPED;
			stopReason = AS_STOPPING_USER_ACTION;
		}
	}
	
	while (state != AS_INITIALIZED)
	{
		[NSThread sleepForTimeInterval:0.1];
	}
}

//
// handleReadFromStream:eventType:data:
//
// Reads data from the network file stream into the AudioFileStream
//
// Parameters:
//    aStream - the network file stream
//    eventType - the event which triggered this method
//
- (void)handleReadFromStream:(CFReadStreamRef)aStream
	eventType:(CFStreamEventType)eventType
{
         //NSLog(@"WE ARE IN HANDLE READ FROM STREAM");
    
	if (eventType == kCFStreamEventErrorOccurred)
	{
         //NSLog(@"handleReadFromStream:  an error happend!");
		[self failWithErrorCode:AS_AUDIO_DATA_NOT_FOUND];
	}
	else if (eventType == kCFStreamEventEndEncountered)
	{
         //NSLog(@"handleReadFromStream:  The end of the stream has been reached.");
		@synchronized(self)
		{
			if ([self isFinishing])
			{
				return;
			}
		}
		
		//
		// If there is a partially filled buffer, pass it to the AudioQueue for
		// processing
		//
		if (bytesFilled)
		{
			[self enqueueBuffer];
		}

		@synchronized(self)
		{
			if (state == AS_WAITING_FOR_DATA)
			{
                 //NSLog(@"handleReadFromStream: we are still waiting for data.. shudda crashed here");
                return;
				//[self failWithErrorCode:AS_AUDIO_DATA_NOT_FOUND];
			}
			
			//
			// We left the synchronized section to enqueue the buffer so we
			// must check that we are !finished again before touching the
			// audioQueue
			//
			else if (![self isFinishing])
			{
				if (audioQueue)
				{
					//
					// Set the progress at the end of the stream
					//
					err = AudioQueueFlush(audioQueue);
					if (err)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_FLUSH_FAILED];
						return;
					}

					self.state = AS_STOPPING;
					stopReason = AS_STOPPING_EOF;
					err = AudioQueueStop(audioQueue, false);
					if (err)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_FLUSH_FAILED];
						return;
					}
				}
				else
				{
					self.state = AS_STOPPED;
					stopReason = AS_STOPPING_EOF;
				}
			}
		}
	}
	else if (eventType == kCFStreamEventHasBytesAvailable)
	{
          //NSLog(@"streamHandler: bytes available!");
        
        
        if (!audioFileStream)
		{
			//
			// Attempt to guess the file type from the URL. Reading the MIME type
			// from the httpHeaders might be a better approach since lots of
			// URL's don't have the right extension.
			//
			// If you have a fixed file-type, you may want to hardcode this.
			//

			AudioFileTypeID fileTypeHint = kAudioFileMPEG4Type;
            //[AudioStreamer hintForFileExtension:self.fileExtension];
            
			// create an audio file stream parser
             //NSLog(@"we are creating audioFileStream using AudioFileStreamOpen (with kAudioFileMPEG4Type mp4 file) and assigning ASPropertyListenerProc and ASPacketsProc");
			err = AudioFileStreamOpen(self, ASPropertyListenerProc, ASPacketsProc, 
                                      fileTypeHint, &audioFileStream);
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_OPEN_FAILED];
				return;
			}
		}
        
        
		UInt8 bytes[kAQDefaultBufSize];
		CFIndex length;
		@synchronized(self)
		{
			if ([self isFinishing])
			{
				return;
			}
			
			//
			// Read the bytes from the stream
			//
            totalBytesHandeled += kAQDefaultBufSize;
             //NSLog(@"we are handling %d bytes with total %lu", kAQDefaultBufSize, totalBytesHandeled);
			length = CFReadStreamRead(stream, bytes, kAQDefaultBufSize);
			
			if (length == -1)
			{
                 //NSLog(@"we have bytes available but length is -1");
				[self failWithErrorCode:AS_AUDIO_DATA_NOT_FOUND];
				return;
			}
			
			if (length == 0)
			{
				return;
			}
		}

		if (discontinuous)
		{
			err = AudioFileStreamParseBytes(audioFileStream, length, bytes, kAudioFileStreamParseFlag_Discontinuity);
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
				return;
			}
       //      //NSLog(@"we are parsing bytes of the size of %ld",length);
		}
		else
		{
			err = AudioFileStreamParseBytes(audioFileStream, length, bytes, 0);
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
				return;
			}
         //     //NSLog(@"we are parsing bytes of the size of %ld",length);
		}
	} else if (eventType == kCFStreamEventCanAcceptBytes) {
         //NSLog(@"handleReadFromStream: The stream can accept bytes for writing.");
    } else if (eventType == kCFStreamEventOpenCompleted) {
         //NSLog(@"handleReadFromStream: The open has completed successfully.");
    } else if (eventType == kCFStreamEventNone) {
         //NSLog(@"handleReadFromStream: nothing happened!!");        
    } else {
         //NSLog(@"handleReadFromStream: undefined behaviour");
    }
}

//
// handleReadFromStream:eventType:data:
//
// Reads data from the network file stream into the AudioFileStream
//
// Parameters:
//    aStream - the network file stream
//    eventType - the event which triggered this method
//
- (void)handleReadGKSessionData:(NSData *)data
{
    
    // //NSLog(@"we're here :)");
    
    if (discontinuous)
    {
        err = AudioFileStreamParseBytes(audioFileStream, [data length], [data bytes], kAudioFileStreamParseFlag_Discontinuity);
        if (err)
        {
            [self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
            return;
        }
    }
    else
    {
        err = AudioFileStreamParseBytes(audioFileStream, [data length], [data bytes], 0);
        if (err)
        {
            [self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
            return;
        }
    }

}


//
// enqueueBuffer
//
// Called from MyPacketsProc and connectionDidFinishLoading to pass filled audio
// bufffers (filled by MyPacketsProc) to the AudioQueue for playback. This
// function does not return until a buffer is idle for further filling or
// the AudioQueue is stopped.
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// CBR functionality added.
//
- (void)enqueueBuffer
{
   //  NSLog(@"inside enqueue buffer");
	@synchronized(self)
	{
		if ([self isFinishing])
		{
            // //NSLog(@"return bc isfinishing");
			return;
		}
		
		inuse[fillBufferIndex] = true;		// set in use flag
		buffersUsed++;

		// enqueue buffer
		AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
		fillBuf->mAudioDataByteSize = bytesFilled;
        

        
		
		if (packetsFilled)
		{
          /*  NSLog(@"\n\n\n\n\n\n");
            NSLog(@":::::: we are enqueuing buffer with %zu packtes!",packetsFilled);
            NSLog(@"buffer data is %@",[NSData dataWithBytes:fillBuf->mAudioData length:fillBuf->mAudioDataByteSize]);
            
            for (int i = 0; i < packetsFilled; i++)
            {
                NSLog(@"\THIS IS THE PACKET WE ARE COPYING TO AUDIO BUFFER----------------\n");
                NSLog(@"this is packetDescriptionArray.mStartOffset: %lld", packetDescs[i].mStartOffset);
                NSLog(@"this is packetDescriptionArray.mVariableFramesInPacket: %lu", packetDescs[i].mVariableFramesInPacket);
                NSLog(@"this is packetDescriptionArray[.mDataByteSize: %lu", packetDescs[i].mDataByteSize);        
                NSLog(@"\n----------------\n");                                               
            }
            
            */
        //    NSLog(@"we are enqueueing buffer %lu",fillBufferIndex);
            
			err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, packetsFilled, packetDescs);
		}
		else
		{
             NSLog(@":::::: we are enqueuing buffer WITHOUT PACKETS");
            
             //NSLog(@"enqueue buffer thread name %@", [NSThread currentThread].name);
			err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, 0, NULL);
		}
		
		if (err)
		{
			[self failWithErrorCode:AS_AUDIO_QUEUE_ENQUEUE_FAILED];
			return;
		}

		
		if (state == AS_BUFFERING ||
			state == AS_WAITING_FOR_DATA ||
			(state == AS_STOPPED && stopReason == AS_STOPPING_TEMPORARILY))
		{
			//
			// Fill all the buffers before starting. This ensures that the
                // avoid an audio glitch playing streaming files on iPhone SDKs < 3.0
			//
             //NSLog(@"this is the amount of buffers used %d", buffersUsed);
			if (buffersUsed == kNumAQBufs - 1)
			{

                UInt32 outNumberOfFramesPrepared = 0;
                err = AudioQueuePrime(audioQueue, 0, &outNumberOfFramesPrepared);
                
        //        NSLog(@"READER: priming the queue");
                if (err)
                {
                    
                    printf("failed to prime audio queue %ld\n", err);
                    [self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
                    return;                        
                }
                
                
                // SEND PACKET to server that this client is primed
               // Packet *packet = [Packet packetWithType:PacketTypeClientPrimed];
                

                Packet *packet = [PacketClientPrimed packetWithProfiler:_localPlayerObj.packetProfiler];
                [_game sendPacketToServer:packet];

                
                
             //   NSLog(@"READER: CLIENT->SERVER: we are primed packet");

                // wait until we get the signal from the host to play
                pthread_mutex_lock(&queueBuffersMutex); 
                while (state != AS_READY_TO_PLAY)
                {
             //       NSLog(@"READER: WE ARE WAITIN FOR state to be as_ready_to_play ");
                //    [_game sendPacketToServer:packet];
                    pthread_cond_wait(&queueBufferReadyCondition, &queueBuffersMutex);
                }
                pthread_mutex_unlock(&queueBuffersMutex);
                
                
                
           //     NSLog(@"READER: we are starting queue");
                err = AudioQueueStart(audioQueue, NULL);
                if (err)
                {
                    [self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
                    return;
                }
                self.state = AS_PLAYING;

			}
		} 
        
    	// go to next buffer
         //NSLog(@"here we are appending fill buff index, its value was %lu", fillBufferIndex);
		if (++fillBufferIndex >= kNumAQBufs) fillBufferIndex = 0;
		bytesFilled = 0;		// reset bytes filled
		packetsFilled = 0;		// reset packets filled
         //NSLog(@"now we are going to next buffer with fill buff index being: %lu",fillBufferIndex);

	}

	// wait until next buffer is not in use
	pthread_mutex_lock(&queueBuffersMutex); 
	while (inuse[fillBufferIndex])
	{
         //NSLog(@"WE ARE BEING BLOOOOCKED on bufindex %lu", fillBufferIndex);
		pthread_cond_wait(&queueBufferReadyCondition, &queueBuffersMutex);
	}
	pthread_mutex_unlock(&queueBuffersMutex);
    
     //NSLog(@"end of enqueue buffer ");
}


-(AudioStreamBasicDescription)getAACaSBD
{
    // get the audio data format from the file
    // we know that it is PCM.. since it's converted    
    AudioStreamBasicDescription dataFormat;
    dataFormat.mSampleRate = 44100.0;
    dataFormat.mFormatID = 1633772320;
    dataFormat.mFormatFlags = 0;
    dataFormat.mBytesPerPacket = 0;
    dataFormat.mFramesPerPacket = 1024;
    dataFormat.mBytesPerFrame = 0;
    dataFormat.mChannelsPerFrame = 2;
    dataFormat.mBitsPerChannel = 0;  
    dataFormat.mReserved = 0;
    
    return dataFormat;
    
}



//
// handlePropertyChangeForFileStream:fileStreamPropertyID:ioFlags:
//
// Object method which handles implementation of MyPropertyListenerProc
//
// Parameters:
//    inAudioFileStream - should be the same as self->audioFileStream
//    inPropertyID - the property that changed
//    ioFlags - the ioFlags passed in
//
- (void)handlePropertyChangeForFileStream:(AudioFileStreamID)inAudioFileStream
	fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID
	ioFlags:(UInt32 *)ioFlags
{
     //NSLog(@"PropChg: handlePropertyChangeForFileStream");
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets)
		{
             //NSLog(@"PropChg: ready to produce packets");
			discontinuous = true;
			/*
			AudioStreamBasicDescription asbd;
			UInt32 asbdSize = sizeof(asbd);
			
			// get the stream format.
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
				return;
			}
            asbd = [self getAACaSBD];
            
			sampleRate = asbd.mSampleRate;
           
            //asbd.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
            // unless this is brute forced, we receive kAudioFormatMPEGLayer1 here.. why? TODO: fix this
            //asbd.mFormatID = kAudioFormatMPEGLayer3;
			
			// create the audio queue
             //NSLog(@"PropChg: ::::::::::  CREATING AUDIO QUEUE");
			err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, self, NULL, NULL, 0, &audioQueue);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_CREATION_FAILED];
				return;
			}
			
			// start the queue if it has not been started already
			// listen to the "isRunning" property
			err = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, MyAudioQueueIsRunningCallback, self);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_ADD_LISTENER_FAILED];
				return;
			}
			
			// allocate audio queue buffers
			for (unsigned int i = 0; i < kNumAQBufs; ++i)
			{
				err = AudioQueueAllocateBuffer(audioQueue, kAQBufSize, &audioQueueBuffer[i]);
				if (err)
				{
					[self failWithErrorCode:AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED];
					return;
				}
			}

			// get the cookie size
			UInt32 cookieSize;
			Boolean writable;
			OSStatus ignorableError;
			ignorableError = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
			if (ignorableError)
			{
				return;
			}

			// get the cookie data
			void* cookieData = calloc(1, cookieSize);
			ignorableError = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
			if (ignorableError)
			{
				return;
			}

			// set the cookie on the queue.
			ignorableError = AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
			free(cookieData);
			if (ignorableError)
			{
				return;
			}
             */
		}
		else if (inPropertyID == kAudioFileStreamProperty_DataOffset)
		{
             //NSLog(@"PropChg: data offset!!"); 
			SInt64 offset;
			UInt32 offsetSize = sizeof(offset);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataOffset, &offsetSize, &offset);
			dataOffset = offset;
            
            if (audioDataByteCount)
			{
				fileLength = dataOffset + audioDataByteCount;
			}
            
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
				return;
			}
		}
        else if (inPropertyID == kAudioFileStreamProperty_FileFormat)
        {
             //NSLog(@"PropChg: file format!!"); 
			UInt32 dataFormat;
			UInt32 dataFormatSize = sizeof(dataFormat);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_FileFormat, &dataFormatSize, &dataFormat);
			//dataOffset = offset;
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
				return;
			}
            
        }
        else if (inPropertyID == kAudioFileStreamProperty_DataFormat)
		{
             //NSLog(@"handlePropertyChangeForFileStream -> kAudioFileStreamProperty_DataFormat");
			if (asbd.mSampleRate == 0)
			{
				UInt32 asbdSize = sizeof(asbd);
				
				// get the stream format.
                 //NSLog(@"in handlePropertyChangeForFileStream.. we are grabbing the absd property and storing it in absd");
				err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
				if (err)
				{
					[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
					return;
				}
			}
		}
	} 
}

//
// handleAudioPackets:numberBytes:numberPackets:packetDescriptions:
//
// Object method which handles the implementation of MyPacketsProc
//
// Parameters:
//    inInputData - the packet data
//    inNumberBytes - byte size of the data
//    inNumberPackets - number of packets in the data
//    inPacketDescriptions - packet descriptions
//
- (void)handleAudioPackets:(const void *)inInputData
	numberBytes:(UInt32)inNumberBytes
	numberPackets:(UInt32)inNumberPackets
	packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions;
{
     //NSLog(@"we are in handle audio packets");

    totalBytesRead += inNumberBytes;
   //  //NSLog(@"handling audio packets with %lu bytes and %lu packets TOTAL BYTES: %lu",inNumberBytes, inNumberPackets, totalBytesRead);
    
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		if (bitRate == 0)
		{
			UInt32 dataRateDataSize = sizeof(UInt32);
			err = AudioFileStreamGetProperty(
				audioFileStream,
				kAudioFileStreamProperty_BitRate,
				&dataRateDataSize,
				&bitRate);
			if (err)
			{
				//
				// m4a and a few other formats refuse to parse the bitrate so
				// we need to set an "unparseable" condition here. If you know
				// the bitrate (parsed it another way) you can set it on the
				// class if needed.
				//
				bitRate = ~0;
			}
		}
		
		// we have successfully read the first packests from the audio stream, so
		// clear the "discontinuous" flag
		discontinuous = false;
        if (!audioQueue)
		{
             //NSLog(@"handle audio packets->create queue");
			[self createQueue];
		}
	}

	// the following code assumes we're streaming VBR data. for CBR data, the second branch is used.
	if (inPacketDescriptions)
	{
         //NSLog(@"there are packet descriptions!!");
		for (int i = 0; i < inNumberPackets; ++i)
		{
			SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
			SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
			size_t bufSpaceRemaining;
			
			@synchronized(self)
			{
				// If the audio was terminated before this point, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If we need to seek then unroll the stack back to the
				// appropriate point
				//
				if ([self shouldSeek])
				{
					return;
				}
				
				if (packetSize > packetBufferSize)
				{
                     //NSLog(@"oops! packet size %lld is bigger than buf size %lu",packetSize, packetBufferSize);
					[self failWithErrorCode:AS_AUDIO_BUFFER_TOO_SMALL];
				}

				bufSpaceRemaining = packetBufferSize - bytesFilled;
			}

			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			if (bufSpaceRemaining < packetSize)
			{
				[self enqueueBuffer];
			}
			
			@synchronized(self)
			{
				// If the audio was terminated while waiting for a buffer, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If we need to seek then unroll the stack back to the
				// appropriate point
				//
				if ([self shouldSeek])
				{
					return;
				}
				 
				// copy data to the audio queue buffer
				AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
				memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)inInputData + packetOffset, packetSize);

				// fill out packet description
				packetDescs[packetsFilled] = inPacketDescriptions[i];
				packetDescs[packetsFilled].mStartOffset = bytesFilled;
				// keep track of bytes filled and packets filled
				bytesFilled += packetSize;
				packetsFilled += 1;
			}
			
			// if that was the last free packet description, then enqueue the buffer.
			size_t packetsDescsRemaining = kAQMaxPacketDescs - packetsFilled;
			if (packetsDescsRemaining == 0) {
				[self enqueueBuffer];
			}
		}	
	}
	else
	{
                 //NSLog(@"there are NO  packet descriptions!!");
     	size_t offset = 0;
		while (inNumberBytes)
		{
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQDefaultBufSize - bytesFilled;
            // //NSLog(@"bufspace remaning is kaqbufsize (%d) - bytesfilled (%zu) = %zu ", kAQBufSize, bytesFilled, bufSpaceRemaining);
			if (bufSpaceRemaining < inNumberBytes)
			{
                // //NSLog(@"-> handleAudioPackets calling enqueueBuffer bc bufspaceremaining < packesize");
				[self enqueueBuffer];
			}
			
			@synchronized(self)
			{
				// If the audio was terminated while waiting for a buffer, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If we need to seek then unroll the stack back to the
				// appropriate point
				//
				if ([self shouldSeek])
				{
					return;
				}
				
				// copy data to the audio queue buffer
				AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
				bufSpaceRemaining = kAQDefaultBufSize - bytesFilled;
				size_t copySize;
				if (bufSpaceRemaining < inNumberBytes)
				{
					copySize = bufSpaceRemaining;
				}
				else
				{
					copySize = inNumberBytes;
				}
                
                
				//
				// If there was some kind of issue with enqueueBuffer and we didn't
				// make space for the new audio data then back out
				//
				if (bytesFilled > packetBufferSize)
				{
					return;
				}
                
                // //NSLog(@"we are copyingstuff to new buffer");
                
               // NSData * data = [NSData dataWithBytes:(const char*)(inInputData + offset) length:copySize];
//                // //NSLog(@"Game: receive data from data: %@, length: %d",data, [data length]);

                
                
				memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)(inInputData + offset), copySize);


				// keep track of bytes filled and packets filled
				bytesFilled += copySize;
				packetsFilled = 0;
				inNumberBytes -= copySize;
				offset += copySize;
                // //NSLog(@"bytes filled is %zu ",bytesFilled);

			}
		}
	}
}


//
// ASAudioQueueIsRunningCallback
//
// Called from the AudioQueue when playback is started or stopped. This
// information is used to toggle the observable "isPlaying" property and
// set the "finished" flag.
//
static void ASAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
	AudioStreamer* streamer = (AudioStreamer *)inUserData;
	[streamer handlePropertyChangeForQueue:inAQ propertyID:inID];
}

//
// createQueue
//
// Method to create the AudioQueue from the parameters gathered by the
// AudioFileStream.
//
// Creation is deferred to the handling of the first audio packet (although
// it could be handled any time after kAudioFileStreamProperty_ReadyToProducePackets
// is true).
//
- (void)createQueue
{
    
    
	sampleRate = asbd.mSampleRate;
	packetDuration = asbd.mFramesPerPacket / sampleRate;
	
	// create the audio queue
     //NSLog(@"we are creating audio queue!");
	err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, self, NULL, NULL, 0, &audioQueue);
	if (err)
	{
		[self failWithErrorCode:AS_AUDIO_QUEUE_CREATION_FAILED];
		return;
	}
	
	// start the queue if it has not been started already
	// listen to the "isRunning" property
	err = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, ASAudioQueueIsRunningCallback, self);
	if (err)
	{
		[self failWithErrorCode:AS_AUDIO_QUEUE_ADD_LISTENER_FAILED];
		return;
	}
	
	// get the packet size if it is available
	UInt32 sizeOfUInt32 = sizeof(UInt32);
	err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &packetBufferSize);
	if (err || packetBufferSize == 0)
	{
		err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_MaximumPacketSize, &sizeOfUInt32, &packetBufferSize);
		if (err || packetBufferSize == 0)
		{
			// No packet size available, just use the default
			packetBufferSize = kAQDefaultBufSize;
		}
	}
    
	// allocate audio queue buffers
	for (unsigned int i = 0; i < kNumAQBufs; ++i)
	{
		err = AudioQueueAllocateBuffer(audioQueue, packetBufferSize, &audioQueueBuffer[i]);
		if (err)
		{
			[self failWithErrorCode:AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED];
			return;
		}
	}
    
	// get the cookie size
	UInt32 cookieSize;
	Boolean writable;
	OSStatus ignorableError;
	ignorableError = AudioFileStreamGetPropertyInfo(audioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
	if (ignorableError)
	{
		return;
	}
    
	// get the cookie data
	void* cookieData = calloc(1, cookieSize);
	ignorableError = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
	if (ignorableError)
	{
		return;
	}
    
	// set the cookie on the queue.
	ignorableError = AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
	free(cookieData);
	if (ignorableError)
	{
		return;
	}
}



//
// handleBufferCompleteForQueue:buffer:
//
// Handles the buffer completetion notification from the audio queue
//
// Parameters:
//    inAQ - the queue
//    inBuffer - the buffer
//
- (void)handleBufferCompleteForQueue:(AudioQueueRef)inAQ
	buffer:(AudioQueueBufferRef)inBuffer
{
    // //NSLog(@"we are in handleBufferCompleteForQueue");
	unsigned int bufIndex = -1;
	for (unsigned int i = 0; i < kNumAQBufs; ++i)
	{
		if (inBuffer == audioQueueBuffer[i])
		{
			bufIndex = i;
			break;
		}
	}
	
	if (bufIndex == -1)
	{
		[self failWithErrorCode:AS_AUDIO_QUEUE_BUFFER_MISMATCH];
		pthread_mutex_lock(&queueBuffersMutex);
		pthread_cond_signal(&queueBufferReadyCondition);
		pthread_mutex_unlock(&queueBuffersMutex);
		return;
	}
	
	// signal waiting thread that the buffer is free.
    // NSLog(@"BUFFER COMPLETION NOTIFICATION: WE ARE UNBLOCKING BUFINDEX %d", bufIndex);
	pthread_mutex_lock(&queueBuffersMutex);
	inuse[bufIndex] = false;
	buffersUsed--;

//
//  Enable this logging to measure how many buffers are queued at any time.
//
#if LOG_QUEUED_BUFFERS
	// NSLog(@"Queued buffers: %d", buffersUsed);
#endif
	
	pthread_cond_signal(&queueBufferReadyCondition);
	pthread_mutex_unlock(&queueBuffersMutex);
}

//
// handlePropertyChangeForQueue:propertyID:
//
// Implementation for MyAudioQueueIsRunningCallback
//
// Parameters:
//    inAQ - the audio queue
//    inID - the property ID
//
- (void)handlePropertyChangeForQueue:(AudioQueueRef)inAQ
	propertyID:(AudioQueuePropertyID)inID
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@synchronized(self)
	{
		if (inID == kAudioQueueProperty_IsRunning)
		{
			if (state == AS_STOPPING)
			{
				self.state = AS_STOPPED;
			}
			else if (state == AS_WAITING_FOR_QUEUE_TO_START)
			{
				//
				// Note about this bug avoidance quirk:
				//
				// On cleanup of the AudioQueue thread, on rare occasions, there would
				// be a crash in CFSetContainsValue as a CFRunLoopObserver was getting
				// removed from the CFRunLoop.
				//
				// After lots of testing, it appeared that the audio thread was
				// attempting to remove CFRunLoop observers from the CFRunLoop after the
				// thread had already deallocated the run loop.
				//
				// By creating an NSRunLoop for the AudioQueue thread, it changes the
				// thread destruction order and seems to avoid this crash bug -- or
				// at least I haven't had it since (nasty hard to reproduce error!)
				//
				[NSRunLoop currentRunLoop];

				self.state = AS_PLAYING;
			}
			else
			{
				// //NSLog(@"AudioQueue changed state in unexpected way.");
			}
		}
	}
	
	[pool release];
}

#ifdef TARGET_OS_IPHONE
//
// handleInterruptionChangeForQueue:propertyID:
//
// Implementation for MyAudioQueueInterruptionListener
//
// Parameters:
//    inAQ - the audio queue
//    inID - the property ID
//
- (void)handleInterruptionChangeToState:(AudioQueuePropertyID)inInterruptionState
{
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
		[self pause];
	}
	else if (inInterruptionState == kAudioSessionEndInterruption)
	{
		[self start];
	}
}
#endif

@end



