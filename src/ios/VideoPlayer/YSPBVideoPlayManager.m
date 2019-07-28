//
//  YSPBVideoPlayManager.m
//  HelloWorld
//
//  Created by vitas on 2019/7/27.
//

#import "YSPBVideoPlayManager.h"
#import "YSPBVideoPlayerView.h"
#import "YSPBVideoPlayerViewData.h"
#import "MainViewController.h"


@interface YSPBVideoPlayManager ()

@property (nonatomic, strong) CDVInvokedUrlCommand *command;
@property (nonatomic, strong) YSPBVideoPlayerView *videoPlayer;
@property (nonatomic, strong) UIColor *webViewBackColor;

@end

@implementation YSPBVideoPlayManager

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static YSPBVideoPlayManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[YSPBVideoPlayManager alloc] init];
    });
    return manager;
}

- (void)playVideo:(CDVInvokedUrlCommand*)command
{
    if (command.arguments.count != 1) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSDictionary *params = (NSDictionary *)[command.arguments objectAtIndex:0];
    if (![params isKindOfClass:[NSDictionary class]] || params.count == 0) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSLog(@"%@", params);
    
    MainViewController *vc = (MainViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if (![vc isKindOfClass:[MainViewController class]]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.y = frame.size.height;
    if (self.videoPlayer) {
        NSString *videoPath = params[@"videoPath"];
        if ([self.videoPlayer.playData.url.absoluteString isEqualToString:videoPath]) {
            [self.videoPlayer startPlay];
            return;
        }
        
        [self.videoPlayer removeFromSuperview];
        self.videoPlayer = nil;
    }
    self.videoPlayer = [[YSPBVideoPlayerView alloc] initWithFrame:frame];
    [vc.view insertSubview:self.videoPlayer belowSubview:vc.webView];
    
    self.webViewBackColor = vc.webView.backgroundColor;
    vc.webView.backgroundColor = [UIColor clearColor];
    vc.webView.opaque = false;
    
    [UIView animateWithDuration:0.25 animations:^{
        CGRect frame = self.videoPlayer.frame;
        frame.origin.y = 0;
        self.videoPlayer.frame = frame;
    } completion:^(BOOL finished) {
        
        [self addNotification];
        
        YSPBVideoPlayerViewData *data = [[YSPBVideoPlayerViewData alloc] init];
        NSString *videoPath = params[@"videoPath"];
        data.url = [NSURL URLWithString:videoPath];
        [self.videoPlayer initializeVideoPlayerWithData:data];
        [self.videoPlayer startPlay];
    }];
    
    NSDictionary *paramss = @{@"status":@(0)};
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self jsonStringEncodedWith:paramss]];
    pluginResult.keepCallback = @(1);
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)closeVideo:(CDVInvokedUrlCommand *)command
{
    if (self.videoPlayer) {
        [UIView animateWithDuration:0.25 animations:^{
            CGRect frame = self.videoPlayer.frame;
            frame.origin.y = 0;
            self.videoPlayer.frame = frame;
        } completion:^(BOOL finished) {
            [self.videoPlayer removeFromSuperview];
            self.videoPlayer = nil;
            
            MainViewController *vc = (MainViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;
            vc.webView.backgroundColor = self.webViewBackColor;
            vc.webView.opaque = true;
            [self removeNotification];
        }];
    }
}

- (void)pauseVideo:(CDVInvokedUrlCommand *)command
{
    [self.videoPlayer pause];
}

- (void)replay:(CDVInvokedUrlCommand *)command
{
    [self.videoPlayer play];
}

- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:YSPhotoBrowserVideoStartPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:YSPhotoBrowserVideoDownloadCompletionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)notificationHandler:(NSNotification *)notification
{
    if ([notification.name isEqualToString:YSPhotoBrowserVideoDownloadCompletionNotification]) {
        NSLog(@"download completion");
        
        NSDictionary *params = @{@"status":@(1)};
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self jsonStringEncodedWith:params]];
        pluginResult.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    } else if ([notification.name isEqualToString:YSPhotoBrowserVideoStartPlayNotification]) {
        NSLog(@"start play");
        
        NSDictionary *params = @{@"status":@(2)};
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self jsonStringEncodedWith:params]];
        pluginResult.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    } else if ([notification.name isEqualToString:AVPlayerItemDidPlayToEndTimeNotification]) {
        NSLog(@"play to end");
        
        NSDictionary *params = @{@"status":@(3)};
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self jsonStringEncodedWith:params]];
        pluginResult.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    } else if ([notification.name isEqualToString:UIApplicationWillResignActiveNotification]) {
        NSLog(@"pause to play");
        
        NSDictionary *params = @{@"status":@(4)};
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self jsonStringEncodedWith:params]];
        pluginResult.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    }
}

- (NSString *)jsonStringEncodedWith:(NSDictionary *)params {
    if ([NSJSONSerialization isValidJSONObject:params]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

@end
