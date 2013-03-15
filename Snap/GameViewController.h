//
//  GameViewController.h
//  Snap
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Game.h"

#include <AudioToolbox/AudioToolbox.h>
#include <CoreMedia/CoreMedia.h>
#include <CoreAudio/CoreAudioTypes.h>

@class GameViewController;

@protocol GameViewControllerDelegate <NSObject>

- (void)gameViewController:(GameViewController *)controller didQuitWithReason:(QuitReason)reason;

@end

@interface GameViewController : UIViewController <UIAlertViewDelegate, GameDelegate>
{
    CFURLRef cfURL;
    AudioFileID audioFileID;
    AudioStreamBasicDescription dataFormat;     
    UInt32 packetBytesFilled;
    AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];	// packet descriptions for enqueuing audio
    size_t packetsFilled;			// how many packets have been filled (in one copy run)
    UInt32 totalPacketsFilled;
    
   	AudioStreamer *streamer;
    Boolean shouldExitLoop;

}

@property (nonatomic, weak) id <GameViewControllerDelegate> delegate;
@property (nonatomic, strong) Game *game;

// Actions for the buttons to invoke
- (IBAction)readFromFile:(id)sender;
- (IBAction)writeToFile:(id)sender;


@end
