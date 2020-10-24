//
//  LCAVPlayerManager.h
//  LC
//
//  Created by touchpal on 2020/5/25.
//

#import <Foundation/Foundation.h>

@class LCAVPlayerPresentView;
@import AVFoundation;


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LCPlayerPlayState) {
    LCPlayerPlayStateUnknown,
    LCPlayerPlayStatePlaying,
    LCPlayerPlayStatePlayFailed,
    LCPlayerPlayStatePaused,
    LCPlayerPlayStatePlayStopped,
    LCPlayerPlayStatePlayToEnd
};

typedef NS_OPTIONS(NSUInteger, LCPlayerLoadState) {
    LCPlayerLoadStateUnknown        = 0,
    LCPlayerLoadStatePrepare        = 1 << 0,
    LCPlayerLoadStatePlayable       = 1 << 1,
    LCPlayerLoadStatePlaythroughOK  = 1 << 2, // Playback will be automatically started.
    LCPlayerLoadStateStalled        = 1 << 3, // Playback will be automatically paused in this state, if started.
};

typedef NS_ENUM(NSInteger, LCPlayerScalingMode) {
    LCPlayerScalingModeNone,       // No scaling.
    LCPlayerScalingModeAspectFit,  // Uniform scale until one dimension fits.
    LCPlayerScalingModeAspectFill, // Uniform scale until the movie fills the visible bounds. One dimension may have clipped contents.
    LCPlayerScalingModeFill        // Non-uniform scale. Both render dimensions will exactly match the visible bounds.
};

@interface LCAVPlayerManager : NSObject

/// The play asset URL.
@property (nonatomic) NSURL *assetURL;

/// The current play asset for assetURL.
@property (nonatomic, strong, readonly) AVURLAsset *asset;

/// The current playerItem.
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;

/// The player.
@property (nonatomic, strong, readonly) AVPlayer *player;

@property (nonatomic, assign) NSTimeInterval timeRefreshInterval;

/// video asset request options
@property (nonatomic, strong) NSDictionary *requestHeader;

/// video preview
@property (nonatomic, strong) LCAVPlayerPresentView *view;

/// The player volume.
/// Only affects audio volume for the player instance and not for the device.
@property (nonatomic, assign) float volume;

/// The player muted.
/// indicates whether or not audio output of the player is muted. Only affects audio muting for the player instance and not for the device.
@property (nonatomic, assign, getter=isMuted) BOOL muted;

/// Playback speed,0.5...2
@property (nonatomic, assign) float rate;

/// The player current play time.
@property (nonatomic, readonly) NSTimeInterval currentTime;

/// The player total time.
@property (nonatomic, readonly) NSTimeInterval totalTime;

/// The player buffer time.
@property (nonatomic, readonly) NSTimeInterval bufferTime;

/// The player seek time.
@property (nonatomic, assign) NSTimeInterval seekTime;

/// The player play state,playing or not playing.
@property (nonatomic, readonly) BOOL isPlaying;

/// Determines how the content scales to fit the view. Defaults to LCPlayerScalingModeNone.
@property (nonatomic, assign) LCPlayerScalingMode scalingMode;

/**
 @abstract Check whether video preparation is complete.
 @discussion isPreparedToPlay processing logic
 
 * If isPreparedToPlay is true, you can call [LCAVPlayerManager play] API start playing;
 * If isPreparedToPlay to false, direct call [LCAVPlayerManager play], in the play the internal automatic call [LCAVPlayerManager prepareToPlay] API.
 * Returns true if prepared for playback.
 */
@property (nonatomic, readonly) BOOL isPreparedToPlay;

/// The player should auto player, default is NO.
@property (nonatomic) BOOL shouldAutoPlay;

/// The player should loop player, default is NO.
@property (nonatomic) BOOL shouldLoopPlay;

/// The video size.
@property (nonatomic, readonly) CGSize presentationSize;

/// The playback state.
@property (nonatomic, readonly) LCPlayerPlayState playState;

/// The player load state.
@property (nonatomic, readonly) LCPlayerLoadState loadState;

///------------------------------------
/// If you don't appoint the controlView, you can called the following blocks.
/// If you appoint the controlView, The following block cannot be called outside, only for `ZFPlayerController` calls.
///------------------------------------

/// The block invoked when the player is Prepare to play.
@property (nonatomic, copy, nullable) void(^playerPrepareToPlay)(LCAVPlayerManager *asset, NSURL *assetURL);

/// The block invoked when the player is Ready to play.
@property (nonatomic, copy, nullable) void(^playerReadyToPlay)(LCAVPlayerManager *asset, NSURL *assetURL);

/// The block invoked when the player play progress changed.
@property (nonatomic, copy, nullable) void(^playerPlayTimeChanged)(LCAVPlayerManager *asset, NSTimeInterval currentTime, NSTimeInterval duration);

/// The block invoked when the player play buffer changed.
@property (nonatomic, copy, nullable) void(^playerBufferTimeChanged)(LCAVPlayerManager *asset, NSTimeInterval bufferTime);

/// The block invoked when the player playback state changed.
@property (nonatomic, copy, nullable) void(^playerPlayStateChanged)(LCAVPlayerManager *asset, LCPlayerPlayState playState);

/// The block invoked when the player load state changed.
@property (nonatomic, copy, nullable) void(^playerLoadStateChanged)(LCAVPlayerManager *asset, LCPlayerLoadState loadState);

/// The block invoked when the player play failed.
@property (nonatomic, copy, nullable) void(^playerPlayFailed)(LCAVPlayerManager *asset, id error);

/// The block invoked when the player is Ready to play.
@property (nonatomic, copy, nullable) void(^playerAssetPlayable)(LCAVPlayerManager *asset, AVMediaType type, BOOL playable);

/// The block invoked when the player play end.
@property (nonatomic, copy, nullable) void(^playerDidToEnd)(LCAVPlayerManager *asset);

// The block invoked when video size changed.
@property (nonatomic, copy, nullable) void(^presentationSizeChanged)(LCAVPlayerManager *asset, CGSize size);

///------------------------------------
/// end
///------------------------------------

/// Prepares the current queue for playback, interrupting any active (non-mixible) audio sessions.
- (void)prepareToPlay;

/// Reload player.
- (void)reloadPlayer;

/// Play playback.
- (void)play;

/// Pauses playback.
- (void)pause;

/// Replay playback.
- (void)replay;

/// Stop playback.
- (void)stop;

/// Video UIImage at the current time.
- (UIImage *)thumbnailImageAtCurrentTime;

/// Use this method to seek to a specified time for the current player and to be notified when the seek operation is complete.
- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler;

@end

NS_ASSUME_NONNULL_END
