//
//  HostViewController.h
//  Snap
//
//  Created by Ray Wenderlich on 5/24/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "MatchmakingServer.h"
#import "MusicTableViewController.h"

@class HostViewController;

@protocol HostViewControllerDelegate <NSObject>

- (void)hostViewControllerDidCancel:(HostViewController *)controller;
- (void)hostViewController:(HostViewController *)controller didEndSessionWithReason:(QuitReason)reason;
- (void)hostViewController:(HostViewController *)controller startGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients;

- (void)hostViewController:(HostViewController *)controller broadcastMusicWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients;

@end

@interface HostViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MatchmakingServerDelegate, MPMediaPickerControllerDelegate, MusicTableViewControllerDelegate, AVAudioPlayerDelegate> {
    MPMediaItemCollection		*userMediaItemCollection;
  	MPMusicPlayerController		*musicPlayer;
    
}

@property (nonatomic, weak) id <HostViewControllerDelegate> delegate;





@property (nonatomic, retain)	MPMediaItemCollection	*userMediaItemCollection; 
@property (readwrite)			BOOL					playedMusicOnce;
@property (nonatomic, retain)	MPMusicPlayerController	*musicPlayer;

@end
