//
//  YSPBVideoPlayerViewData.h
//  JieYouPu
//
//  Created by vitas on 2018/11/12.
//  Copyright © 2018 XinChao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger, YSPBVideoPlayerViewDataState) {
    YSPBVideoPlayerViewDataStateInvalid,
    YSPBVideoPlayerViewDataStateFirstFrameReady,
    
    YSPBVideoPlayerViewDataStateIsLoadingFirstFrame,
    YSPBVideoPlayerViewDataStateLoadFirstFrameSuccess,
    YSPBVideoPlayerViewDataStateLoadFirstFrameFailed,
    
    YSPBVideoPlayerViewDataStateIsLoadingPHAsset,
    YSPBVideoPlayerViewDataStateLoadPHAssetSuccess,
    YSPBVideoPlayerViewDataStateLoadPHAssetFailed
};

typedef NS_ENUM(NSInteger, YSPBVideoPlayerViewDataDownloadState) {
    YSPBVideoPlayerViewDataDownloadStateNone,
    YSPBVideoPlayerViewDataDownloadStateIsDownloading,
    YSPBVideoPlayerViewDataDownloadStateComplete
};


NS_ASSUME_NONNULL_BEGIN

@interface YSPBVideoPlayerViewData : NSObject

/** The network address of video. */
@property (nonatomic, strong, nullable) NSURL *url;

/** Usually, use 'AVURLAsset'. */
@property (nonatomic, strong, nullable) AVAsset *avAsset;

/** As a preview image. Without explicit settings, the first frame will be loaded from the video source and consume some CPU resources. */
@property (nonatomic, strong, nullable) UIImage *firstFrame;

@property (nonatomic, assign) YSPBVideoPlayerViewDataState dataState;

@property (nonatomic, assign) YSPBVideoPlayerViewDataDownloadState dataDownloadState;

@property (nonatomic, assign) CGFloat downloadingVideoProgress;

+ (CGRect)getImageViewFrameWithImageSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
