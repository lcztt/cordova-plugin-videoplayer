//
//  LCAVPlayerManager.m
//  LC
//
//  Created by touchpal on 2020/5/25.
//

#import "LCAVPlayerManager.h"
#import "LCAVPlayerPresentView.h"
#import "LCAVKVOController.h"
#import "LCAVNetworkReachability.h"


@import AVFoundation;

/*!
 *  Refresh interval for timed observations of AVPlayer
 */
static NSString *const kStatus                   = @"status";
static NSString *const kLoadedTimeRanges         = @"loadedTimeRanges";
static NSString *const kPlaybackBufferEmpty      = @"playbackBufferEmpty";
static NSString *const kPlaybackLikelyToKeepUp   = @"playbackLikelyToKeepUp";
static NSString *const kPresentationSize         = @"presentationSize";
static NSString *const kTimeControlStatus        = @"timeControlStatus";
static NSString *const kReasonForWaitingToPlay   = @"reasonForWaitingToPlay";


@interface LCAVPlayerManager () {
    id _timeObserver;
    id _itemEndObserver;
    LCAVKVOController *_playerItemKVO;
}

@property (nonatomic, assign) BOOL isBuffering;
@property (nonatomic, assign) BOOL isReadyToPlay;

@end

@implementation LCAVPlayerManager
@synthesize view                           = _view;
@synthesize currentTime                    = _currentTime;
@synthesize totalTime                      = _totalTime;
@synthesize playerPlayTimeChanged          = _playerPlayTimeChanged;
@synthesize playerBufferTimeChanged        = _playerBufferTimeChanged;
@synthesize playerDidToEnd                 = _playerDidToEnd;
@synthesize bufferTime                     = _bufferTime;
@synthesize playState                      = _playState;
@synthesize loadState                      = _loadState;
@synthesize assetURL                       = _assetURL;
@synthesize playerPrepareToPlay            = _playerPrepareToPlay;
@synthesize playerReadyToPlay              = _playerReadyToPlay;
@synthesize playerPlayStateChanged         = _playerPlayStateChanged;
@synthesize playerLoadStateChanged         = _playerLoadStateChanged;
@synthesize seekTime                       = _seekTime;
@synthesize muted                          = _muted;
@synthesize volume                         = _volume;
@synthesize presentationSize               = _presentationSize;
@synthesize isPlaying                      = _isPlaying;
@synthesize rate                           = _rate;
@synthesize isPreparedToPlay               = _isPreparedToPlay;
@synthesize shouldAutoPlay                 = _shouldAutoPlay;
@synthesize scalingMode                    = _scalingMode;
@synthesize playerPlayFailed               = _playerPlayFailed;
@synthesize presentationSizeChanged        = _presentationSizeChanged;


- (instancetype)init
{
    self = [super init];
    if (self) {
        _scalingMode = LCPlayerScalingModeAspectFit; // LCPlayerScalingModeAspectFill 无黑边适配全屏
        _shouldAutoPlay = NO;
    }
    return self;
}

- (void)prepareToPlay
{
    if (!_assetURL) {
        return;
    }
    
    _isPreparedToPlay = YES;
    
    [self initializePlayer];
    
    self.loadState = LCPlayerLoadStatePrepare;
    
    if (self.playerPrepareToPlay) {
        self.playerPrepareToPlay(self, self.assetURL);
    }
    
    if (self.shouldAutoPlay) {
        [self play];
    }
}

- (void)reloadPlayer {
    self.seekTime = self.currentTime;
    [self prepareToPlay];
}

- (void)play {
    if (!_isPreparedToPlay) {
        [self prepareToPlay];
    } else {
        [self.player play];
        self.player.rate = self.rate;
        _isPlaying = YES;
        self.playState = LCPlayerPlayStatePlaying;
    }
}

