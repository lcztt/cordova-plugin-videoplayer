//
//  YSPBUtilities.m
//  Solution
//
//  Created by vitas on 2018/11/9.
//  Copyright © 2018 Solution. All rights reserved.
//

#import "YSPBUtilities.h"
#import <sys/utsname.h>


UIWindow *YSPBGetNormalWindow(void) {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow *temp in windows) {
            if (temp.windowLevel == UIWindowLevelNormal) {
                window = temp; break;
            }
        }
    }
    return window;
}

UIViewController *YSPBGetTopController(void)
{
    UIWindow *window = YSPBGetNormalWindow();
    
    UIViewController *topController = window.rootViewController;
    
    if ([topController isKindOfClass:UITabBarController.class]) {
        topController = [(UITabBarController *)topController selectedViewController];
    }
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    if ([topController isKindOfClass:UINavigationController.class]) {
        topController = [(UINavigationController *)topController visibleViewController];
    }
    
    return topController;
}


@implementation YSPBUtilities

+ (void)countTimeConsumingOfCode:(void(^)(void))code
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    code?code():nil;
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
    XCPBLOG(@"TimeConsuming: %f ms", linkTime *1000.0);
}

@end
