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
    [[YSPBVideoPlayManager shareInstance] closeVideo:command];
}

@end