- (void)pause {
    [self.player pause];
    _isPlaying = NO;
    self.playState = LCPlayerPlayStatePaused;
    [_playerItem cancelPendingSeeks];
    [_asset cancelLoading];
}

- (void)replay {
    __weak __typeof(self) weakSelf = self;
    [self seekToTime:0 completionHandler:^(BOOL finished) {
        
        [weakSelf play];
    }];
}

- (void)stop {
    [_playerItemKVO safelyRemoveAllObservers];
    self.loadState = LCPlayerLoadStateUnknown;
    self.playState = LCPlayerPlayStatePlayStopped;
    if (self.player.rate != 0) {
        [self.player pause];
    }
    [self.player removeTimeObserver:_timeObserver];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    _timeObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:_itemEndObserver name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    _itemEndObserver = nil;
    _isPlaying = NO;
    _player = nil;
    _assetURL = nil;
    _playerItem = nil;
    _isPreparedToPlay = NO;
    _currentTime = 0;
    _totalTime = 0;
    _bufferTime = 0;
    self.isReadyToPlay = NO;
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler {
    if (self.totalTime > 0) {
        CMTime seekTime = CMTimeMake(time, 1);
        [_player seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
    } else {
        self.seekTime = time;
    }
}

- (UIImage *)thumbnailImageAtCurrentTime {
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:_asset];
    CMTime expectedTime = _playerItem.currentTime;
    CGImageRef cgImage = NULL;
    
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    cgImage = [imageGenerator copyCGImageAtTime:expectedTime actualTime:NULL error:NULL];
    
    if (!cgImage) {
        imageGenerator.requestedTimeToleranceBefore = kCMTimePositiveInfinity;
        imageGenerator.requestedTimeToleranceAfter = kCMTimePositiveInfinity;
        cgImage = [imageGenerator copyCGImageAtTime:expectedTime actualTime:NULL error:NULL];
    }
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

#pragma mark - private method

/// Calculate buffer progress
- (NSTimeInterval)availableDuration {
    NSArray *timeRangeArray = _playerItem.loadedTimeRanges;
    CMTime currentTime = [_player currentTime];
    BOOL foundRange = NO;
    CMTimeRange aTimeRange = {0};
    if (timeRangeArray.count) {
        aTimeRange = [[timeRangeArray objectAtIndex:0] CMTimeRangeValue];
        if (CMTimeRangeContainsTime(aTimeRange, currentTime)) {
            foundRange = YES;
        }
    }
    
    if (foundRange) {
        CMTime maxTime = CMTimeRangeGetEnd(aTimeRange);
        NSTimeInterval playableDuration = CMTimeGetSeconds(maxTime);
        if (playableDuration > 0) {
            return playableDuration;
        }
    }
    return 0;
}

- (void)initializePlayer
{
    _asset = [AVURLAsset URLAssetWithURL:self.assetURL options:self.requestHeader];
    _playerItem = [AVPlayerItem playerItemWithAsset:_asset];
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    
    [self enableAudioTracks:YES inPlayerItem:_playerItem];
    
    LCAVPlayerPresentView *presentView = (LCAVPlayerPresentView *)self.view;
    presentView.player = _player;
    self.scalingMode = _scalingMode;
    if (@available(iOS 9.0, *)) {
        _playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = NO;
    }
    if (@available(iOS 10.0, *)) {
        _playerItem.preferredForwardBufferDuration = 5;
        _player.automaticallyWaitsToMinimizeStalling = NO;
    }
    [self itemObserving];
}

/// Playback speed switching method
- (void)enableAudioTracks:(BOOL)enable inPlayerItem:(AVPlayerItem *)playerItem
{
    for (AVPlayerItemTrack *track in playerItem.tracks) {
        if ([track.assetTrack.mediaType isEqual:AVMediaTypeVideo]) {
            track.enabled = enable;
        }
    }
}

/**
 *  缓冲较差时候回调这里
 */
- (void)bufferingSomeSecond {
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    if (self.isBuffering || self.playState == LCPlayerPlayStatePlayStopped) {
        return;
    }
    
    /// 没有网络
    if ([LCAVNetworkReachability defaultReachability].status == LCAVNetworkReachabilityStatusNotReachable) {
        return;
    }
    
    self.isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.player pause];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (!self.isPlaying && self.loadState == LCPlayerLoadStateStalled) {
            self.isBuffering = NO;
            return;
        }
        
        [self play];
        
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        self.isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
}

- (void)itemObserving
{
    [_playerItemKVO safelyRemoveAllObservers];
    _playerItemKVO = [[LCAVKVOController alloc] initWithTarget:_playerItem];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kStatus
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kPlaybackBufferEmpty
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kPlaybackLikelyToKeepUp
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kLoadedTimeRanges
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kPresentationSize
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    
    CMTime interval = CMTimeMakeWithSeconds(self.timeRefreshInterval > 0 ? self.timeRefreshInterval : 0.1, NSEC_PER_SEC);
    __weak __typeof(self) weakSelf = self;
    _timeObserver = [self.player addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        if (!weakSelf) {
            return;
        }
        
        if (weakSelf.playState == LCPlayerPlayStatePlayToEnd) {
            return;
        }
        
        if (weakSelf.isPlaying && weakSelf.loadState == LCPlayerLoadStateStalled) {
            weakSelf.player.rate = weakSelf.rate;
        }
        
        NSArray *loadedRanges = weakSelf.playerItem.seekableTimeRanges;
        if (loadedRanges.count > 0) {
            if (weakSelf.playerPlayTimeChanged) {
                weakSelf.playerPlayTimeChanged(weakSelf, weakSelf.currentTime, weakSelf.totalTime);
            }
        }
    }];
    
    _itemEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        if (!weakSelf) {
            return;
        }
        
        if (weakSelf.playState == LCPlayerPlayStatePlayToEnd) {
            return;
        }
        
        weakSelf.playState = LCPlayerPlayStatePlayToEnd;
        strongSelf->_isPlaying = NO;
        
        if (weakSelf.playerDidToEnd) {
            weakSelf.playerDidToEnd(weakSelf);
        }
        
        if (weakSelf.shouldLoopPlay) {
            [weakSelf seekToTime:0 completionHandler:^(BOOL finished) {
                [weakSelf play];
            }];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([keyPath isEqualToString:kStatus]) {
            
            if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                
                if (!self.isReadyToPlay) {
                    self.isReadyToPlay = YES;
                    
                    self.loadState = LCPlayerLoadStatePlaythroughOK;
                    if (self.playerReadyToPlay) {
                        self.playerReadyToPlay(self, self.assetURL);
                    }
                    
                    NSArray<AVPlayerItemTrack *> *tracks = self.playerItem.tracks;
                    AVAssetTrack *videoTrack = nil;
                    AVAssetTrack *audioTrack = nil;
                    for (AVPlayerItemTrack *track in tracks) {
                        if ([track.assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) {
                            videoTrack = track.assetTrack;
                        } else if ([track.assetTrack.mediaType isEqualToString:AVMediaTypeAudio]) {
                            audioTrack = track.assetTrack;
                        }
                    }
                    
                    if (videoTrack) {
                        if (self.playerAssetPlayable) {
                            self.playerAssetPlayable(self, AVMediaTypeVideo, videoTrack.playable);
                        }
                    }
                }
                
                if (self.seekTime) {
                    [self seekToTime:self.seekTime completionHandler:nil];
                    self.seekTime = 0;
                }
                
                if (self.isPlaying) {
                    [self play];
                }
                
                self.player.muted = self.muted;
                
                NSArray *loadedRanges = self.playerItem.seekableTimeRanges;
                if (loadedRanges.count > 0) {
                    if (self.playerPlayTimeChanged) {
                        self.playerPlayTimeChanged(self, self.currentTime, self.totalTime);
                    }
                }
            } else if (self.player.currentItem.status == AVPlayerItemStatusFailed) {
                
                self.playState = LCPlayerPlayStatePlayFailed;
                NSError *error = self.player.currentItem.error;
                if (self.playerPlayFailed) {
                    self.playerPlayFailed(self, error);
                }
            }
        } else if ([keyPath isEqualToString:kPlaybackBufferEmpty]) {
            
            // When the buffer is empty
            if (self.playerItem.playbackBufferEmpty) {
                self.loadState = LCPlayerLoadStateStalled;
                [self bufferingSomeSecond];
            }
        } else if ([keyPath isEqualToString:kPlaybackLikelyToKeepUp]) {
            
            // When the buffer is good
            if (self.playerItem.playbackLikelyToKeepUp) {
                self.loadState = LCPlayerLoadStatePlayable;
                if (self.isPlaying) {
                    [self.player play];
                }
            }
        } else if ([keyPath isEqualToString:kLoadedTimeRanges]) {
            
            NSTimeInterval bufferTime = [self availableDuration];
            self->_bufferTime = bufferTime;
            if (self.playerBufferTimeChanged) {
                self.playerBufferTimeChanged(self, bufferTime);
            }
        } else if ([keyPath isEqualToString:kPresentationSize]) {
            
            self->_presentationSize = self.playerItem.presentationSize;
            if (self.presentationSizeChanged) {
                self.presentationSizeChanged(self, self->_presentationSize);
            }
        } else {
            
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    });
}

