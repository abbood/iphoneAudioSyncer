//
//  AudioFile.m
//  Snap
//
//  Created by Abdullah Bakhach on 8/9/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "AudioFile.h"
#import "HostViewController.h"

@implementation AudioFile

@synthesize fileID;
@synthesize format;
@synthesize maxPacketSize;
@synthesize packetsCount;
@synthesize inStartingPacket;


- (id)initWithURL:(CFURLRef)url
{
    if (self = [super init]){       
        
        
        AudioFileOpenURL(
                         url,
                         0x01, //fsRdPerm, read only
                         0, //no hint
                         &fileID
                         );
        
        UInt32 sizeOfPlaybackFormatASBDStruct = sizeof format;
        AudioFileGetProperty (
                              fileID, 
                              kAudioFilePropertyDataFormat,
                              &sizeOfPlaybackFormatASBDStruct,
                              &format
                              );
        
        UInt32 propertySize = sizeof (maxPacketSize);        
        AudioFileGetProperty (
                              fileID, 
                              kAudioFilePropertyMaximumPacketSize,
                              &propertySize,
                              &maxPacketSize
                              );
        
        propertySize = sizeof(packetsCount);
        AudioFileGetProperty(fileID, 
                             kAudioFilePropertyAudioDataPacketCount, 
                             &propertySize, 
                             &packetsCount
                             );
        
        propertySize = sizeof (inStartingPacket);
        AudioFileGetProperty(fileID, 
                             kAudioFilePropertyDataOffset,
                             &propertySize,
                             &inStartingPacket
                             );
    }
    
    return self;
} 

- (id)initWithID:(AudioFileID)id 
{
    if (self = [super init]){       
                
        UInt32 sizeOfPlaybackFormatASBDStruct = sizeof format;
        AudioFileGetProperty (
                              fileID, 
                              kAudioFilePropertyDataFormat,
                              &sizeOfPlaybackFormatASBDStruct,
                              &format
                              );
        
        UInt32 propertySize = sizeof (maxPacketSize);        
        AudioFileGetProperty (
                              fileID, 
                              kAudioFilePropertyMaximumPacketSize,
                              &propertySize,
                              &maxPacketSize
                              );
        
        propertySize = sizeof(packetsCount);
        AudioFileGetProperty(fileID, 
                             kAudioFilePropertyAudioDataPacketCount, 
                             &propertySize, 
                             &packetsCount
                             );
        
        propertySize = sizeof (inStartingPacket);
        AudioFileGetProperty(fileID, 
                             kAudioFilePropertyDataOffset,
                             &propertySize,
                             &inStartingPacket
                             );
    }
    
    return self;            
}


-(AudioStreamBasicDescription *)audioFormatRef{
    return &format;
}

- (void) dealloc {
    NSLog(@"about to close audio file %@", self);
    AudioFileClose(fileID);
}


@end
