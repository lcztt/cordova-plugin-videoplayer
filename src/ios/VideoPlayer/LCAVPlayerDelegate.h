//
//  LCAVPlayerDelegate.h
//  LC
//
//  Created by touchpal on 2020/3/26.
//

#import <Foundation/Foundation.h>
@import AVFoundation;
#import "LCAVPlayerManager.h"
@class LCAVPlayer;

NS_ASSUME_NONNULL_BEGIN

@protocol LCAVPlayerDelegate <NSObject>

@optional
/// 展示视频封面
- (void)playerDidShowVideoCover:(LCAVPlayer *)view;
/// 视频加载成功，等待播放
- (void)playerDidReadyToPlay:(LCAVPlayer *)playView;
/// 视频加载失败
- (void)playerDidLoadFail:(LCAVPlayer *)playView error:(nullable NSError *)error;
/// 播放进度更新
- (void)playerDidPlaying:(LCAVPlayer *)playView progress:(NSTimeInterval)progress duration:(NSTimeInterval)duration;
/// 播放结束
- (void)playerDidPlayFinish:(LCAVPlayer *)playView;
/// 播放状态更新
- (void)playerDidUpdateState:(LCPlayerPlayState)state;

@end

NS_ASSUME_NONNULL_END
