//
//  iPhoneStreamingPlayerViewController.h
//  iPhoneStreamingPlayer
//
//  Created by Matt Gallagher on 28/10/08.
//  Copyright Matt Gallagher 2008. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@class AudioStreamer;

@interface iPhoneStreamingPlayerViewController : UIViewController <GKSessionDelegate, GKPeerPickerControllerDelegate>
{
	IBOutlet UITextField *downloadSourceField;
	IBOutlet UIButton *button;
	IBOutlet UIView *volumeSlider;
	IBOutlet UILabel *positionLabel;
	NSTimer *progressUpdateTimer;
   	AudioStreamer *streamer;        
}

@property (nonatomic, strong) AudioStreamer *streamer;

- (IBAction)buttonPressed:(id)sender;
- (void)spinButton;
- (void)updateProgress:(NSTimer *)aNotification;
- (void)destroyStreamer;


// 4.  Methods to connect and send data
- (void) connectToPeers:(id) sender;
- (void) sendALoudFart:(id)sender;
- (void) sendASilentAssassin:(id)sender;

- (AudioStreamer *) createStreamer;

@end

