//
//  YSPhotoBrowserProgressView.h
//  JieYouPu
//
//  Created by vitas on 2018/11/12.
//  Copyright © 2018 XinChao. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class YSPhotoBrowserProgressView;

@interface UIView (YSPhotoBrowserProgressView)

- (void)showProgressViewWithValue:(CGFloat)progress;

- (void)showProgressViewLoading;

- (void)showProgressViewWithText:(NSString *)text click:(nullable void(^)(void))click;

- (void)hideProgressView;

@property (nonatomic, strong, readonly) YSPhotoBrowserProgressView *progressView;

@end

@interface YSPhotoBrowserProgressView : UIView

- (void)showProgress:(CGFloat)progress;

- (void)showLoading;

- (void)showText:(NSString *)text click:(void(^)(void))click;

@end

NS_ASSUME_NONNULL_END
