//
//  LCAVPlayer.h
//  LC
//
//  Created by Shi Jackie on 2019/12/24.
//

#import <UIKit/UIKit.h>
#import "LCAVPlayerDelegate.h"


NS_ASSUME_NONNULL_BEGIN

@class LCAVPlayerModel;

@interface LCAVPlayer : UIView

@property (nonatomic, weak) id<LCAVPlayerDelegate> delegate;

@property (nonatomic, strong) LCAVPlayerModel *videoModel;

/// The player should auto player, default is NO.
@property (nonatomic, assign) BOOL shouldAutoPlay;

/// The player should loop player, default is NO.
@property (nonatomic, assign) BOOL shouldLoopPlay;

/// is on playing
@property (nonatomic, assign, readonly) BOOL isPlaying;

/// is play finish
@property (nonatomic, assign, readonly) BOOL isPlayFinish;

/// 静音状态，YES：已静音，NO：未静音
@property (nonatomic, assign) BOOL isMute;

/// 播放
- (void)play;

/// 暂停
- (void)pause;

/// 停止播放
- (void)stop;

@end

NS_ASSUME_NONNULL_END