#pragma mark - getter

- (UIView *)view
{
    if (!_view) {
        _view = [[LCAVPlayerPresentView alloc] init];
    }
    return _view;
}

- (float)rate
{
    return _rate == 0 ? 1 : _rate;
}

- (NSTimeInterval)totalTime
{
    NSTimeInterval sec = CMTimeGetSeconds(self.player.currentItem.duration);
    if (isnan(sec)) {
        return 0;
    }
    return sec;
}

- (NSTimeInterval)currentTime
{
    NSTimeInterval sec = CMTimeGetSeconds(self.playerItem.currentTime);
    if (isnan(sec) || sec < 0) {
        return 0;
    }
    return sec;
}

#pragma mark - setter

- (void)setPlayState:(LCPlayerPlayState)playState
{
    _playState = playState;
    
    if (self.playerPlayStateChanged) {
        self.playerPlayStateChanged(self, playState);
    }
}

- (void)setLoadState:(LCPlayerLoadState)loadState
{
    _loadState = loadState;
    
    if (self.playerLoadStateChanged) {
        self.playerLoadStateChanged(self, loadState);
    }
}

- (void)setAssetURL:(NSURL *)assetURL
{
    if (self.player) {
        [self stop];
    }
    _assetURL = assetURL;
    [self prepareToPlay];
}

- (void)setRate:(float)rate
{
    _rate = rate;
    if (self.player && fabsf(_player.rate) > 0.00001f) {
        self.player.rate = rate;
    }
}

- (void)setMuted:(BOOL)muted
{
    _muted = muted;
    self.player.muted = muted;
}

- (void)setScalingMode:(LCPlayerScalingMode)scalingMode
{
    _scalingMode = scalingMode;
    LCAVPlayerPresentView *presentView = (LCAVPlayerPresentView *)self.view;
    switch (scalingMode) {
        case LCPlayerScalingModeNone:
            presentView.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case LCPlayerScalingModeAspectFit:
            presentView.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case LCPlayerScalingModeAspectFill:
            presentView.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case LCPlayerScalingModeFill:
            presentView.videoGravity = AVLayerVideoGravityResize;
            break;
        default:
            break;
    }
}

- (void)setVolume:(float)volume
{
    _volume = MIN(MAX(0, volume), 1);
    self.player.volume = volume;
}

@end
