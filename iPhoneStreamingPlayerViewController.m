//
//  iPhoneStreamingPlayerViewController.m
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

#import "iPhoneStreamingPlayerViewController.h"
#import "AudioStreamer.h"
#import <QuartzCore/CoreAnimation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>

@implementation iPhoneStreamingPlayerViewController



//
// setButtonImage:
//
// Used to change the image on the playbutton. This method exists for
// the purpose of inter-thread invocation because
// the observeValueForKeyPath:ofObject:change:context: method is invoked
// from secondary threads and UI updates are only permitted on the main thread.
//
// Parameters:
//    image - the image to set on the play button.
//
- (void)setButtonImage:(UIImage *)image
{
	[button.layer removeAllAnimations];
	if (!image)
	{
		[button setImage:[UIImage imageNamed:@"playbutton.png"] forState:0];
	}
	else
	{
		[button setImage:image forState:0];
		
		if ([button.currentImage isEqual:[UIImage imageNamed:@"loadingbutton.png"]])
		{
			[self spinButton];
		}
	}
}




//
// createStreamer
//
// Creates or recreates the AudioStreamer object.
//
- (AudioStreamer *)createStreamer
{
	if (streamer)
	{
		return;
	}

	[self destroyStreamer];
	
	
	streamer = [[AudioStreamer alloc] initStreamer];
	
	progressUpdateTimer =
		[NSTimer
			scheduledTimerWithTimeInterval:0.1
			target:self
			selector:@selector(updateProgress:)
			userInfo:nil
			repeats:YES];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(playbackStateChanged:)
		name:ASStatusChangedNotification
		object:streamer];
    
    return streamer;
}

//
// viewDidLoad
//
// Creates the volume slider, sets the default path for the local file and
// creates the streamer immediately if we already have a file at the local
// location.
//
- (void)viewDidLoad
{		    
	[super viewDidLoad];
    
	// Create the buttons
	UIButton *btnConnect = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btnConnect addTarget:self action:@selector(connectToPeers:) forControlEvents:UIControlEventTouchUpInside];
	[btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
	btnConnect.frame = CGRectMake(20, 300, 280, 30);
	btnConnect.tag = 12;
	[self.view addSubview:btnConnect];
    
    // gk session end
	
	MPVolumeView *volumeView = [[[MPVolumeView alloc] initWithFrame:volumeSlider.bounds] autorelease];
	[volumeSlider addSubview:volumeView];
	[volumeView sizeToFit];
	
	[self setButtonImage:[UIImage imageNamed:@"playbutton.png"]];
}


//
// spinButton
//
// Shows the spin button when the audio is loading. This is largely irrelevant
// now that the audio is loaded from a local file.
//
- (void)spinButton
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	CGRect frame = [button frame];
	button.layer.anchorPoint = CGPointMake(0.5, 0.5);
	button.layer.position = CGPointMake(frame.origin.x + 0.5 * frame.size.width, frame.origin.y + 0.5 * frame.size.height);
	[CATransaction commit];

	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanFalse forKey:kCATransactionDisableActions];
	[CATransaction setValue:[NSNumber numberWithFloat:2.0] forKey:kCATransactionAnimationDuration];

	CABasicAnimation *animation;
	animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	animation.fromValue = [NSNumber numberWithFloat:0.0];
	animation.toValue = [NSNumber numberWithFloat:2 * M_PI];
	animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
	animation.delegate = self;
	[button.layer addAnimation:animation forKey:@"rotationAnimation"];

	[CATransaction commit];
}

//
// animationDidStop:finished:
//
// Restarts the spin animation on the button when it ends. Again, this is
// largely irrelevant now that the audio is loaded from a local file.
//
// Parameters:
//    theAnimation - the animation that rotated the button.
//    finished - is the animation finised?
//
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)finished
{
	if (finished)
	{
		[self spinButton];
	}
}

//
// buttonPressed:
//
// Handles the play/stop button. Creates, observes and starts the
// audio streamer when it is a play button. Stops the audio streamer when
// it isn't.
//
// Parameters:
//    sender - normally, the play/stop button.
//
- (IBAction)buttonPressed:(id)sender
{
	if ([button.currentImage isEqual:[UIImage imageNamed:@"playbutton.png"]])
	{
		[downloadSourceField resignFirstResponder];
		
		[self createStreamer];
		[self setButtonImage:[UIImage imageNamed:@"loadingbutton.png"]];
		[streamer start];
	}
	else
	{
		[streamer stop];
	}
}

//
// playbackStateChanged:
//
// Invoked when the AudioStreamer
// reports that its playback status has changed.
//
- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([streamer isWaiting])
	{
		[self setButtonImage:[UIImage imageNamed:@"loadingbutton.png"]];
	}
	else if ([streamer isPlaying])
	{
		[self setButtonImage:[UIImage imageNamed:@"stopbutton.png"]];
	}
	else if ([streamer isIdle])
	{
		[self destroyStreamer];
		[self setButtonImage:[UIImage imageNamed:@"playbutton.png"]];
	}
}

//
// updateProgress:
//
// Invoked when the AudioStreamer
// reports that its playback progress has changed.
//
- (void)updateProgress:(NSTimer *)updatedTimer
{
	if (streamer.bitRate != 0.0)
	{
		double progress = streamer.progress;
		positionLabel.text =
			[NSString stringWithFormat:@"Time Played: %.1f seconds",
				progress];
	}
	else
	{
		positionLabel.text = @"Time Played:";
	}
}

//
// textFieldShouldReturn:
//
// Dismiss the text field when done is pressed
//
// Parameters:
//    sender - the text field
//
// returns YES
//
- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
	[sender resignFirstResponder];
	[self createStreamer];
	return YES;
}




@end
