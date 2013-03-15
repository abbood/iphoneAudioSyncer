//
//  AudioFile.h
//  Snap
//
//  Created by Abdullah Bakhach on 8/9/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AudioFile : NSObject {
    AudioFileID                     fileID;     // the identifier for the audio file to play
    AudioStreamBasicDescription     format;
    UInt64                          packetsCount;           
    UInt32                          maxPacketSize;  
    SInt64                          inStartingPacket;
    
}

@property (readwrite)           AudioFileID                 fileID;
@property (readwrite)           UInt64                      packetsCount;
@property (readwrite)           UInt32                      maxPacketSize;
@property (readwrite)           AudioStreamBasicDescription format;
@property (readwrite)           SInt64                      inStartingPacket;


- (id) initWithURL: (CFURLRef) url;
- (id) initWithID:(AudioFileID)id;
- (AudioStreamBasicDescription *)audioFormatRef;

@end
