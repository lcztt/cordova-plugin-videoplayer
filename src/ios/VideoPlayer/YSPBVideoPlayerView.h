//
//  YSPBVideoPlayerView.h
//  JieYouPu
//
//  Created by vitas on 2018/11/12.
//  Copyright © 2018 XinChao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSPBVideoPlayerViewData.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const YSPhotoBrowserVideoStartPlayNotification;
FOUNDATION_EXPORT NSString * const YSPhotoBrowserVideoDownloadCompletionNotification;

@interface YSPBVideoPlayerView : UIView

- (void)startPlay;
- (void)initializeVideoPlayerWithData:(YSPBVideoPlayerViewData *)data;

@end

NS_ASSUME_NONNULL_END
