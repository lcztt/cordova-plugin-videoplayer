//
//  YSPBVideoPlayerView.m
//  JieYouPu
//
//  Created by vitas on 2018/11/12.
//  Copyright © 2018 XinChao. All rights reserved.
//

#import "YSPBVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "YSPBUtilities.h"
#import "YSPhotoBrowserTipView.h"
#import "YSPhotoBrowserProgressView.h"
#import "YSPBCopyWriter.h"

NSString * const YSPhotoBrowserVideoStartPlayNotification = @"YSPhotoBrowserVideoStartPlayNotification";
NSString * const YSPhotoBrowserVideoDownloadCompletionNotification = @"YSPhotoBrowserVideoDownloadCompletionNotification";

@interface YSPBVideoPlayerView () {
    AVPlayer *_player;
    AVPlayerLayer *_playerLayer;
    AVPlayerItem *_playerItem;
    
    BOOL _isPlaying;
    BOOL _isActive;
}

@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIImageView *firstFrameImageView;
@property (nonatomic, strong) YSPBVideoPlayerViewData *cellData;

@end


@implementation YSPBVideoPlayerView

#pragma mark - life cycle

- (void)dealloc {
    [self removeObserverForDataState];
    [self removeObserverForSystem];
    [self cancelPlay];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self->_isPlaying = NO;
        self->_isActive = YES;
        
        [self addSubview:self.baseView];
        [self.baseView addSubview:self.firstFrameImageView];
        
        [self addObserverForSystem];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.baseView.frame = self.bounds;
    self.firstFrameImageView.frame = [self.cellData.class getImageViewFrameWithImageSize:self.cellData.firstFrame.size];
    if (self->_playerLayer) {
        self->_playerLayer.frame = self.bounds;
    }
}

#pragma mark - publick

- (void)initializeVideoPlayerWithData:(YSPBVideoPlayerViewData *)data
{
    self.cellData = data;
    
    [self addObserverForDataState];
}

- (void)startPlay {
    if (!self.cellData.avAsset || self->_isPlaying) return;
    
    [self cancelPlay];
    
    self->_isPlaying = YES;
    
    self->_playerItem = [AVPlayerItem playerItemWithAsset:self.cellData.avAsset];
    self->_player = [AVPlayer playerWithPlayerItem:self->_playerItem];
    self->_playerLayer = [AVPlayerLayer playerLayerWithPlayer:self->_player];
    self->_playerLayer.frame = self.bounds;
    [self.baseView.layer addSublayer:self->_playerLayer];
    
    [self addObserverForPlayer];
    
    [self.baseView showProgressViewLoading];
}

- (void)cancelPlay {
    [self restorePlay];
    [self restoreAsset];
}

- (void)restorePlay {
    
    [self removeObserverForPlayer];
    
    if (self->_player) {
        [self->_player pause];
        self->_player = nil;
    }
    if (self->_playerLayer) {
        [self->_playerLayer removeFromSuperlayer];
        self->_playerLayer = nil;
    }
    self->_playerItem = nil;
    
    self->_isPlaying = NO;
}

- (void)restoreAsset
{
    AVAsset *asset = self.cellData.avAsset;
    if ([asset isKindOfClass:AVURLAsset.class]) {
        self.cellData.avAsset = [AVURLAsset assetWithURL:((AVURLAsset *)asset).URL];
    }
}

- (void)videoJumpWithScale:(float)scale
{
    CMTime startTime = CMTimeMakeWithSeconds(scale, self->_player.currentTime.timescale);
    AVPlayer *tmpPlayer = self->_player;
    [self->_player seekToTime:startTime toleranceBefore:CMTimeMake(1, 1000) toleranceAfter:CMTimeMake(1, 1000) completionHandler:^(BOOL finished) {
        if (finished && tmpPlayer == self->_player) {
            [self->_player play];
        }
    }];
}

- (void)cellDataDownloadStateChanged {
    YSPBVideoPlayerViewData *data = self.cellData;
    YSPBVideoPlayerViewDataDownloadState dataDownloadState = data.dataDownloadState;
    switch (dataDownloadState) {
        case YSPBVideoPlayerViewDataDownloadStateIsDownloading: {
            [self showProgressViewWithValue:self.cellData.downloadingVideoProgress];
        }
            break;
        case YSPBVideoPlayerViewDataDownloadStateComplete: {
            [self hideProgressView];
        }
            break;
        default:
            break;
    }
}

