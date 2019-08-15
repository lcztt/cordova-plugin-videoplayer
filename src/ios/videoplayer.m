/********* videoplayer.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "YSPBVideoPlayManager.h"

@interface videoplayer : CDVPlugin

@end

@implementation videoplayer

- (void)playVideo:(CDVInvokedUrlCommand*)command
{
    [YSPBVideoPlayManager shareInstance].commandDelegate = self.commandDelegate;
    [[YSPBVideoPlayManager shareInstance] playVideo:command];
}

- (void)closeVideo:(CDVInvokedUrlCommand *)command
{
    [YSPBVideoPlayManager shareInstance].commandDelegate = self.commandDelegate;
    [[YSPBVideoPlayManager shareInstance] closeVideo:command];
}

- (void)pauseVideo:(CDVInvokedUrlCommand *)command
{
    [YSPBVideoPlayManager shareInstance].commandDelegate = self.commandDelegate;
    [[YSPBVideoPlayManager shareInstance] pauseVideo:command];
}

- (void)replay:(CDVInvokedUrlCommand *)command
{
    [YSPBVideoPlayManager shareInstance].commandDelegate = self.commandDelegate;
    [[YSPBVideoPlayManager shareInstance] replay:command];
}

- (void)mute:(CDVInvokedUrlCommand *)command;
{
    [YSPBVideoPlayManager shareInstance].commandDelegate = self.commandDelegate;
    [[YSPBVideoPlayManager shareInstance] mute:command];
}

@end
