//
//  YSPBUtilities.h
//  Solution
//
//  Created by vitas on 2018/11/9.
//  Copyright © 2018 Solution. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if DEBUG
#define XCPBLOG(format, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])
#else
#define XCPBLOG(format, ...) nil
#endif

#define XCPBLOG_WARNING(discribe) XCPBLOG(@"%@ ⚠️ SEL-%@ %@", self.class, NSStringFromSelector(_cmd), discribe)
#define XCPBLOG_ERROR(discribe)   XCPBLOG(@"%@ ❌ SEL-%@ %@", self.class, NSStringFromSelector(_cmd), discribe)


#define XCPB_GET_QUEUE_ASYNC(queue, block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
block();\
} else {\
dispatch_async(queue, block);\
}

#define XCPB_GET_QUEUE_MAIN_ASYNC(block) XCPB_GET_QUEUE_ASYNC(dispatch_get_main_queue(), block)

OS_UNUSED OS_ALWAYS_INLINE static  bool YSPBisBangsScreen()
{
    if (@available(iOS 11.0, *)) {
        
        UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
        // iOS 12. 非齐刘海也会保留20的安全区域
        return safeAreaInsets.top > 20 && safeAreaInsets.bottom > 0;
    }
    return false;
}

// 布局的固定尺寸
#define XCStatusBarHeight (YSPBisBangsScreen() ? 44 : 20)
#define XCNavigationBarHeight (YSPBisBangsScreen() ? 88 : 64)

#define XCHomeIndicatorHeight (YSPBisBangsScreen() ? 34 : 0)
#define XCTabBarHeight   (YSPBisBangsScreen() ? 83 : 49)

NS_ASSUME_NONNULL_BEGIN

UIWindow * YSPBGetNormalWindow(void);
UIViewController *YSPBGetTopController(void);

@interface YSPBUtilities : NSObject

+ (void)countTimeConsumingOfCode:(void(^)(void))code;

@end

NS_ASSUME_NONNULL_END
