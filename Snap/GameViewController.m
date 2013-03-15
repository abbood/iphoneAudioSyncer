//
//  GameViewController.m
//  Snap
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "GameViewController.h"
#import "UIFont+SnapAdditions.h"

@interface GameViewController ()

@property (nonatomic, weak) IBOutlet UILabel *centerLabel;

@end

@implementation GameViewController

@synthesize delegate = _delegate;
@synthesize game = _game;

@synthesize centerLabel = _centerLabel;

- (void)dealloc
{
#ifdef DEBUG
	NSLog(@"dealloc %@", self);
#endif
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
	self.centerLabel.font = [UIFont rw_snapFontWithSize:18.0f];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Actions

- (IBAction)exitAction:(id)sender
{
	[self.game quitGameWithReason:QuitReasonUserQuit];
}

#pragma mark - GameDelegate

- (void)game:(Game *)game didQuitWithReason:(QuitReason)reason
{
	[self.delegate gameViewController:self didQuitWithReason:reason];
}

- (void)gameWaitingForServerReady:(Game *)game
{
	self.centerLabel.text = NSLocalizedString(@"Waiting for game to start...", @"Status text: waiting for server");
}

- (void)gameWaitingForClientsReady:(Game *)game
{
	self.centerLabel.text = NSLocalizedString(@"Waiting for other players...", @"Status text: waiting for clients");
}

- (void)gameDidBegin:(Game *)game
{
}


- (void)serverBroadcastDidBegin:(Game *)game
{
}

- (void)clientReceptionDidBegin:(Game *)game
{
}

- (IBAction)readFromFile:(id)sender 
{
    NSLog(@"we are about to start reading");
    //streamer = [[AudioStreamer alloc] initWithCFURL:cfURL];    
    

    
    
}

- (IBAction)writeToFile:(id)sender 
{
    [self storeDatainFile]; 
}


-(void)storeDatainFile
{
    
    // init file 
    [self initFile];
    
    NSURL *assetURL = [NSURL URLWithString:@"ipod-library://item/item.m4a?id=1053020204400037178"]; 
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    
    NSError * error = nil;
    AVAssetReader* reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
    
    AVAssetTrack* track = [songAsset.tracks objectAtIndex:0]; 
    
    AVAssetReaderTrackOutput* readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track
                                                                                        outputSettings:nil];
    
    [reader addOutput:readerOutput];
    [reader startReading];
    
    
    CMSampleBufferRef sample;
    //UInt32 counter = 1000;
    
    NSLog(@"before entering loop.. this is totalPackets filled %lu",totalPacketsFilled);
    shouldExitLoop = false;
    
    while ((sample = [readerOutput copyNextSampleBuffer]) && !shouldExitLoop) 
    {                                          

        
        Boolean isBufferDataReady = CMSampleBufferDataIsReady(sample);
        
        if (!isBufferDataReady) {
            while (!isBufferDataReady) {
                NSLog(@"buffer is not ready!");
            }
        }
        
        CMBlockBufferRef CMBuffer = CMSampleBufferGetDataBuffer( sample );                                                         
        AudioBufferList audioBufferList;  
        
        CheckError(CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                                                                           sample,
                                                                           NULL,
                                                                           &audioBufferList,
                                                                           sizeof(audioBufferList),
                                                                           NULL,
                                                                           NULL,
                                                                           kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                           &CMBuffer
                                                                           ),
                   "could not read sample data");
        
        const AudioStreamPacketDescription   * inPacketDescriptions;
        size_t								 packetDescriptionsSizeOut;
        size_t inNumberPackets;
        
        CheckError(CMSampleBufferGetAudioStreamPacketDescriptionsPtr(sample, 
                                                                     &inPacketDescriptions,
                                                                     &packetDescriptionsSizeOut),
                   "could not read sample packet descriptions");
        
        inNumberPackets = packetDescriptionsSizeOut/sizeof(AudioStreamPacketDescription);
        
        AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
        
        char * packet = (char*)malloc(MAX_PACKET_SIZE);        
        
        
        for (int i = 0; i < inNumberPackets; ++i)
        {
            
            SInt64 dataOffset = inPacketDescriptions[i].mStartOffset;
			UInt32 dataSize   = inPacketDescriptions[i].mDataByteSize;            
            
            size_t packetSpaceRemaining;
            packetSpaceRemaining = MAX_PACKET_SIZE - packetBytesFilled;
            
            // if the space remaining in the buffer is not enough for the data contained in this packet
            // then just write it
            if (packetSpaceRemaining < dataSize)
            {
                // NSLog(@"oops! packetSpaceRemaining (%zu) is smaller than datasize (%lu) SO WE WILL SHIP PACKET [%d]: (abs number %lu)",
                //     packetSpaceRemaining, dataSize, i, packetNumber);
                
                [self writeDataToFile:packet];
                
                
                //                [self encapsulateAndShipPacket:packet packetDescriptions:packetDescriptions packetID:assetID];                
            }
            
       //     NSLog(@"now we are about to copy data to packets");
            // copy data to the packet
            memcpy((char*)packet + packetBytesFilled, 
                   (const char*)(audioBuffer.mData + dataOffset), dataSize); 
            
            
            
            // fill out packet description
            packetDescs[packetsFilled] = inPacketDescriptions[i];
            packetDescs[packetsFilled].mStartOffset = packetBytesFilled;
            
            
            packetBytesFilled += dataSize;
            packetsFilled += 1;
            
            
            // if this is the last packet, then ship it
            if (i == (inNumberPackets - 1)) {          
                //NSLog(@"woooah! this is the last packet (%d).. so we will ship it!", i);
                [self writeDataToFile:packet];
                //  [self encapsulateAndShipPacket:packet packetDescriptions:packetDescriptions packetID:assetID];                 
            }                  
        }                                                                                                     
    }
    
    NSLog(@"finished going through sample and total packets filled are %lu", totalPacketsFilled);
    
    CheckError(AudioFileClose(audioFileID), "could not close file");
    NSLog(@"successfully closed file");
}

