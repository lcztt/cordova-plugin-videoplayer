//
//  LCAVPlayer.m
//  LC
//
//  Created by Shi Jackie on 2019/12/24.
//

#import "LCAVPlayer.h"
#import "LCAVPlayerManager.h"
#import "LCAVPlayerPresentView.h"
#import "UIImageView+ZFCache.h"
#import "UIView+ZFFrame.h"
#import <AVFoundation/AVFoundation.h>
#import "LCAVPlayerModel.h"


@interface LCAVPlayer()
{
    struct {
        unsigned int progressStart:1; // 开始播放
        unsigned int progressOne:1; // 播放进度四分之一
        unsigned int progressTwo:1; // 播放进度四分之二
        unsigned int progressThree:1; // 播放进度四分之三
        unsigned int progressFinish:1; // 播放结束
        unsigned int notificationPause:1; // 因为APP退到后台暂停播放
    } _flag;
}

@property (nonatomic, strong) LCAVPlayerManager *playerManager;
@property (nonatomic, strong) UIImageView *coverImgView;
@property (nonatomic, strong) UIImageView *playIcon;

@end

@implementation LCAVPlayer
@dynamic isMute;

- (void)dealloc
{
    [self stop];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        [self addSubview:self.playerManager.view];
        [self addPlayerCallback];
        
        [self addSubview:self.coverImgView];
        self.coverImgView.hidden = YES;
        
        [self addSubview:self.playIcon];
        self.playIcon.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.playerManager.view.frame = self.bounds;
    self.coverImgView.frame = self.bounds;
    self.playIcon.center = CGPointMake(self.zf_width * 0.5, self.zf_height * 0.5);
}

#pragma mark - publick interface

- (void)setVideoModel:(LCAVPlayerModel *)videoModel
{
    _videoModel = videoModel;
    
    [self _setupPlayer];
}

- (void)setShouldAutoPlay:(BOOL)shouldAutoPlay
{
    _shouldAutoPlay = shouldAutoPlay;
    _playerManager.shouldAutoPlay = shouldAutoPlay;
}

- (void)setShouldLoopPlay:(BOOL)shouldLoopPlay
{
    _shouldLoopPlay = shouldLoopPlay;
    _playerManager.shouldLoopPlay = shouldLoopPlay;
}

// 播放
- (void)play
{
    // 首次播放，隐藏封面
    if (self.coverImgView.hidden == NO) {
        
        [UIView animateWithDuration:0.5 animations:^{
            self.coverImgView.alpha = 0;
        } completion:^(BOOL finished) {
            self.coverImgView.hidden = YES;
            self.coverImgView.alpha = 1;
        }];
    }
    
    self.playIcon.hidden = YES;
    [self.playerManager play];
}

// 暂停
- (void)pause
{
    [self.playerManager pause];
}

- (void)stop
{
    [self removeNotification];
    
    [self.playerManager stop];
}

- (void)setIsMute:(BOOL)isMute
{
    self.playerManager.muted = isMute;
}

- (BOOL)isMute
{
    return self.playerManager.isMuted;
}

- (BOOL)isPlaying
{
    return self.playerManager.playState == LCPlayerPlayStatePlaying;
}

- (BOOL)isPlayFinish
{
    return self.playerManager.playState == LCPlayerPlayStatePlayToEnd;
}

#pragma mark - private

- (void)_setupPlayer
{
    if (self.videoModel.cover_path) {
        __weak __typeof(self) weakSelf = self;
        NSString *urlStr = self.videoModel.cover_path;
        [self.coverImgView setImageWithURLString:urlStr placeholderImageName:nil completion:^(UIImage *image) {
            if (image) {
                if ([weakSelf.delegate respondsToSelector:@selector(playerDidShowVideoCover:)]) {
                    [weakSelf.delegate playerDidShowVideoCover:weakSelf];
                }
            }
        }];
        
        self.coverImgView.hidden = NO;
    }
    
    NSURL *url = [NSURL URLWithString:self.videoModel.video_path];
    if (!url) {
        return;
    }
    
    self.playerManager.assetURL = url;
    [self.playerManager prepareToPlay];
    [self addNotification];
}

