//
//  YSPhotoBrowserTipView.h
//  Solution
//
//  Created by vitas on 2018/11/9.
//  Copyright © 2018 Solution. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, YSPhotoBrowserTipType) {
    YSPhotoBrowserTipTypeNone,
    YSPhotoBrowserTipTypeHook,
    YSPhotoBrowserTipTypeFork
};

NS_ASSUME_NONNULL_BEGIN

@class YSPhotoBrowserTipView;

@interface UIView (YSPhotoBrowserTipView)

- (void)showHookTipView:(NSString *)text;

- (void)showForkTipView:(NSString *)text;

- (void)hideTipView;

@property (nonatomic, strong, readonly) YSPhotoBrowserTipView *tipView;

@end


@interface YSPhotoBrowserTipView : UIView

- (void)startAnimationWithText:(NSString *)text type:(YSPhotoBrowserTipType)tipType;

@end

NS_ASSUME_NONNULL_END
