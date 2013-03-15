//
//  AudioItem.m
//  Snap
//
//  Created by Abdullah Bakhach on 9/7/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#include <AudioToolBox/AudioToolBox.h>
#import "AudioItem.h"

@implementation AudioItem

@synthesize ID = _ID;

@synthesize title;
@synthesize album;
@synthesize artist;
@synthesize duration;

@synthesize percentageFilled;
@synthesize timeStamp;  

@synthesize audioFileID;
@synthesize startingByte;
@synthesize URLString;

@synthesize inStartingPacket;




-(id)initWithID:(NSString *)itemID
{
    self = [super init];
    if (0 == self) return NULL;
    ID = itemID;  
    
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
    
    
  /*  NSString * fileName = itemID;
    NSString * filePath = [[[NSFileManager defaultManager] currentDirectoryPath] 
                           stringByAppendingPathComponent:@"hello"];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];*/
    
    cfURL = [self getFilename:itemID];
    OSStatus audioErr = noErr;
    audioErr = AudioFileCreateWithURL(cfURL, 
                                      kAudioFileMPEG4Type,      //remember, this is file *type*, not audio format, MP4 can handle PCM, AAC, AC3 +
                                      &dataFormat,
                                      kAudioFileFlags_EraseFile, 
                                      &audioFileID);
    

    assert(audioErr == noErr);    
    NSLog(@"we havesuccessfully created CFurl");

    return self;
}


- (CFURLRef)getFilename:(NSString *)itemID
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                         NSUserDomainMask, YES); 
    NSString* docDir = [paths objectAtIndex:0];
    NSString * slash = [docDir stringByAppendingString:@"/"];                    
    NSString* file = [slash stringByAppendingString:itemID];
    NSString* completeFile= [file stringByAppendingString:@".mp4"];    
    URLString = completeFile;
    
    const char *buffer;    
    
    buffer = [completeFile UTF8String];
    
    CFURLRef fileURL = CFURLCreateFromFileSystemRepresentation(NULL, (UInt8*)buffer, strlen(buffer), false);
 //   NSLog(@"this is the file url we are creating: %@",fileURL);
    
    return fileURL;
}


@end