- (void)addPlayerCallback
{
    __weak __typeof(self) weakSelf = self;
    
    self.playerManager.playerPrepareToPlay = ^(LCAVPlayerManager * _Nonnull asset, NSURL * _Nonnull assetURL) {
        
    };
    
    
    self.playerManager.playerReadyToPlay = ^(LCAVPlayerManager * _Nonnull asset, NSURL * _Nonnull assetURL) {
        
        // 首次播放，隐藏封面
        if (weakSelf.coverImgView.hidden == NO) {
            [UIView animateWithDuration:0.5 animations:^{
                weakSelf.coverImgView.alpha = 0;
            } completion:^(BOOL finished) {
                weakSelf.coverImgView.hidden = YES;
                weakSelf.coverImgView.alpha = 1;
            }];
        }
        
        if ([weakSelf.delegate respondsToSelector:@selector(playerDidReadyToPlay:)]) {
            [weakSelf.delegate playerDidReadyToPlay:weakSelf];
        }
    };
    
    self.playerManager.playerPlayTimeChanged = ^(LCAVPlayerManager * _Nonnull asset, NSTimeInterval currentTime, NSTimeInterval duration) {
        
        if (duration <= 0) {
            return;
        }
        
        if ([weakSelf.delegate respondsToSelector:@selector(playerDidPlaying:progress:duration:)]) {
            [weakSelf.delegate playerDidPlaying:weakSelf progress:currentTime duration:duration];
        }
    };
    
    self.playerManager.playerDidToEnd = ^(LCAVPlayerManager * _Nonnull asset) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf->_flag.progressFinish) {
            strongSelf->_flag.progressFinish = YES;
            
            if ([weakSelf.delegate respondsToSelector:@selector(playerDidPlayFinish:)]) {
                [weakSelf.delegate playerDidPlayFinish:weakSelf];
            }
        }
        
        weakSelf.playIcon.hidden = NO;
    };
    
    self.playerManager.playerPlayFailed = ^(LCAVPlayerManager * _Nonnull asset, id  _Nonnull error) {
        
        if ([weakSelf.delegate respondsToSelector:@selector(playerDidLoadFail:error:)]) {
            [weakSelf.delegate playerDidLoadFail:weakSelf error:error];
        }
    };
    
    self.playerManager.playerPlayStateChanged = ^(LCAVPlayerManager * _Nonnull asset, LCPlayerPlayState playState) {
        
        if (playState == LCPlayerPlayStatePaused) {
//            weakSelf.playIcon.hidden = NO;
        } else if (playState == LCPlayerPlayStatePlaying) {
            weakSelf.playIcon.hidden = YES;
        }
    };
    
    self.playerManager.presentationSizeChanged = ^(LCAVPlayerManager * _Nonnull asset, CGSize size) {
        
    };
}

#pragma mark - notification

- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationHandler:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationHandler:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)notificationHandler:(NSNotification *)notification
{
    if ([notification.name isEqualToString:UIApplicationWillResignActiveNotification]) {
        
        if (self.isPlaying) {
            _flag.notificationPause = YES;
            [self pause];
        }
        
    } else if ([notification.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
        
        if (_flag.notificationPause) {
            _flag.notificationPause = NO;
            [self play];
        }
    }
}

#pragma mark - getter, setter

- (LCAVPlayerManager *)playerManager
{
    if (!_playerManager) {
        _playerManager = [[LCAVPlayerManager alloc] init];
        _playerManager.shouldAutoPlay = self.shouldAutoPlay;
    }
    return _playerManager;
}

- (UIImageView *)coverImgView
{
    if (!_coverImgView) {
        _coverImgView = [[UIImageView alloc] init];
        _coverImgView.backgroundColor = [UIColor clearColor];
        _coverImgView.userInteractionEnabled = YES;
        _coverImgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return _coverImgView;
}

- (UIImageView *)playIcon
{
    if (!_playIcon) {
        _playIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]];
    }
    
    return _playIcon;
}

@end