- (void)cellDataStateChanged {
    YSPBVideoPlayerViewData *data = self.cellData;
    YSPBVideoPlayerViewDataState dataState = data.dataState;
    switch (dataState) {
        case YSPBVideoPlayerViewDataStateInvalid: {
            [self.baseView showProgressViewWithText:[YSPBCopyWriter shareCopyWriter].videoIsInvalid click:nil];
        }
            break;
        case YSPBVideoPlayerViewDataStateFirstFrameReady: {
            self.firstFrameImageView.image = data.firstFrame;
            self.firstFrameImageView.frame = [self.cellData.class getImageViewFrameWithImageSize:self.cellData.firstFrame.size];
        }
            break;
        case YSPBVideoPlayerViewDataStateIsLoadingPHAsset: {
            [self.baseView showProgressViewLoading];
        }
            break;
        case YSPBVideoPlayerViewDataStateLoadPHAssetSuccess: {
            [self.baseView hideProgressView];
        }
            break;
        case YSPBVideoPlayerViewDataStateLoadPHAssetFailed: {
            [self.baseView showProgressViewWithText:[YSPBCopyWriter shareCopyWriter].videoIsInvalid click:nil];
        }
            break;
        case YSPBVideoPlayerViewDataStateIsLoadingFirstFrame: {
            [self.baseView showProgressViewLoading];
        }
            break;
        case YSPBVideoPlayerViewDataStateLoadFirstFrameSuccess: {
            [self.baseView hideProgressView];
            [[NSNotificationCenter defaultCenter] postNotificationName:YSPhotoBrowserVideoDownloadCompletionNotification object:nil];
        }
            break;
        case YSPBVideoPlayerViewDataStateLoadFirstFrameFailed: {
            // Get video first frame failed, also show the 'playButton'.
            [self.baseView hideProgressView];
        }
            break;
        default:
            break;
    }
}

- (void)avPlayerItemStatusChanged {
    if (!self->_isActive) return;
    
    switch (self->_playerItem.status) {
        case AVPlayerItemStatusReadyToPlay: {
            
            [self->_player play];
            [[NSNotificationCenter defaultCenter] postNotificationName:YSPhotoBrowserVideoStartPlayNotification object:nil];
            
            [self.baseView hideProgressView];
        }
            break;
        case AVPlayerItemStatusUnknown: {
            [self.baseView showProgressViewWithText:[YSPBCopyWriter shareCopyWriter].videoError click:nil];
            [self cancelPlay];
        }
            break;
        case AVPlayerItemStatusFailed: {
            [self.baseView showProgressViewWithText:[YSPBCopyWriter shareCopyWriter].videoError click:nil];
            [self cancelPlay];
        }
            break;
    }
}

#pragma mark - observe

- (void)addObserverForPlayer {
    [self->_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:self->_playerItem];
}

- (void)removeObserverForPlayer {
    [self->_playerItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self->_playerItem];
}

- (void)addObserverForDataState {
    [self.cellData addObserver:self forKeyPath:@"dataState" options:NSKeyValueObservingOptionNew context:nil];
    [self.cellData addObserver:self forKeyPath:@"dataDownloadState" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserverForDataState {
    [self.cellData removeObserver:self forKeyPath:@"dataState"];
    [self.cellData removeObserver:self forKeyPath:@"dataDownloadState"];
}

- (void)videoPlayFinish:(NSNotification *)noti {
    if (noti.object == self->_playerItem) {
        [self cancelPlay];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == self->_playerItem) {
        
        if ([keyPath isEqualToString:@"status"]) {
            [self avPlayerItemStatusChanged];
        }
    } else if (object == self.cellData) {
        
        if ([keyPath isEqualToString:@"dataState"]) {
            [self cellDataStateChanged];
        } else if ([keyPath isEqualToString:@"dataDownloadState"]) {
            [self cellDataDownloadStateChanged];
        }
    }
}

- (void)removeObserverForSystem {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)addObserverForSystem {
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)   name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    self->_isActive = NO;
    if (self->_player && self->_isPlaying) {
        [self->_player pause];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    self->_isActive = YES;
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            if (self->_player && self->_isPlaying) {
                [self->_player pause];
            }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            break;
    }
}

#pragma mark - getter

- (UIView *)baseView {
    if (!_baseView) {
        _baseView = [UIView new];
        _baseView.backgroundColor = [UIColor clearColor];
    }
    return _baseView;
}

- (UIImageView *)firstFrameImageView {
    if (!_firstFrameImageView) {
        _firstFrameImageView = [UIImageView new];
        _firstFrameImageView.contentMode = UIViewContentModeScaleAspectFit;
        _firstFrameImageView.layer.masksToBounds = YES;
    }
    return _firstFrameImageView;
}

@end
