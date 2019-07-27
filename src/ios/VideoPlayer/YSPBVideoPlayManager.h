//
//  YSPBVideoPlayManager.h
//  HelloWorld
//
//  Created by vitas on 2019/7/27.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSPBVideoPlayManager : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, weak) id <CDVCommandDelegate> commandDelegate;

- (void)playVideo:(CDVInvokedUrlCommand *)command;
- (void)closeVideo:(CDVInvokedUrlCommand *)command;

@end

NS_ASSUME_NONNULL_END