-(void)writeDataToFile:(void *)packet
{
    
    UInt32 ioNumPackets = packetsFilled;
    
   /* NSLog(@"this is packtBody data %@",[NSData dataWithBytes:packet length:packetBytesFilled]);
    NSLog(@"these are the packet descriptions we will send over");
    [self printPacketDescriptionContents];
    NSLog(@"===== we will write %lu bytes with %lu packets", packetBytesFilled, ioNumPackets);*/
    
    if (totalPacketsFilled >= 10865)
    {
        NSLog(@"this is the last packet! watch out!");
    }
    
    OSStatus error = AudioFileWritePackets(audioFileID,
                                     false,
                                     packetBytesFilled,
                                     packetDescs, 
                                     totalPacketsFilled,
                                     &ioNumPackets,
                                     packet);    
    if (error != noErr) {
        shouldExitLoop = true;
        return;
    }
    
    
    totalPacketsFilled += ioNumPackets;
    
    packetsFilled = 0;
    packetBytesFilled = 0;
    memset(packetDescs, 0, sizeof(packetDescs)); 
    
    NSLog(@"written %zu packets with a total of  %lu", ioNumPackets, totalPacketsFilled);
    
}


-(void)printPacketDescriptionContents
{
    
    for (int i = 0; i < packetsFilled; ++i)
    {
        NSLog(@"\n----------------\n");
        NSLog(@"this is packetDescriptionArray[%d].mStartOffset: %lld", i,packetDescs[i].mStartOffset);
        NSLog(@"this is packetDescriptionArray[%d].mVariableFramesInPacket: %lu", i,packetDescs[i].mVariableFramesInPacket);
        NSLog(@"this is packetDescriptionArray[%d].mDataByteSize: %lu", i,packetDescs[i].mDataByteSize);
        NSLog(@"\n----------------\n");
    }
    
}


-(void)initFile
{
    cfURL = [self getFilename:@"destinationFile"];
    
    
    // initliaze data format to be AAC (iPod library format)
    dataFormat.mSampleRate = 44100.0;
    dataFormat.mFormatID = kAudioFormatMPEG4AAC;
    dataFormat.mFormatFlags = kAudioFormatFlagsCanonical;
    dataFormat.mBytesPerPacket = 0;
    dataFormat.mFramesPerPacket = 1024;
    dataFormat.mBytesPerFrame = 0;
    dataFormat.mChannelsPerFrame = 2;
    dataFormat.mBitsPerChannel = 0;
    dataFormat.mReserved = 0;
    
    OSStatus audioErr = noErr;
    audioErr = AudioFileCreateWithURL(cfURL, 
                                      kAudioFileMPEG4Type,      //remember, this is file *type*, not audio format, MP4 can handle PCM, AAC, AC3 +
                                      &dataFormat,
                                      kAudioFileFlags_EraseFile, 
                                      &audioFileID);
    
    
    assert(audioErr == noErr);    
    NSLog(@"we havesuccessfully created CFurl");        
}


- (CFURLRef)getFilename:(NSString *)itemID
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                         NSUserDomainMask, YES); 
    NSString* docDir = [paths objectAtIndex:0];
    NSString * slash = [docDir stringByAppendingString:@"/"];                    
    NSString* file = [slash stringByAppendingString:itemID];
    NSString* completeFile= [file stringByAppendingString:@".mp4"];    
    
    NSLog(@"destination file name %@", completeFile);
    
    const char *buffer;    
    
    buffer = [completeFile UTF8String];
    
    CFURLRef fileURL = CFURLCreateFromFileSystemRepresentation(NULL, (UInt8*)buffer, strlen(buffer), false);
    //   NSLog(@"this is the file url we are creating: %@",fileURL);
    
    return fileURL;
}

static void CheckError (OSStatus error, const char *operation)
{
    if (error == noErr) return;
    
    char errorString [20];
    // see if it asppears to be a 4-char code
    *(UInt32 *) (errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint (errorString[2]) && 
        isprint(errorString[3]) && isprint (errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else 
        // no format ist as an integer
        sprintf(errorString, "%d", (int)error);
    fprintf(stderr, "error: %s (%s)\n", operation, errorString);
    
    exit(1);
}



@end
