//
//  AudioItem.h
//  Snap
//
//  Created by Abdullah Bakhach on 9/7/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "VirtualRingBuffer.h"


#define ITEM_CAPACITY 4194304  // limit item capacity to 4 megabytes


@interface AudioItem : NSObject
{


    NSString * ID;
    
    // metadata
    NSString * title;
    NSString * album;
    NSString * artist;
    NSString * duration;
    
    

    
    UInt32 percentageFilled;
    UInt32 timeStamp;       
    SInt64 startingByte;
    
    SInt64 inStartingPacket;
    
    AudioFileID audioFileID;

    AudioStreamBasicDescription dataFormat;
    
    @public 
        CFURLRef cfURL;
        NSString * URLString;
    
}

@property (retain, readwrite) NSString *ID;

@property (retain, readwrite) NSString *title;
@property (retain, readwrite) NSString * album;
@property (retain, readwrite) NSString * artist; 
@property (retain, readwrite) NSString * duration;



@property (retain, readwrite) NSString * URLString;
@property (assign, readwrite) CFURLRef cfURL;


@property (assign, readwrite) UInt32 percentageFilled;
@property (assign, readwrite) UInt32 timeStamp;  
@property (assign, readwrite) SInt64 inStartingPacket;

@property (assign, readwrite) AudioFileID audioFileID;
@property (assign, readwrite) SInt64 startingByte;

-(id)initWithID:(NSString *)itemID;

@end
